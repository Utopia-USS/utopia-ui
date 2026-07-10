/// `tokenBindings` extraction: an AST visitor over a component's source file
/// that finds every `UtopiaThemeData` member the component reads, normalized
/// to the dotted vocabulary in protocol SPEC section 3.6.
///
/// Shared verbatim by `generate_manifest` (produce) and `validate_manifest`
/// (re-check against source) - see `ledger/checkpoints/A3-spec.md`.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Extracts the set of dotted `tokenBindings` paths a single file's AST
/// reads, per the two mechanisms in the spec:
///
/// 1. Direct chains rooted at `context.<theme|colors|textStyles|tokens|
///    spacing|radius|fieldDecoration>` or `UtopiaTheme.of/read(ctx)`.
/// 2. One-hop local aliasing: `final x = context.<prefix>;` then `x.Y`.
///
/// Whole-file scope: private helper widgets in the same file are included,
/// matching how a component's rendering is often split across `_build*`
/// methods and private subwidgets in the same file.
List<String> extractTokenBindings(CompilationUnit unit) {
  final visitor = _TokenBindingVisitor();
  unit.accept(visitor);
  final sorted = visitor.bindings.toList()..sort();
  return sorted;
}

/// The theme-rooted prefixes recognized as mechanism-1 chain roots.
const Set<String> _themeRootPrefixes = {'colors', 'textStyles', 'tokens', 'spacing', 'radius', 'theme'};

/// Nested `UtopiaTokens` family names (the second segment under `tokens.`).
const Set<String> _tokenFamilies = {'spacing', 'radius', 'borders', 'shadows', 'fontWeights', 'durations', 'breakpoints'};

class _TokenBindingVisitor extends RecursiveAstVisitor<void> {
  final Set<String> bindings = {};

  /// Local variable name -> normalized alias root (one of
  /// `colors`/`textStyles`/`tokens`/`spacing`/`radius`/`theme`), populated as
  /// `final x = context.<prefix>...;` (or `final y = theme.colors;`, one hop
  /// off an existing alias) declarations are encountered. Two-hop aliasing
  /// (alias of an alias beyond one extra hop) is not tracked, per spec.
  final Map<String, String> _aliases = {};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer != null) {
      final chain = _asChain(initializer);
      if (chain != null) {
        final root = _resolveRoot(chain.rootName);
        if (root != null) {
          final aliasTarget = _aliasTargetFor(root, chain.segments);
          if (aliasTarget != null) {
            _aliases[node.name.lexeme] = aliasTarget;
          }
        }
      }
    }
    super.visitVariableDeclaration(node);
  }

  /// Visits every top-level property-read expression exactly once by
  /// walking the longest contiguous member-access chain from its root
  /// (`context`/an alias/`UtopiaTheme.of(...)`) and recursing into the
  /// non-chain subexpressions (call arguments, etc.) manually, so inner
  /// chains are not independently re-visited as spurious short bindings by
  /// the generic recursive visitor.
  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isChainInterior(node)) return;
    final chain = _asChain(node);
    if (chain != null) {
      _recordChain(chain);
      _visitNonChainChildren(chain.tail);
      return;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isChainInterior(node)) return;
    final chain = _asChain(node);
    if (chain != null) {
      _recordChain(chain);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isChainInterior(node)) return;
    final chain = _asChain(node);
    if (chain != null) {
      _recordChain(chain);
      _visitNonChainChildren(chain.tail);
      return;
    }
    super.visitMethodInvocation(node);
  }

  /// Whether [node] is itself the target/receiver sub-expression of an outer
  /// chain node (its parent is a [PropertyAccess]/[PrefixedIdentifier] whose
  /// target/prefix is exactly this node). Such nodes are visited as part of
  /// the outer chain walk in [_asChain] and must not be independently
  /// re-recorded, which is what produces spurious short bindings like a bare
  /// `theme.colors` alongside the full `theme.colors.surface`.
  bool _isChainInterior(AstNode node) {
    final parent = node.parent;
    if (parent is PropertyAccess && identical(parent.target, node)) return true;
    if (parent is PrefixedIdentifier && identical(parent.prefix, node)) return true;
    return false;
  }

  // ---------------------------------------------------------------------
  // Chain parsing: turn `a.b.c(...)` / `a.b.c` into a root name + ordered
  // field-name segments, whatever mix of PropertyAccess/PrefixedIdentifier/
  // MethodInvocation the parser produced for it.
  // ---------------------------------------------------------------------

  _Chain? _asChain(Expression expr) {
    final segments = <String>[];
    Expression? current = expr;
    Expression? tail;
    while (current != null) {
      if (current is PropertyAccess) {
        segments.insert(0, current.propertyName.name);
        current = current.target;
        continue;
      }
      if (current is PrefixedIdentifier) {
        segments.insert(0, current.identifier.name);
        current = current.prefix;
        continue;
      }
      if (current is MethodInvocation && current.target == null) {
        // A bare call in the middle of nothing (e.g. `UtopiaTheme.of(ctx)`
        // itself, when its target is a SimpleIdentifier `UtopiaTheme`, is
        // handled below as a special root case) - not a chain segment.
        break;
      }
      break;
    }
    if (current == null) return null;
    if (current is SimpleIdentifier) {
      tail = current;
      return _Chain(rootName: current.name, segments: segments, tail: tail);
    }
    if (current is MethodInvocation) {
      final target = current.target;
      if (target is SimpleIdentifier &&
          target.name == 'UtopiaTheme' &&
          (current.methodName.name == 'of' || current.methodName.name == 'read')) {
        return _Chain(rootName: 'UtopiaTheme.${current.methodName.name}', segments: segments, tail: current);
      }
    }
    return null;
  }

  /// Resolves a chain's textual root (`context`, `ctx`, `UtopiaTheme.of`,
  /// `UtopiaTheme.read`, or a tracked local alias name) to its normalized
  /// alias-root vocabulary word (`colors`/`textStyles`/`tokens`/`spacing`/
  /// `radius`/`theme`), or `null` if the root isn't theme-rooted at all.
  String? _resolveRoot(String rootName) {
    if (rootName == 'UtopiaTheme.of' || rootName == 'UtopiaTheme.read') return 'theme';
    if (_aliases.containsKey(rootName)) return _aliases[rootName];
    if (rootName == 'context' || rootName == 'ctx') return '__context__';
    return null;
  }

  /// For a chain whose resolved root is `contextRoot` (already covers
  /// `theme`/`colors`/etc. via [_resolveRoot]) with field [segments] read
  /// off it, decides whether the read as a whole should itself be tracked
  /// as a new one-hop alias (`final theme = context.theme;` -> alias
  /// `theme`; `final c = theme.colors;` -> alias `colors`), returning the
  /// normalized alias-root word to store, or `null` if this expression does
  /// not denote a plain rooted read (so should not be aliased).
  String? _aliasTargetFor(String contextRoot, List<String> segments) {
    if (contextRoot == '__context__') {
      if (segments.length != 1) return null;
      final field = segments.first;
      return _themeRootPrefixes.contains(field) ? field : null;
    }
    // One more hop off an existing alias, e.g. `theme.colors` -> `colors`.
    if (segments.length == 1 && _themeRootPrefixes.contains(segments.first)) {
      return segments.first;
    }
    return null;
  }

  void _recordChain(_Chain chain) {
    final root = _resolveRoot(chain.rootName);
    if (root == null) return;
    if (root == '__context__') {
      if (chain.segments.isEmpty) return;
      final field = chain.segments.first;
      if (field == 'fieldDecoration') {
        bindings.add('theme.fieldDecoration');
        return;
      }
      if (!_themeRootPrefixes.contains(field)) return;
      _emit(field, chain.segments.skip(1).toList());
      return;
    }
    _emit(root, chain.segments);
  }

  void _emit(String root, List<String> rest) {
    if (rest.isEmpty) return;
    switch (root) {
      case 'colors':
        bindings.add('colors.${rest.first}');
      case 'textStyles':
        bindings.add('textStyles.${rest.first}');
      case 'spacing':
        bindings.add('tokens.spacing.${rest.first}');
      case 'radius':
        bindings.add('tokens.radius.${rest.first}');
      case 'tokens':
        _emitTokens(rest);
      case 'theme':
        _emitTheme(rest);
    }
  }

  void _emitTokens(List<String> rest) {
    if (rest.isEmpty) return;
    final first = rest.first;
    if (first == 'x') {
      bindings.add('tokens.x');
      return;
    }
    if (_tokenFamilies.contains(first) && rest.length > 1) {
      bindings.add('tokens.$first.${rest[1]}');
    }
  }

  void _emitTheme(List<String> rest) {
    if (rest.isEmpty) return;
    final first = rest.first;
    if (first == 'colors' && rest.length > 1) {
      bindings.add('colors.${rest[1]}');
      return;
    }
    if (first == 'textStyles' && rest.length > 1) {
      bindings.add('textStyles.${rest[1]}');
      return;
    }
    if (first == 'spacing' && rest.length > 1) {
      bindings.add('tokens.spacing.${rest[1]}');
      return;
    }
    if (first == 'radius' && rest.length > 1) {
      bindings.add('tokens.radius.${rest[1]}');
      return;
    }
    if (first == 'tokens' && rest.length > 1) {
      _emitTokens(rest.skip(1).toList());
      return;
    }
    // Any other theme.<slotOrGetter> (borderRadius, cardDecoration,
    // dividerThickness, fieldContentPadding, fieldMinHeight, pageTopPadding,
    // tileHeight, cardRadius, cardShadow, menuShadow, cardBorderWidth,
    // fieldDecoration, cardBorderDecoration, ...).
    bindings.add('theme.$first');
  }

  /// After recording a full chain rooted in theme territory, the chain's
  /// deepest node (`tail`, e.g. the `context`/`ctx` [SimpleIdentifier] or the
  /// `UtopiaTheme.of(ctx)` [MethodInvocation]) still needs its own
  /// non-chain children visited normally (e.g. the `ctx` argument expression
  /// inside `UtopiaTheme.of(ctx)`) so nested reads elsewhere in the same
  /// statement are not skipped.
  void _visitNonChainChildren(AstNode? tail) {
    if (tail == null) return;
    if (tail is MethodInvocation) {
      tail.argumentList.accept(this);
    }
  }
}

/// A parsed member-access chain: `rootName` is the textual root (`context`,
/// `ctx`, `UtopiaTheme.of`, `UtopiaTheme.read`, or any other identifier),
/// `segments` are the field names read after it in order, and `tail` is the
/// deepest AST node reached (used to visit any non-chain subexpressions it
/// still owns, e.g. call arguments).
class _Chain {
  const _Chain({required this.rootName, required this.segments, required this.tail});

  final String rootName;
  final List<String> segments;
  final AstNode? tail;
}
