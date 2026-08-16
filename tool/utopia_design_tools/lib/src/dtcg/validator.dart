import 'package:json_schema/json_schema.dart';
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/token_document.dart';

export 'package:json_schema/json_schema.dart' show JsonSchema;

/// The protocol version this validator implements (protocol/VERSIONING.md).
/// Used for the profileVersion compatibility check (gate 6).
const String protocolVersion = '0.4.0';

/// Runs every validation gate from protocol SPEC section 2.7 against a
/// parsed token document, in order, reporting every finding (no fail-fast).
///
/// The bound schema is the loaded `protocol/schemas/tokens.schema.json`. The
/// document passed to `validate` is the decoded document (before
/// [TokenDocument.parse] discards non-token structure), needed by the
/// schema-error refinement layer to re-inspect the concrete value at a
/// failing path.
class TokenValidator {
  /// Creates a validator bound to the given [schema].
  const TokenValidator(this.schema);

  /// The loaded token-document JSON Schema.
  final JsonSchema schema;

  /// Validates [rawJson], returning every [Finding] from gates 1-6.
  List<Finding> validate(Map<String, dynamic> rawJson) {
    final findings = <Finding>[];

    // Gate 1 + 2: schema validity (naming conformance is schema-encoded).
    // The underlying schema library sometimes reports the same underlying
    // problem once per ancestor level (e.g. a missing required property is
    // reported both at the parent group and at the missing child's own
    // path); once refined, those collapse to identical findings, so
    // deduplicate by (severity, path, message).
    final schemaResult = schema.validate(rawJson);
    final seen = <String>{};
    for (final error in schemaResult.errors) {
      final finding = _refineSchemaError(rawJson, error);
      final key = '${finding.severity}|${finding.path}|${finding.message}';
      if (seen.add(key)) {
        findings.add(finding);
      }
    }

    // If the document does not even parse into the expected tree shape,
    // stop here: gates 3-6 assume a schema-shaped document and would
    // otherwise throw or produce noise on top of the gate-1 errors.
    if (!_isTreeWalkable(rawJson)) {
      return findings;
    }

    final document = TokenDocument.parse(rawJson);

    // Gate 3: alias resolvability.
    findings.addAll(_checkAliasResolvability(document));

    // Gate 4: value coherence (derivation, hex/component).
    findings.addAll(_checkValueCoherence(document));

    // Gate 5: textStyle bindings.
    findings.addAll(_checkTextStyleBindings(document));

    // Gate 6: warnings (profileVersion, unknown extension keys).
    findings.addAll(_checkWarnings(document));

    return findings;
  }

  bool _isTreeWalkable(Map<String, dynamic> rawJson) {
    const requiredGroups = [
      'x',
      'spacing',
      'radius',
      'border',
      'shadow',
      'fontWeight',
      'duration',
      'breakpoint',
      'color',
      'textStyle',
      'textStyle-colors',
      'theme',
    ];
    return requiredGroups.every(rawJson.containsKey);
  }

  // ---------------------------------------------------------------------
  // Gate 1: schema error refinement.
  // ---------------------------------------------------------------------

  Finding _refineSchemaError(Map<String, dynamic> rawJson, ValidationError error) {
    final path = _dottedPath(error.instancePath);
    final refinement = _refineMessage(rawJson, path, error);
    return Finding.error(refinement.path.isEmpty ? r'$' : refinement.path, refinement.message);
  }

  /// Converts a JSON-Pointer instance path (`/spacing/md/$value/unit`) to a
  /// dotted jsonPath-ish path (`spacing.md`). Trims trailing `$value`/`$type`
  /// segments so the reported path names the token, not its internals.
  String _dottedPath(String instancePath) {
    final segments = instancePath.split('/').where((s) => s.isNotEmpty).toList();
    // Trim trailing internal segments (\$value, \$type, unit, value, ...) so
    // the path names the token itself; keep array indices for shadow layers.
    while (segments.isNotEmpty && (segments.last.startsWith(r'$') || _isInternalValueKey(segments.last))) {
      segments.removeLast();
    }
    return segments.map(Uri.decodeComponent).join('.');
  }

  bool _isInternalValueKey(String segment) => const {'unit', 'value'}.contains(segment);

  ({String path, String message}) _refineMessage(Map<String, dynamic> rawJson, String path, ValidationError error) {
    final rawMessage = error.message;

    // additionalProperties: "unknown token 'X': the utopia token tree is
    // closed; custom tokens are not supported yet."
    final additionalPropMatch = RegExp(r'unallowed additional property (\S+)').firstMatch(rawMessage);
    if (additionalPropMatch != null) {
      final propName = additionalPropMatch.group(1)!;
      final fullPath = path.isEmpty ? propName : '$path.$propName';
      return (
        path: fullPath,
        message:
            "unknown token '$fullPath': the utopia token tree is closed; custom tokens are not supported yet (the reserved custom group is not implemented)",
      );
    }

    // required prop missing: "missing required token 'group.name'." The
    // underlying schema library reports this once per ancestor level (once
    // at the group path, once at the missing child's own path); avoid
    // double-appending the property name when the instance path already
    // ends with it.
    final requiredMatch = RegExp(r'required prop missing: (\S+)').firstMatch(rawMessage);
    if (requiredMatch != null) {
      final propName = requiredMatch.group(1)!;
      final alreadyEndsWithProp = path == propName || path.endsWith('.$propName');
      final fullPath = alreadyEndsWithProp || path.isEmpty ? (path.isEmpty ? propName : path) : '$path.$propName';
      return (path: fullPath, message: "missing required token '$fullPath'");
    }

    // allOf violated on a typed token: re-check the concrete node against
    // the expectations for its position to produce a precise message. The
    // diagnosis functions return a self-contained "path: message" line
    // (their path may be more specific than the outer schema error's path,
    // e.g. pointing at a shadow layer or a typography sub-value), so split
    // it back into (path, message) rather than double-prefixing the path.
    if (rawMessage.contains('allOf violated')) {
      final node = _lookupRaw(rawJson, path);
      if (node is Map<String, dynamic>) {
        final specific = _diagnoseTokenNode(path, node);
        if (specific != null) {
          final separatorIndex = specific.indexOf(': ');
          if (separatorIndex != -1) {
            return (path: specific.substring(0, separatorIndex), message: specific.substring(separatorIndex + 2));
          }
          return (path: path, message: specific);
        }
      }
    }

    return (path: path, message: rawMessage);
  }

  /// Looks up the raw JSON value at a dotted [path] (empty path = root).
  dynamic _lookupRaw(Map<String, dynamic> rawJson, String path) {
    if (path.isEmpty) {
      return rawJson;
    }
    dynamic current = rawJson;
    for (final segment in path.split('.')) {
      if (current is Map<String, dynamic>) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Diagnoses a single token node whose schema `allOf` failed, producing a
  /// one-line message naming the concrete rule that was violated. Returns
  /// `null` when no specific rule matches (caller falls back to the raw
  /// schema message).
  String? _diagnoseTokenNode(String path, Map<String, dynamic> node) {
    final type = node[r'$type'] as String?;
    final value = node[r'$value'];
    if (type == null) {
      return null;
    }
    switch (type) {
      case 'dimension':
        return _diagnoseDimensionValue(path, value, nonNegative: true);
      case 'duration':
        return _diagnoseDurationValue(path, value);
      case 'color':
        return _diagnoseColorValue(path, value);
      case 'fontWeight':
        return _diagnoseFontWeightValue(path, value);
      case 'typography':
        return _diagnoseTypographyValue(path, value);
      case 'shadow':
        return _diagnoseShadowValue(path, value);
      case 'number':
        return _diagnoseNumberValue(path, value);
    }
    return null;
  }

  /// [nonNegative] holds for standalone dimension tokens (spacing, radius,
  /// border, breakpoint, theme.*); signed dimension values (shadow
  /// offsets/spread, letterSpacing) pass false.
  String? _diagnoseDimensionValue(String path, dynamic value, {bool nonNegative = false}) {
    if (value is String) {
      // Alias form; malformed aliases are caught by the alias pattern check.
      if (aliasPathOf(value) == null) {
        return '$path: malformed alias "$value" (expected the form "{group.token}")';
      }
      return null;
    }
    if (value is! Map) {
      return '$path: dimension \$value must be an object with "value" and "unit", or an alias string';
    }
    final unit = value['unit'];
    if (unit != 'px') {
      return '$path: dimension unit must be "px" (got "$unit")';
    }
    final rawValue = value['value'];
    if (rawValue is! num) {
      return '$path: dimension "value" must be a number (got "$rawValue")';
    }
    if (nonNegative && rawValue < 0) {
      return '$path: dimension "value" must be >= 0 (got $rawValue)';
    }
    return null;
  }

  String? _diagnoseDurationValue(String path, dynamic value) {
    if (value is String) {
      if (aliasPathOf(value) == null) {
        return '$path: malformed alias "$value" (expected the form "{group.token}")';
      }
      return null;
    }
    if (value is! Map) {
      return '$path: duration \$value must be an object with "value" and "unit", or an alias string';
    }
    final unit = value['unit'];
    if (unit != 'ms') {
      return '$path: duration unit must be "ms" (got "$unit")';
    }
    final rawValue = value['value'];
    if (rawValue is num && rawValue < 0) {
      return '$path: duration "value" must be >= 0 (got $rawValue)';
    }
    return null;
  }

  String? _diagnoseColorValue(String path, dynamic value) {
    if (value is String) {
      if (aliasPathOf(value) == null) {
        return '$path: malformed alias "$value" (expected the form "{group.token}")';
      }
      return null;
    }
    if (value is! Map) {
      return '$path: color \$value must be a DTCG color object or an alias string';
    }
    final colorSpace = value['colorSpace'];
    if (colorSpace != 'srgb') {
      return '$path: color colorSpace must be "srgb" (got "$colorSpace")';
    }
    final hex = value['hex'];
    if (hex is! String || !RegExp(r'^#[0-9a-f]{6}$').hasMatch(hex)) {
      if (hex is String && RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex) && hex != hex.toLowerCase()) {
        return '$path: color hex must be lowercase (got "$hex")';
      }
      return '$path: color hex must be a lowercase 6-digit "#rrggbb" string (got "$hex")';
    }
    final components = value['components'];
    if (components is! List || components.length != 3) {
      return '$path: color components must be an array of exactly 3 numbers in 0..1 (got "$components")';
    }
    for (final c in components) {
      if (c is! num || c < 0 || c > 1) {
        return '$path: color components must each be in the 0..1 range (got $components)';
      }
    }
    final alpha = value['alpha'];
    if (alpha != null && (alpha is! num || alpha < 0 || alpha > 1)) {
      return '$path: color alpha must be in the 0..1 range (got $alpha)';
    }
    return null;
  }

  String? _diagnoseFontWeightValue(String path, dynamic value) {
    if (value is String) {
      if (aliasPathOf(value) == null) {
        return '$path: malformed alias "$value" (expected the form "{group.token}")';
      }
      return null;
    }
    const validWeights = {100, 200, 300, 400, 500, 600, 700, 800, 900};
    if (value is! num || !validWeights.contains(value.toInt()) || value != value.toInt()) {
      return '$path: fontWeight must be one of $validWeights (got $value)';
    }
    return null;
  }

  String? _diagnoseNumberValue(String path, dynamic value) {
    if (value is String) {
      if (aliasPathOf(value) == null) {
        return '$path: malformed alias "$value" (expected the form "{group.token}")';
      }
      return null;
    }
    if (value is! num || value <= 0) {
      return '$path: number \$value must be > 0 (got $value)';
    }
    return null;
  }

  String? _diagnoseTypographyValue(String path, dynamic value) {
    if (value is String) {
      if (aliasPathOf(value) == null) {
        return '$path: malformed alias "$value" (expected the form "{group.token}")';
      }
      return null;
    }
    if (value is! Map) {
      return '$path: typography \$value must be an object or an alias string';
    }
    const allowedKeys = {'fontFamily', 'fontSize', 'fontWeight', 'letterSpacing'};
    for (final key in value.keys) {
      if (!allowedKeys.contains(key)) {
        if (key == 'lineHeight') {
          return '$path: lineHeight is not part of the Utopia Design Protocol v0 typography profile '
              '(utopia_ui does not set TextStyle.height); remove it';
        }
        return '$path: unknown typography property "$key"; typography tokens carry only fontFamily, '
            'fontSize, fontWeight, letterSpacing';
      }
    }
    for (final key in allowedKeys) {
      if (!value.containsKey(key)) {
        return '$path: typography \$value is missing required property "$key"';
      }
    }
    final fontSizeDiagnosis = _diagnoseDimensionValue('$path.fontSize', value['fontSize']);
    if (fontSizeDiagnosis != null) {
      return fontSizeDiagnosis;
    }
    final letterSpacingDiagnosis = _diagnoseDimensionValue('$path.letterSpacing', value['letterSpacing']);
    if (letterSpacingDiagnosis != null) {
      return letterSpacingDiagnosis;
    }
    final fontWeightDiagnosis = _diagnoseFontWeightValue('$path.fontWeight', value['fontWeight']);
    if (fontWeightDiagnosis != null) {
      return fontWeightDiagnosis;
    }
    return null;
  }

  String? _diagnoseShadowValue(String path, dynamic value) {
    if (value is String) {
      if (aliasPathOf(value) == null) {
        return '$path: malformed alias "$value" (expected the form "{group.token}")';
      }
      return null;
    }
    if (value is! List || value.isEmpty) {
      return '$path: shadow \$value must be a non-empty array of shadow layers';
    }
    for (var i = 0; i < value.length; i++) {
      final layer = value[i];
      final layerPath = '$path[$i]';
      if (layer is String) {
        if (aliasPathOf(layer) == null) {
          return '$layerPath: malformed alias "$layer" (expected the form "{group.token}")';
        }
        continue;
      }
      if (layer is! Map) {
        return '$layerPath: shadow layer must be an object with color/offsetX/offsetY/blur/spread';
      }
      const requiredKeys = ['color', 'offsetX', 'offsetY', 'blur', 'spread'];
      for (final key in requiredKeys) {
        if (!layer.containsKey(key)) {
          return '$layerPath: shadow layer is missing required property "$key"';
        }
      }
      final colorDiagnosis = _diagnoseColorValue('$layerPath.color', layer['color']);
      if (colorDiagnosis != null) {
        return colorDiagnosis;
      }
      for (final key in ['offsetX', 'offsetY', 'blur', 'spread']) {
        final dimDiagnosis = _diagnoseDimensionValue('$layerPath.$key', layer[key]);
        if (dimDiagnosis != null) {
          return dimDiagnosis;
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Gate 3: alias resolvability.
  // ---------------------------------------------------------------------

  List<Finding> _checkAliasResolvability(TokenDocument document) {
    final findings = <Finding>[];
    for (final entry in document.tokensByPath.entries) {
      final path = entry.key;
      final node = entry.value;
      _checkAliasesInValue(document, path, node.type, node.value, findings);
    }
    return findings;
  }

  void _checkAliasesInValue(
    TokenDocument document,
    String path,
    String? type,
    dynamic value,
    List<Finding> findings,
  ) {
    if (value is String) {
      final aliasPath = aliasPathOf(value);
      if (aliasPath == null) {
        return;
      }
      final resolution = resolveAlias(document, aliasPath);
      if (!resolution.isResolved) {
        findings.add(Finding.error(path, '${resolution.error}'));
        return;
      }
      final expectedFamily = familyOfType(type);
      final resolvedFamily = familyOfType(resolution.terminal!.type);
      if (expectedFamily != null && resolvedFamily != null && expectedFamily != resolvedFamily) {
        findings.add(
          Finding.error(
            path,
            'alias "{$aliasPath}" resolves to a ${resolution.terminal!.type} token but a $type value was expected',
          ),
        );
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        _checkAliasesInValue(document, '$path.${entry.key}', null, entry.value, findings);
      }
      return;
    }
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        _checkAliasesInValue(document, '$path[$i]', type, value[i], findings);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Gate 4: value coherence (derivation + hex/component).
  // ---------------------------------------------------------------------

  List<Finding> _checkValueCoherence(TokenDocument document) {
    final findings = <Finding>[];
    final xNode = document.tokensByPath['x'];
    double? xValue;
    if (xNode != null && xNode.value is num) {
      xValue = (xNode.value as num).toDouble();
    }

    for (final entry in document.tokensByPath.entries) {
      final path = entry.key;
      final node = entry.value;
      final extensions = node.utopiaExtensions;
      final derivation = extensions?['derivation'];
      if (derivation != null && path == 'radius.full') {
        findings.add(
          Finding.error(
            path,
            'radius.full is deliberately not base-derived and must not carry a derivation extension (SPEC 2.5)',
          ),
        );
      } else if (derivation is String && xValue != null) {
        findings.addAll(_checkDerivation(path, node, derivation, xValue));
      }
      _checkColorCoherence(path, node.type, node.value, findings);
    }
    return findings;
  }

  List<Finding> _checkDerivation(String path, TokenNode node, String derivation, double xValue) {
    final match = RegExp(r'^x\*([0-9]+(?:\.[0-9]+)?)$').firstMatch(derivation);
    if (match == null) {
      return [Finding.error(path, 'malformed derivation extension "$derivation" (expected the form "x*<multiple>")')];
    }
    final multiple = double.parse(match.group(1)!);
    final expected = xValue * multiple;
    final actualValue = node.value;
    double? actual;
    if (actualValue is Map && actualValue['value'] is num) {
      actual = (actualValue['value'] as num).toDouble();
    } else if (actualValue is num) {
      actual = actualValue.toDouble();
    }
    if (actual == null) {
      return [];
    }
    if ((actual - expected).abs() > derivationTolerance) {
      final expectedText = expected == expected.roundToDouble() ? expected.toInt().toString() : expected.toString();
      return [
        Finding.error(
          path,
          'derivation x*${match.group(1)} expects $expectedText (x=${_formatNum(xValue)}), got ${_formatNum(actual)}',
        ),
      ];
    }
    return [];
  }

  String _formatNum(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  void _checkColorCoherence(String path, String? type, dynamic value, List<Finding> findings) {
    if (type == 'color' && value is Map<String, dynamic>) {
      _checkOneColorCoherence(path, value, findings);
      return;
    }
    if (type == 'shadow' && value is List) {
      for (var i = 0; i < value.length; i++) {
        final layer = value[i];
        if (layer is Map && layer['color'] is Map) {
          _checkOneColorCoherence('$path[$i].color', layer['color'] as Map<String, dynamic>, findings);
        }
      }
    }
  }

  void _checkOneColorCoherence(String path, Map<String, dynamic> value, List<Finding> findings) {
    final hex = value['hex'];
    final components = value['components'];
    if (hex is! String || components is! List || components.length != 3) {
      return;
    }
    final expectedHex = _hexOfComponents(components);
    if (expectedHex == null) {
      return;
    }
    if (hex.toLowerCase() != expectedHex) {
      findings.add(Finding.error(path, 'hex "$hex" does not match components; expected "$expectedHex"'));
    }
  }

  String? _hexOfComponents(List<dynamic> components) {
    final channels = <int>[];
    for (final c in components) {
      if (c is! num) {
        return null;
      }
      channels.add((c.toDouble() * 255).round().clamp(0, 255));
    }
    return '#${channels.map((c) => c.toRadixString(16).padLeft(2, '0')).join()}';
  }

  // ---------------------------------------------------------------------
  // Gate 5: textStyle bindings.
  // ---------------------------------------------------------------------

  List<Finding> _checkTextStyleBindings(TokenDocument document) {
    final findings = <Finding>[];
    final textStyleGroup = document.root.children['textStyle'];
    if (textStyleGroup == null) {
      return findings;
    }
    for (final entry in textStyleGroup.children.entries) {
      final role = entry.key;
      final node = entry.value;
      final path = 'textStyle.$role';
      final extensions = node.utopiaExtensions;
      final colorToken = extensions?['colorToken'];
      if (colorToken is! String || colorToken.isEmpty) {
        findings.add(
          Finding.error(
            path,
            r'missing $extensions["io.utopiasoft.design"].colorToken binding a sibling color token',
          ),
        );
        continue;
      }
      final target = document.tokensByPath[colorToken];
      if (target == null) {
        findings.add(Finding.error(path, 'colorToken "$colorToken" does not resolve to an existing color token'));
        continue;
      }
      if (target.type != 'color') {
        findings.add(
          Finding.error(
            path,
            'colorToken "$colorToken" resolves to a ${target.type} token, not a color token',
          ),
        );
        continue;
      }
      final expected = 'textStyle-colors.$role';
      if (colorToken != expected) {
        findings.add(Finding.warning(path, 'colorToken "$colorToken" is not the conventional "$expected"'));
      }
    }
    return findings;
  }

  // ---------------------------------------------------------------------
  // Gate 6: warnings (profileVersion, unknown extension keys).
  // ---------------------------------------------------------------------

  List<Finding> _checkWarnings(TokenDocument document) {
    final findings = <Finding>[];
    final rootExtensions = document.rootExtensions;
    final profileVersion = rootExtensions?['profileVersion'];
    if (profileVersion == null) {
      findings.add(
        const Finding.warning(
          r'$extensions.io.utopiasoft.design.profileVersion',
          'missing root profileVersion; assuming the current protocol version',
        ),
      );
    } else if (profileVersion is String) {
      findings.addAll(_checkProfileVersion(profileVersion));
    }

    _checkUnknownExtensionKeys(document.root, r'$', findings);
    for (final entry in document.tokensByPath.entries) {
      _checkUnknownExtensionKeys(entry.value, entry.key, findings);
    }
    return findings;
  }

  List<Finding> _checkProfileVersion(String profileVersion) {
    final docParts = profileVersion.split('.');
    final selfParts = protocolVersion.split('.');
    if (docParts.isEmpty || selfParts.isEmpty) {
      return [];
    }
    final docMajor = int.tryParse(docParts[0]);
    final selfMajor = int.tryParse(selfParts[0]);
    if (docMajor == null || selfMajor == null) {
      return [];
    }
    if (docMajor != selfMajor) {
      return [
        Finding.error(
          r'$extensions.io.utopiasoft.design.profileVersion',
          'profileVersion "$profileVersion" has a major version incompatible with this tool '
              '(protocol $protocolVersion)',
        ),
      ];
    }
    if (docParts.length > 1 && selfParts.length > 1) {
      final docMinor = int.tryParse(docParts[1]);
      final selfMinor = int.tryParse(selfParts[1]);
      if (docMinor != null && selfMinor != null && docMinor > selfMinor) {
        return [
          Finding.warning(
            r'$extensions.io.utopiasoft.design.profileVersion',
            'profileVersion "$profileVersion" is newer than this tool understands (protocol $protocolVersion)',
          ),
        ];
      }
    }
    return [];
  }

  static const _knownExtensionKeys = {
    'derivation',
    'colorToken',
    'fontPackage',
    'profileVersion',
    'lastSyncedValue',
    'lastSyncedAt',
    'sourceRef',
  };

  void _checkUnknownExtensionKeys(TokenNode node, String path, List<Finding> findings) {
    final extensions = node.json[r'$extensions'];
    if (extensions is Map<String, dynamic>) {
      final ns = extensions['io.utopiasoft.design'];
      if (ns is Map<String, dynamic>) {
        for (final key in ns.keys) {
          if (!_knownExtensionKeys.contains(key)) {
            findings.add(Finding.warning(path, 'unknown key "$key" under the io.utopiasoft.design extension namespace'));
          }
        }
      }
    }
  }
}

/// Decodes and returns the JSON schema document at [schemaSource] (already
/// read as a string) as a ready-to-use [JsonSchema].
JsonSchema loadSchema(String schemaSource) => JsonSchema.create(schemaSource);
