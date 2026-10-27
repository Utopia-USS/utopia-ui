/// Pure-Dart representation of a parsed DTCG token document (protocol SPEC
/// section 2): a tree walker plus alias resolution, with no dependency on
/// Flutter or the schema validator. Shared by `validator.dart` (gates 3-6)
/// and any future rewrite tooling (`--fix`).
library;

/// Float tolerance shared by the exporter's derivation stamping and the
/// validator's derivation-coherence gate (protocol SPEC 2.5), so the two
/// cannot drift apart.
const double derivationTolerance = 0.001;

/// The concrete DTCG value families a resolved token can carry, used to
/// check that an alias resolves to a token of a compatible family (protocol
/// SPEC 2.7 gate 3: "resolved terminal type family matches the context").
enum TokenValueFamily {
  /// `dimension`: `{"value": <number>, "unit": "px"}`.
  dimension,

  /// `duration`: `{"value": <number>, "unit": "ms"}`.
  duration,

  /// `number`: a bare JSON number.
  number,

  /// `fontWeight`: a bare JSON number in `100..900`.
  fontWeight,

  /// `color`: the DTCG sRGB + hex color object.
  color,

  /// `shadow`: an array of shadow layer objects.
  shadow,

  /// `typography`: the composite typography object.
  typography,
}

/// A single node in the parsed token tree: either a group (has children) or
/// a token (leaf, carries `$type`/`$value`).
class TokenNode {
  /// Creates a node at [path] backed by the raw JSON [json] for this
  /// position in the tree.
  TokenNode({required this.path, required this.json, required this.children});

  /// Dotted path from the document root, e.g. `spacing.md` or `theme.fieldContentPadding.top`.
  final String path;

  /// The raw JSON object at this position (may include `$type`, `$value`,
  /// `$extensions`, `$description`, `$deprecated` for a token, or nested
  /// members for a group).
  final Map<String, dynamic> json;

  /// Child nodes keyed by their own last path segment. Empty for a token leaf.
  final Map<String, TokenNode> children;

  /// Whether this node is a token leaf (`$type` and `$value` both present).
  bool get isToken => json.containsKey(r'$type') && json.containsKey(r'$value');

  /// The DTCG `$type` string, or `null` if this is not a token leaf.
  String? get type => json[r'$type'] as String?;

  /// The raw `$value` payload, or `null` if this is not a token leaf.
  dynamic get value => json[r'$value'];

  /// The `io.utopiasoft.design` extension map for this node, if present.
  Map<String, dynamic>? get utopiaExtensions {
    final extensions = json[r'$extensions'];
    if (extensions is Map<String, dynamic>) {
      final ns = extensions['io.utopiasoft.design'];
      if (ns is Map<String, dynamic>) {
        return ns;
      }
    }
    return null;
  }
}

/// A parsed token document: the full tree plus a flat index of every token
/// leaf by dotted path, for O(1) alias resolution.
class TokenDocument {
  TokenDocument._(this.root, this.tokensByPath);

  /// Parses [json] (the decoded root object of a token document) into a
  /// [TokenDocument].
  factory TokenDocument.parse(Map<String, dynamic> json) {
    final tokensByPath = <String, TokenNode>{};
    final root = _parseNode(path: '', json: json, tokensByPath: tokensByPath, isRoot: true);
    return TokenDocument._(root, tokensByPath);
  }

  /// The root group node.
  final TokenNode root;

  /// Every token leaf in the document, keyed by its dotted path.
  final Map<String, TokenNode> tokensByPath;

  /// The document root's `$extensions["io.utopiasoft.design"]` map, if present.
  Map<String, dynamic>? get rootExtensions => root.utopiaExtensions;

  static TokenNode _parseNode({
    required String path,
    required Map<String, dynamic> json,
    required Map<String, TokenNode> tokensByPath,
    bool isRoot = false,
  }) {
    final isToken = json.containsKey(r'$type') && json.containsKey(r'$value');
    final children = <String, TokenNode>{};
    if (!isToken) {
      for (final entry in json.entries) {
        final key = entry.key;
        if (key.startsWith(r'$')) {
          continue;
        }
        final childJson = entry.value;
        if (childJson is Map<String, dynamic>) {
          final childPath = isRoot ? key : '$path.$key';
          final childNode = _parseNode(path: childPath, json: childJson, tokensByPath: tokensByPath);
          children[key] = childNode;
        }
      }
    }
    final node = TokenNode(path: path, json: json, children: children);
    if (isToken) {
      tokensByPath[path] = node;
    }
    return node;
  }
}

/// Matches a DTCG alias string (`"{spacing.md}"`) and extracts the
/// referenced path, or returns `null` if [value] is not an alias string.
String? aliasPathOf(dynamic value) {
  if (value is! String) {
    return null;
  }
  final match = RegExp(r'^\{([^{}]+)\}$').firstMatch(value);
  return match?.group(1);
}

/// Result of resolving an alias chain: either the terminal (non-alias) node
/// reached, or a description of why resolution failed.
class AliasResolution {
  const AliasResolution._({this.terminal, this.error, this.chain = const []});

  /// A successful resolution ending at [terminal], with the full alias
  /// [chain] traversed (starting path first, terminal path last).
  factory AliasResolution.resolved(TokenNode terminal, List<String> chain) =>
      AliasResolution._(terminal: terminal, chain: chain);

  /// A failed resolution with an actionable [error] message.
  factory AliasResolution.failed(String error, {List<String> chain = const []}) =>
      AliasResolution._(error: error, chain: chain);

  /// The token this alias chain resolves to, or `null` on failure.
  final TokenNode? terminal;

  /// The actionable error message, or `null` on success.
  final String? error;

  /// The full chain of paths traversed while resolving (for cycle messages).
  final List<String> chain;

  /// Whether resolution succeeded.
  bool get isResolved => terminal != null;
}

/// Resolves an alias chain starting at [startPath] within [document].
/// Follows `{...}` references until a non-alias value is reached, detecting
/// cycles and dangling references.
AliasResolution resolveAlias(TokenDocument document, String startPath) {
  final visited = <String>[];
  var currentPath = startPath;
  while (true) {
    if (visited.contains(currentPath)) {
      final chain = [...visited, currentPath];
      return AliasResolution.failed('circular alias: ${chain.join(' -> ')}', chain: chain);
    }
    visited.add(currentPath);
    final node = document.tokensByPath[currentPath];
    if (node == null) {
      return AliasResolution.failed('dangling alias: "$currentPath" does not resolve to any token', chain: visited);
    }
    final next = aliasPathOf(node.value);
    if (next == null) {
      return AliasResolution.resolved(node, visited);
    }
    currentPath = next;
  }
}

/// Maps a DTCG `$type` name to its [TokenValueFamily], or `null` for unknown
/// types.
TokenValueFamily? familyOfType(String? type) => switch (type) {
  'dimension' => TokenValueFamily.dimension,
  'duration' => TokenValueFamily.duration,
  'number' => TokenValueFamily.number,
  'fontWeight' => TokenValueFamily.fontWeight,
  'color' => TokenValueFamily.color,
  'shadow' => TokenValueFamily.shadow,
  'typography' => TokenValueFamily.typography,
  _ => null,
};
