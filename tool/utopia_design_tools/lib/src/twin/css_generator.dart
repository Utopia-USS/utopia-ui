/// Renders a parsed [TokenDocument] into `twin/tokens.css` (protocol SPEC
/// section 4.2): one `:root { ... }` block of `--utopia-*` custom properties,
/// in token-tree document order, plus a small trailing font-face note.
///
/// This is the shared naming/value-serialization layer: `tailwind_generator.dart`
/// reuses [cssVarName], [serializeColor], [serializeDimensionValue] and
/// friends so the two twin stylesheets never disagree on how a value prints.
library;

import 'package:utopia_design_tools/src/dtcg/token_document.dart';

/// Converts a dotted token path (`spacing.md`, `theme.fieldContentPadding.top`)
/// into its `--utopia-*` custom property name (protocol SPEC 4.2): every path
/// segment is kebab-cased on camelCase boundaries, then joined with `-`.
///
/// `textStyle-colors.<role>` is handled by the caller (the fold rule folds it
/// into the sibling `textStyle.<role>` expansion rather than emitting
/// `--utopia-text-style-colors-<role>`); this function is not given that path
/// shape directly.
String cssVarName(String dottedPath) {
  final segments = dottedPath.split('.');
  final kebabSegments = segments.map(_kebabCase);
  return '--utopia-${kebabSegments.join('-')}';
}

/// Splits [segment] on camelCase boundaries and lower-kebab-cases it:
/// `fieldContentPadding` -> `field-content-padding`, `semiBold` -> `semi-bold`.
String _kebabCase(String segment) {
  final buffer = StringBuffer();
  for (var i = 0; i < segment.length; i++) {
    final char = segment[i];
    final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
    if (isUpper && i > 0) {
      buffer.write('-');
    }
    buffer.write(char.toLowerCase());
  }
  return buffer.toString();
}

/// Formats a resolved dimension value (already-resolved logical px double) as
/// CSS: no trailing `.0` for whole numbers (`6px`, `1.5px`).
String serializeDimensionValue(double value) {
  final formatted = value == value.roundToDouble() && value.isFinite ? value.toInt().toString() : _trimmed(value);
  return '${formatted}px';
}

/// Formats a resolved duration (milliseconds) as CSS: `<n>ms`.
String serializeDurationValue(num value) {
  final asDouble = value.toDouble();
  final formatted = asDouble == asDouble.roundToDouble() ? asDouble.toInt().toString() : _trimmed(asDouble);
  return '${formatted}ms';
}

/// Formats a bare unitless number (the `x` token, or a `fontWeight`): whole
/// numbers print without a trailing `.0`.
String serializeUnitlessNumber(num value) {
  final asDouble = value.toDouble();
  if (asDouble == asDouble.roundToDouble() && asDouble.isFinite) {
    return asDouble.toInt().toString();
  }
  return _trimmed(asDouble);
}

/// Trims a double to at most 4 significant decimal digits, dropping trailing
/// zeros and a trailing decimal point (used for both plain dimensions with
/// fractional values and alpha channels).
String _trimmed(double value) {
  var text = value.toStringAsFixed(4);
  if (text.contains('.')) {
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
  }
  return text;
}

/// Serializes a DTCG color `$value` object (protocol SPEC 2.3) as a CSS color
/// literal: lowercase `#rrggbb` when alpha is exactly `1`, else
/// `rgb(R G B / A)` with 0-255 integer channels and alpha trimmed to at most
/// 4 significant decimals.
String serializeColor(Map<String, dynamic> value) {
  final hex = value['hex'] as String;
  final alpha = (value['alpha'] as num?)?.toDouble() ?? 1.0;
  if (alpha == 1) {
    return hex.toLowerCase();
  }
  final components = (value['components'] as List).cast<num>();
  final r = (components[0].toDouble() * 255).round().clamp(0, 255);
  final g = (components[1].toDouble() * 255).round().clamp(0, 255);
  final b = (components[2].toDouble() * 255).round().clamp(0, 255);
  return 'rgb($r $g $b / ${_trimmed(alpha)})';
}

/// One CSS custom property declaration to be printed inside `:root { ... }`.
class CssDeclaration {
  /// Creates a declaration `--utopia-<name>: <value>;`.
  const CssDeclaration(this.name, this.value);

  /// The custom property name, including the `--utopia-` prefix.
  final String name;

  /// The already-serialized CSS value (a literal, or a `var(...)` reference).
  final String value;

  /// Renders as `  --utopia-name: value;` (two-space indent, matching the
  /// `:root` block body).
  String toLine() => '  $name: $value;';
}

/// Walks [document] in token-tree order (protocol SPEC 2.2) and produces the
/// full ordered list of [CssDeclaration]s for `:root`.
List<CssDeclaration> buildCssDeclarations(TokenDocument document) {
  final declarations = <CssDeclaration>[];
  final root = document.root;

  void emitScalarGroup(String groupName) {
    final group = root.children[groupName];
    if (group == null) {
      return;
    }
    for (final entry in group.children.entries) {
      final node = entry.value;
      declarations.add(CssDeclaration(cssVarName(node.path), _serializeScalarToken(document, node)));
    }
  }

  // x
  final xNode = root.children['x'];
  if (xNode != null) {
    declarations.add(CssDeclaration(cssVarName('x'), _serializeScalarToken(document, xNode)));
  }

  emitScalarGroup('spacing');
  emitScalarGroup('radius');
  emitScalarGroup('border');

  // shadow: one var per step, full box-shadow value list.
  final shadowGroup = root.children['shadow'];
  if (shadowGroup != null) {
    for (final entry in shadowGroup.children.entries) {
      final node = entry.value;
      declarations.add(CssDeclaration(cssVarName(node.path), serializeShadowValue(document, node)));
    }
  }

  emitScalarGroup('fontWeight');
  emitScalarGroup('duration');
  emitScalarGroup('breakpoint');
  emitScalarGroup('color');

  // textStyle: composite expansion, with the sibling textStyle-colors value
  // folded in adjacent to each role's block (protocol SPEC 4.2).
  final textStyleGroup = root.children['textStyle'];
  final textStyleColorsGroup = root.children['textStyle-colors'];
  if (textStyleGroup != null) {
    for (final entry in textStyleGroup.children.entries) {
      final role = entry.key;
      final node = entry.value;
      declarations.addAll(_serializeTypographyToken(document, node, role, textStyleColorsGroup));
    }
  }

  // theme.*: scalar dimensions, plus the fieldContentPadding sub-group.
  final themeGroup = root.children['theme'];
  if (themeGroup != null) {
    for (final entry in themeGroup.children.entries) {
      final node = entry.value;
      if (node.isToken) {
        declarations.add(CssDeclaration(cssVarName(node.path), _serializeScalarToken(document, node)));
      } else {
        for (final subEntry in node.children.entries) {
          final subNode = subEntry.value;
          declarations.add(CssDeclaration(cssVarName(subNode.path), _serializeScalarToken(document, subNode)));
        }
      }
    }
  }

  return declarations;
}

/// Serializes a single scalar token (dimension, duration, number, fontWeight
/// or color) at [node]: an alias emits a `var()` reference to its target;
/// otherwise the literal value is serialized per its `$type`.
String _serializeScalarToken(TokenDocument document, TokenNode node) {
  final aliasPath = aliasPathOf(node.value);
  if (aliasPath != null) {
    return 'var(${cssVarName(aliasPath)})';
  }
  return _serializeLiteralByType(node.type, node.value);
}

String _serializeLiteralByType(String? type, dynamic value) {
  switch (type) {
    case 'dimension':
      return serializeDimensionValue(((value as Map)['value'] as num).toDouble());
    case 'duration':
      return serializeDurationValue((value as Map)['value'] as num);
    case 'number':
      return serializeUnitlessNumber(value as num);
    case 'fontWeight':
      return serializeUnitlessNumber(value as num);
    case 'color':
      return serializeColor((value as Map).cast<String, dynamic>());
    default:
      throw StateError('generate_twin: unsupported scalar token \$type "$type"');
  }
}

/// Serializes a `shadow` token into the single CSS `box-shadow` value list
/// (protocol SPEC 4.2): `offsetX offsetY blur spread color`, layers
/// comma-joined. Aliased sub-values (and a fully-aliased layer array) resolve
/// to their literal values - a shadow variable is always a plain CSS literal,
/// never a `var()` reference, because CSS cannot compose a `var()` inside one
/// component of a composite value this way. Shared with `tailwind_generator.dart`
/// so `--shadow-<step>` prints the identical value as `--utopia-shadow-<step>`.
String serializeShadowValue(TokenDocument document, TokenNode node) {
  final aliasPath = aliasPathOf(node.value);
  final layers = aliasPath != null ? resolveAlias(document, aliasPath).terminal!.value as List : node.value as List;
  return layers.map((rawLayer) => _serializeShadowLayer(document, rawLayer)).join(', ');
}

String _serializeShadowLayer(TokenDocument document, dynamic rawLayer) {
  Map<String, dynamic> layer;
  if (rawLayer is String) {
    final aliasPath = aliasPathOf(rawLayer);
    if (aliasPath == null) {
      throw StateError('generate_twin: malformed shadow layer alias "$rawLayer"');
    }
    final resolution = resolveAlias(document, aliasPath);
    final terminalValue = resolution.terminal!.value;
    if (terminalValue is List && terminalValue.isNotEmpty) {
      layer = (terminalValue.first as Map).cast<String, dynamic>();
    } else {
      throw StateError('generate_twin: shadow layer alias "$rawLayer" did not resolve to a shadow');
    }
  } else {
    layer = (rawLayer as Map).cast<String, dynamic>();
  }

  double dimensionOf(dynamic raw) {
    if (raw is String) {
      final aliasPath = aliasPathOf(raw);
      if (aliasPath == null) {
        throw StateError('generate_twin: malformed dimension alias "$raw" inside a shadow layer');
      }
      final resolution = resolveAlias(document, aliasPath);
      return ((resolution.terminal!.value as Map)['value'] as num).toDouble();
    }
    return ((raw as Map)['value'] as num).toDouble();
  }

  Map<String, dynamic> colorOf(dynamic raw) {
    if (raw is String) {
      final aliasPath = aliasPathOf(raw);
      if (aliasPath == null) {
        throw StateError('generate_twin: malformed color alias "$raw" inside a shadow layer');
      }
      final resolution = resolveAlias(document, aliasPath);
      return (resolution.terminal!.value as Map).cast<String, dynamic>();
    }
    return (raw as Map).cast<String, dynamic>();
  }

  final offsetX = _serializeShadowDimension(dimensionOf(layer['offsetX']));
  final offsetY = _serializeShadowDimension(dimensionOf(layer['offsetY']));
  final blur = _serializeShadowDimension(dimensionOf(layer['blur']));
  final spread = _serializeShadowDimension(dimensionOf(layer['spread']));
  final color = serializeColor(colorOf(layer['color']));
  return '$offsetX $offsetY $blur $spread $color';
}

/// Formats a dimension component inside a `box-shadow` value list: a zero
/// length prints unitless (`0`, matching the protocol SPEC 4.2 example
/// `0 1px 6px 0 rgb(...)`), a non-zero length prints as `<n>px` via
/// [serializeDimensionValue].
String _serializeShadowDimension(double value) => value == 0 ? '0' : serializeDimensionValue(value);

/// Serializes a `typography` token into its per-property expansion plus the
/// folded sibling color (protocol SPEC 4.2): `-font-family`, `-font-size`,
/// `-font-weight`, `-letter-spacing`, `-color`. The `fontPackage` extension is
/// ignored (Dart-only concern).
List<CssDeclaration> _serializeTypographyToken(
  TokenDocument document,
  TokenNode node,
  String role,
  TokenNode? textStyleColorsGroup,
) {
  final aliasPath = aliasPathOf(node.value);
  final value = aliasPath != null ? resolveAlias(document, aliasPath).terminal!.value as Map : node.value as Map;

  final basePrefix = cssVarName('textStyle.$role');
  final declarations = <CssDeclaration>[];

  // Each typography sub-value may itself be an alias (the schema permits it and
  // the validator accepts it); resolve to the terminal value before consuming,
  // as the shadow layers above already do.
  dynamic resolveSub(dynamic raw) {
    if (raw is String) {
      final aliasPath = aliasPathOf(raw);
      if (aliasPath != null) return resolveAlias(document, aliasPath).terminal!.value;
    }
    return raw;
  }

  final fontFamilyRaw = resolveSub(value['fontFamily']);
  final String fontFamilyCss;
  if (fontFamilyRaw is List) {
    fontFamilyCss = fontFamilyRaw.map((f) => _quoteFontFamily(f as String)).join(', ');
  } else {
    fontFamilyCss = _quoteFontFamily(fontFamilyRaw as String);
  }
  declarations.add(CssDeclaration('$basePrefix-font-family', fontFamilyCss));

  final fontSize = ((resolveSub(value['fontSize']) as Map)['value'] as num).toDouble();
  declarations.add(CssDeclaration('$basePrefix-font-size', serializeDimensionValue(fontSize)));

  final fontWeight = resolveSub(value['fontWeight']) as num;
  declarations.add(CssDeclaration('$basePrefix-font-weight', serializeUnitlessNumber(fontWeight)));

  final letterSpacing = ((resolveSub(value['letterSpacing']) as Map)['value'] as num).toDouble();
  declarations.add(CssDeclaration('$basePrefix-letter-spacing', serializeDimensionValue(letterSpacing)));

  // Folded sibling color: textStyle-colors.<role> -> --utopia-text-style-<role>-color,
  // emitted adjacent to this typography block's expansion (protocol SPEC 4.2).
  final colorNode = textStyleColorsGroup?.children[role];
  if (colorNode != null) {
    final colorAliasPath = aliasPathOf(colorNode.value);
    final colorValue = colorAliasPath != null
        ? resolveAlias(document, colorAliasPath).terminal!.value as Map
        : colorNode.value as Map;
    declarations.add(
      CssDeclaration('$basePrefix-color', serializeColor(colorValue.cast<String, dynamic>())),
    );
  }

  return declarations;
}

/// Quotes a font family name for CSS when it contains a space (`"Sora Sans"`);
/// single-word families are emitted bare (`Sora`).
String _quoteFontFamily(String family) => family.contains(' ') ? '"$family"' : family;

/// Renders the full `tokens.css` file text for [document], read from
/// [inputPath] (recorded in the header comment) and carrying [profileVersion]
/// (also recorded in the header).
String generateCss(TokenDocument document, {required String inputPath, required String profileVersion}) {
  final declarations = buildCssDeclarations(document);
  final buffer = StringBuffer();
  buffer.writeln('/* GENERATED by utopia_design_tools:generate_twin from $inputPath - do not edit. */');
  buffer.writeln('/* Regenerate: dart run utopia_design_tools:generate_twin $inputPath */');
  buffer.writeln('/* profileVersion: $profileVersion */');
  buffer.writeln(':root {');
  for (final declaration in declarations) {
    buffer.writeln(declaration.toLine());
  }
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('/* The twin does not bundle fonts: gallery pages load the family named above from');
  buffer.writeln("   the system font stack or a webfont of the consumer's choosing (see A5). */");
  return buffer.toString();
}
