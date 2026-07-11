/// Surgical, in-place repair of a decoded DTCG token document (protocol SPEC
/// section 2.7 gate 4): re-derives `derivation`-carrying token values from
/// `x`, and resyncs every color's `hex` to its `components`.
///
/// The fixer mutates the same `Map`/`List` instances produced by `jsonDecode`
/// rather than rebuilding the tree, so key order, `$description` fields,
/// unrelated number formatting and every `$extensions` entry (known or
/// foreign-vendor) are preserved untouched (protocol SPEC 2.1, 2.6).
library;

/// A single mechanical repair applied by [TokenFixer.fix].
class TokenFix {
  /// Creates a record of one repair at [path], from [from] to [to].
  const TokenFix({required this.path, required this.from, required this.to});

  /// Dotted path (jsonPath-ish, matching validator finding paths) of the
  /// value that was rewritten, e.g. `spacing.md` or `shadow.sm[0].color`.
  final String path;

  /// The previous value, rendered as a display string.
  final String from;

  /// The new value, rendered as a display string.
  final String to;

  /// Text-mode rendering: `FIXED <path>: <old> -> <new>`.
  String toLine() => 'FIXED $path: $from -> $to';

  /// JSON-mode rendering: `{"path": ..., "from": ..., "to": ...}`.
  Map<String, dynamic> toJsonEntry() => {'path': path, 'from': from, 'to': to};
}

/// Applies the two mechanical `--fix` repair classes (protocol SPEC 2.5, 2.7
/// gate 4) to a decoded token document in place.
///
/// Repair classes:
/// 1. Re-derive every `derivation`-carrying token's value from `x` (`value :=
///    x * multiple`, where `multiple` comes from the token's
///    `$extensions["io.utopiasoft.design"].derivation` string `x*<m>`).
/// 2. Resync every color's `hex` to its `components` (6-digit lowercase hex
///    from 8-bit-rounded channels), including colors nested inside shadow
///    layers.
///
/// Both classes walk the whole tree, including array positions (shadow
/// layers), so nothing is missed. Aliases (`"{group.token}"` strings) are
/// left untouched: they carry no `$value` to fix, and their coherence is
/// enforced by resolving to the aliased token instead.
class TokenFixer {
  const TokenFixer._();

  /// Walks [rawJson] (the mutable decoded root object of a token document)
  /// and applies every mechanical repair found, returning the ordered list of
  /// [TokenFix] records. [rawJson] is mutated in place; the same instance is
  /// safe to re-encode afterwards.
  ///
  /// An empty return list means the document already satisfies both repair
  /// classes and [rawJson] was left byte-identical (no keys were touched,
  /// only candidate values were compared and found already-coherent).
  static List<TokenFix> fix(Map<String, dynamic> rawJson) {
    final fixes = <TokenFix>[];
    final xNode = rawJson['x'];
    double? xValue;
    if (xNode is Map<String, dynamic> && xNode[r'$value'] is num) {
      xValue = (xNode[r'$value'] as num).toDouble();
    }
    _walk(rawJson, '', xValue, fixes);
    return fixes;
  }

  /// Recursively walks a node of the decoded tree. [path] is the dotted path
  /// to [node] from the document root (empty string at the root).
  static void _walk(dynamic node, String path, double? xValue, List<TokenFix> fixes) {
    if (node is Map<String, dynamic>) {
      final isToken = node.containsKey(r'$type') && node.containsKey(r'$value');
      if (isToken) {
        _fixToken(node, path, xValue, fixes);
        return;
      }
      for (final entry in node.entries) {
        final key = entry.key;
        if (key.startsWith(r'$')) {
          continue;
        }
        final childPath = path.isEmpty ? key : '$path.$key';
        _walk(entry.value, childPath, xValue, fixes);
      }
      return;
    }
    if (node is List) {
      for (var i = 0; i < node.length; i++) {
        _walk(node[i], '$path[$i]', xValue, fixes);
      }
    }
  }

  /// Applies both repair classes to a single token leaf [node] at [path].
  static void _fixToken(Map<String, dynamic> node, String path, double? xValue, List<TokenFix> fixes) {
    final type = node[r'$type'];
    final value = node[r'$value'];

    // Repair class 1: derivation re-derivation.
    if (xValue != null) {
      final extensions = node[r'$extensions'];
      if (extensions is Map<String, dynamic>) {
        final ns = extensions['io.utopiasoft.design'];
        if (ns is Map<String, dynamic>) {
          final derivation = ns['derivation'];
          if (derivation is String) {
            _fixDerivation(node, path, derivation, xValue, fixes);
          }
        }
      }
    }

    // Repair class 2: color hex resync. Colors can appear as the direct
    // token `$value` (`$type: "color"`) or nested inside a `shadow` array's
    // layer objects (walked recursively below since shadow values are
    // arrays, not token leaves themselves).
    if (type == 'color' && value is Map<String, dynamic>) {
      _fixColorHex(value, path, fixes);
    } else if (type == 'shadow' && value is List) {
      for (var i = 0; i < value.length; i++) {
        final layer = value[i];
        if (layer is Map<String, dynamic> && layer['color'] is Map<String, dynamic>) {
          _fixColorHex(layer['color'] as Map<String, dynamic>, '$path[$i].color', fixes);
        }
      }
    }
  }

  /// Re-derives a single `derivation`-carrying token's numeric value from
  /// `x * multiple`, in either bare-number (`number` $type) or
  /// dimension-object (`{"value": n, "unit": "px"}`) shape. Skips tokens
  /// whose `$value` is an alias string (nothing to re-derive: coherence is
  /// enforced on the resolved target) or whose derivation string is
  /// malformed (left for the validator to report as an error).
  static void _fixDerivation(
    Map<String, dynamic> node,
    String path,
    String derivation,
    double xValue,
    List<TokenFix> fixes,
  ) {
    final match = RegExp(r'^x\*([0-9]+(?:\.[0-9]+)?)$').firstMatch(derivation);
    if (match == null) {
      return;
    }
    final multiple = double.parse(match.group(1)!);
    final expected = xValue * multiple;
    final value = node[r'$value'];

    if (value is Map<String, dynamic> && value['value'] is num) {
      final actual = (value['value'] as num).toDouble();
      if (!_numEquals(actual, expected)) {
        value['value'] = _jsonNumber(expected);
        fixes.add(TokenFix(path: path, from: _formatNum(actual), to: _formatNum(expected)));
      }
      return;
    }
    if (value is num) {
      final actual = value.toDouble();
      if (!_numEquals(actual, expected)) {
        node[r'$value'] = _jsonNumber(expected);
        fixes.add(TokenFix(path: path, from: _formatNum(actual), to: _formatNum(expected)));
      }
    }
  }

  /// Resyncs a single DTCG color object's `hex` field to its `components`,
  /// leaving `components`, `alpha` and `colorSpace` untouched. No-op when
  /// `components` is malformed (left for the validator to report) or the hex
  /// already matches.
  static void _fixColorHex(Map<String, dynamic> colorValue, String path, List<TokenFix> fixes) {
    final components = colorValue['components'];
    final hex = colorValue['hex'];
    if (components is! List || components.length != 3 || hex is! String) {
      return;
    }
    final expectedHex = _hexOfComponents(components);
    if (expectedHex == null) {
      return;
    }
    if (hex != expectedHex) {
      colorValue['hex'] = expectedHex;
      fixes.add(TokenFix(path: path, from: hex, to: expectedHex));
    }
  }

  /// Computes the 6-digit lowercase `#rrggbb` hex for [components] (each
  /// `channel / 255`), rounding each channel to the nearest 8-bit value.
  /// Mirrors `TokenValidator._hexOfComponents` (the gate-4 coherence check),
  /// kept in lockstep so the fixer always produces a hex the validator then
  /// accepts.
  static String? _hexOfComponents(List<dynamic> components) {
    final channels = <int>[];
    for (final c in components) {
      if (c is! num) {
        return null;
      }
      channels.add((c.toDouble() * 255).round().clamp(0, 255));
    }
    return '#${channels.map((c) => c.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// Whether [a] and [b] are the same number for fixing purposes: exact
  /// equality (covers both int and double representations of the same
  /// value, e.g. `12` vs `12.0`).
  static bool _numEquals(double a, double b) => a == b;

  /// Converts a [double] to the JSON-friendly numeric representation: an
  /// [int] when the value is whole (`12` not `12.0`), otherwise the [double]
  /// unchanged. Mirrors `ThemeCapture._jsonNumber` so fixed values are
  /// formatted identically to exporter output.
  static dynamic _jsonNumber(double value) {
    if (value == value.roundToDouble() && value.isFinite) {
      return value.toInt();
    }
    return value;
  }

  /// Formats a number for display in a [TokenFix] change line: whole values
  /// without a trailing `.0`.
  static String _formatNum(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
