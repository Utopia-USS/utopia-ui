/// The `validate_twin` gates (protocol SPEC section 4.5 and
/// `ledger/checkpoints/A5-spec.md`): a literals linter over the twin's
/// hand-authored CSS, id coverage between the manifest and the twin HTML
/// (both directions), a freshness check on the generated stylesheets
/// (`tokens.css`, plus `tokens.tailwind.css` when the twin carries one) and on
/// `DESIGN.md`'s GENERATED front matter (SPEC 4.6) against the resolved token
/// document, plus the two warning-only drift reports in
/// [TwinCoverageGates] (gallery/tier-1 coverage and manifest-state parity).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli/output.dart';
import '../dtcg/token_document.dart';
import '../twin/css_generator.dart';
import '../twin/design_md_generator.dart';
import '../twin/tailwind_generator.dart';
import '../twin/twin_coverage.dart';

/// Runs every `validate_twin` gate, reporting every [Finding] (no fail-fast),
/// mirroring `ManifestValidator`/`TokenValidator`'s style.
///
/// [twinDir] is the `twin/` directory to validate (`components.html`,
/// `components.css`, `gallery.html`, `tokens.css`). [manifestComponentIds] is
/// the set of component ids from the resolved manifest (gate 2). Gate 1's
/// spacing/radius/border hard-fail set is read directly from the twin's own
/// `tokens.css` (see `_extractSpacingRadiusBorderPx`) so the linter and the
/// freshness gate never disagree on what "current" means.
/// [tokenDocument]/[tokensInputPath]/[profileVersion] back gate 3's and gate
/// 4's regenerate-and-byte-compare checks. [manifestComponentStates] backs
/// gate 6 and may be left empty, which skips it.
class TwinValidator {
  /// Creates a validator bound to the given twin directory and token
  /// document context.
  const TwinValidator({
    required this.twinDir,
    required this.manifestComponentIds,
    required this.tokenDocument,
    required this.tokensInputPath,
    required this.profileVersion,
    this.manifestComponentStates = const {},
  });

  /// The `twin/` directory being validated.
  final Directory twinDir;

  /// Every component id declared in the resolved manifest.
  final Set<String> manifestComponentIds;

  /// The manifest's `states[]` per component id, backing gate 6's parity
  /// check. Components declaring no states may be omitted; an empty map skips
  /// the gate entirely.
  final Map<String, List<String>> manifestComponentStates;

  /// The parsed token document backing gate 3's regeneration.
  final TokenDocument tokenDocument;

  /// The token document's source path, recorded in the regenerated
  /// `tokens.css` header comment (must match the on-disk file's header for
  /// gate 3's byte-compare to pass).
  final String tokensInputPath;

  /// The token document's `profileVersion`, recorded the same way.
  final String profileVersion;

  /// Runs gates 1-6 and returns every finding.
  List<Finding> validate() {
    final findings = <Finding>[];

    final tokensCssFile = File(p.join(twinDir.path, 'tokens.css'));
    final currentTokenPx = tokensCssFile.existsSync()
        ? _extractSpacingRadiusBorderPx(tokensCssFile.readAsStringSync())
        : const <double>{};
    final radiusFullPx = _resolveRadiusFullPx();

    // Gate 1: literals linter over every hand-authored twin CSS file (i.e.
    // every *.css under twinDir except tokens.css / tokens.tailwind.css,
    // which are GENERATED and not in scope for this gate).
    for (final cssFile in _handAuthoredCssFiles()) {
      findings.addAll(_lintCssFile(cssFile, currentTokenPx, radiusFullPx: radiusFullPx));
    }

    // Gate 1b: the same linter over inline <style> blocks in the twin HTML
    // files (full rule set), plus a color/font-only check on style="..."
    // attributes (raw dimensions there are specimen scaffolding, allowed by
    // SPEC 4.5; raw colors and font literals are not).
    for (final htmlFile in _twinHtmlFiles()) {
      findings.addAll(_lintHtmlFile(htmlFile, currentTokenPx, radiusFullPx: radiusFullPx));
    }

    // Gate 2: id coverage, both directions, across every twin HTML file.
    // RFC-B5 auto-partial mode: a generated-only consumer twin has no
    // components.html - there is nothing for the id-coverage gate to cover,
    // so it is skipped (the CLI prints an info line); the literals linter and
    // the tokens.css freshness gate still run and still carry value.
    if (File(p.join(twinDir.path, 'components.html')).existsSync()) {
      findings.addAll(_checkIdCoverage());
    }

    // Gate 3: generated stylesheet freshness (regenerate and byte-compare),
    // for tokens.css and - when present - its Tailwind variant.
    findings.addAll(_checkTokensCssFreshness(tokensCssFile));
    findings.addAll(_checkTailwindCssFreshness(File(p.join(twinDir.path, 'tokens.tailwind.css'))));

    // Gate 4: the same regenerate-and-byte-compare for DESIGN.md's GENERATED
    // front matter (SPEC 4.6).
    findings.addAll(_checkDesignMdFrontMatterFreshness(File(p.join(twinDir.path, 'DESIGN.md'))));

    // Gates 5-6: warning-only drift reports (gallery/tier-1 coverage and
    // manifest-state parity) - see TwinCoverageGates. They never change the
    // exit code: the twin lagging the manifest on a SHOULD surface is a
    // report, not a build break.
    final coverage = TwinCoverageGates(
      twinDir: twinDir,
      manifestComponentIds: manifestComponentIds,
      manifestComponentStates: manifestComponentStates,
    );
    findings.addAll(coverage.checkForwardCoverage());
    findings.addAll(coverage.checkStateParity());

    return findings;
  }

  // --- Gate 1: literals linter ---

  List<File> _handAuthoredCssFiles() {
    if (!twinDir.existsSync()) return const [];
    return twinDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.css'))
        .where((f) => !p.basename(f.path).startsWith('tokens.'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  // CSS units, function names and property names are case-insensitive, so
  // every literal-detection pattern below is too: `16PX`, `RGB(`, `200MS` and
  // `Font-Family:` are the same declarations the gates already reject in
  // lower case.
  static final RegExp _hexColor = RegExp(r'#[0-9a-fA-F]{3,8}\b');
  static final RegExp _rgbHslColor = RegExp(r'\b(rgb|rgba|hsl|hsla)\s*\(', caseSensitive: false);
  static final RegExp _pxValue = RegExp(r'(-?\d*\.?\d+)px', caseSensitive: false);
  static final RegExp _msValue = RegExp(r'(-?\d*\.?\d+)ms', caseSensitive: false);
  // The declaration value runs to the next `;`, the block's closing `}` or
  // the end of the line - the last declaration in a block carries no `;`.
  static final RegExp _fontFamilyDecl = RegExp(r'font-family\s*:\s*([^;}]+)', caseSensitive: false);
  static final RegExp _fontWeightDecl = RegExp(r'font-weight\s*:\s*([^;}]+)', caseSensitive: false);
  static final RegExp _literalOkAnnotation = RegExp(r'utopia-literal-ok\s*:');
  static final RegExp _utopiaVarReference = RegExp(r'var\s*\(\s*--utopia-', caseSensitive: false);
  static final RegExp _varReferenceOpener = RegExp(r'var\s*\(', caseSensitive: false);

  /// The CSS generic family keywords a `font-family` declaration may name
  /// alongside its required `var(--utopia-*-font-family)` reference (every
  /// twin declaration spells one as the fallback family). Anything else in a
  /// `font-family` value is a raw literal family name.
  static const Set<String> _cssGenericFontFamilies = {
    'sans-serif',
    'serif',
    'monospace',
    'system-ui',
    'ui-monospace',
    'cursive',
    'fantasy',
    // The remaining CSS Fonts 4 generics: keywords, not family names, so a
    // twin spelling one as its fallback is as token-clean as `sans-serif`.
    'ui-sans-serif',
    'ui-serif',
    'ui-rounded',
    'math',
    'emoji',
    'fangsong',
  };

  /// A trailing `!important` on a declaration value, which is a priority flag
  /// rather than part of the value: stripped before the font-family and
  /// font-weight cleanliness checks so a token-clean declaration does not
  /// hard-fail for carrying one. The px/ms/hex checks need no such strip -
  /// they look for literals anywhere in the line, and `!important` is neither.
  static final RegExp _importantFlag = RegExp(r'\s*!\s*important\s*$', caseSensitive: false);

  /// The `radius.full` fallback used when the bound token document carries no
  /// resolvable `radius.full` dimension (see [_resolveRadiusFullPx]).
  static const double _fallbackRadiusFullPx = 9999;

  /// Resolves `radius.full`'s own px value from the bound [tokenDocument] -
  /// the pill-radius sentinel a twin may spell out literally
  /// (`border-radius: 9999px`), exempt from the px literal gate. Reading it
  /// from the token document rather than hard-coding `9999` keeps the
  /// exemption correct after a rebrand moves `radius.full`; falls back to
  /// [_fallbackRadiusFullPx] when the bound document has no `radius.full`
  /// dimension to read (e.g. a partial document in auto-partial mode).
  double _resolveRadiusFullPx() {
    final node = tokenDocument.tokensByPath['radius.full'];
    if (node == null) return _fallbackRadiusFullPx;
    final aliasPath = aliasPathOf(node.value);
    final resolved = aliasPath == null ? node : resolveAlias(tokenDocument, aliasPath).terminal;
    final value = resolved?.value;
    if (resolved?.type == 'dimension' && value is Map) {
      final raw = value['value'];
      if (raw is num) return raw.toDouble();
    }
    return _fallbackRadiusFullPx;
  }

  List<File> _twinHtmlFiles() {
    if (!twinDir.existsSync()) return const [];
    return twinDir.listSync().whereType<File>().where((f) => f.path.endsWith('.html')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  static final RegExp _styleAttribute = RegExp(r'style\s*=\s*"([^"]*)"');

  /// Lints a twin HTML file: `<style>` block contents get the full CSS rule
  /// set (same gates as components.css); `style="..."` attributes get the
  /// color/font hard-fail checks only (raw dimensions in attributes are
  /// specimen scaffolding, allowed per SPEC 4.5).
  List<Finding> _lintHtmlFile(File file, Set<double> currentTokenPx, {required double radiusFullPx}) {
    final findings = <Finding>[];
    final lines = const LineSplitter().convert(file.readAsStringSync());
    final relPath = p.relative(file.path, from: twinDir.parent.path);

    var insideStyleBlock = false;
    final blockLines = <String>[];
    var blockFirstLineNo = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNo = i + 1;

      if (insideStyleBlock) {
        final closeStart = line.indexOf('</style>');
        if (closeStart != -1) {
          insideStyleBlock = false;
          // CSS can share the closing line (`.x { border: 16px }</style>`):
          // that leading substring is block content and has to join
          // blockLines before the flush, or it is never linted at all.
          blockLines.add(line.substring(0, closeStart));
          findings.addAll(
            _lintLines(blockLines, relPath, currentTokenPx, radiusFullPx: radiusFullPx, firstLineNo: blockFirstLineNo),
          );
          blockLines.clear();
        } else {
          blockLines.add(line);
        }
        continue;
      }
      if (line.contains('<style')) {
        final openEnd = line.indexOf('>', line.indexOf('<style'));
        final closeStart = line.indexOf('</style>');
        if (openEnd != -1 && closeStart > openEnd) {
          // Single-line <style>...</style>: lint the inline content directly.
          findings.addAll(
            _lintLines(
              [line.substring(openEnd + 1, closeStart)],
              relPath,
              currentTokenPx,
              radiusFullPx: radiusFullPx,
              firstLineNo: lineNo,
            ),
          );
        } else {
          insideStyleBlock = true;
          if (openEnd != -1) {
            // CSS can share the opening line (`<style> .x { color: #fff }`):
            // the opener's trailing substring is the block's first content
            // line, so the block starts on *this* line and every reported
            // line number stays aligned with the real file lines.
            blockFirstLineNo = lineNo;
            blockLines.add(line.substring(openEnd + 1));
          } else {
            blockFirstLineNo = lineNo + 1;
          }
        }
        continue;
      }

      // style="..." attributes: colors and font literals hard-fail; raw
      // dimensions are allowed (specimen scaffolding). An HTML comment
      // carrying utopia-literal-ok on the same line silences the line.
      if (_literalOkAnnotation.hasMatch(line)) continue;
      for (final match in _styleAttribute.allMatches(line)) {
        final path = '$relPath:$lineNo';
        final value = match.group(1)!;
        if (_hasValuePositionHexColor(value) || _rgbHslColor.hasMatch(value)) {
          findings.add(Finding.error(path, 'raw color literal in a style attribute - use var(--utopia-color-*)'));
        }
        for (final decl in _fontFamilyDecl.allMatches(value)) {
          if (_isTokenCleanFontFamily(decl.group(1)!)) continue;
          findings.add(Finding.error(path, 'raw font-family literal in a style attribute - use var(--utopia-text-style-*-font-family)'));
        }
        for (final decl in _fontWeightDecl.allMatches(value)) {
          if (_isTokenCleanFontWeight(decl.group(1)!)) continue;
          findings.add(Finding.error(path, 'raw font-weight literal in a style attribute - use var(--utopia-font-weight-*)'));
        }
      }
    }
    return findings;
  }

  List<Finding> _lintCssFile(File file, Set<double> currentTokenPx, {required double radiusFullPx}) {
    final lines = const LineSplitter().convert(file.readAsStringSync());
    final relPath = p.relative(file.path, from: twinDir.parent.path);
    return _lintLines(lines, relPath, currentTokenPx, radiusFullPx: radiusFullPx);
  }

  List<Finding> _lintLines(
    List<String> lines,
    String relPath,
    Set<double> currentTokenPx, {
    double radiusFullPx = _fallbackRadiusFullPx,
    int firstLineNo = 1,
  }) {
    final findings = <Finding>[];

    // Tracks whether the scan is currently inside a `/* ... */` block that
    // spans multiple lines, so continuation lines of a multi-line doc
    // comment (which do not themselves start with `/*`) are not scanned for
    // literals mentioned in prose.
    var insideBlockComment = false;

    // Tracks whether the previous line left a declaration value open (a `:`
    // with no `;`/`}` after it), so a value spread over several lines
    // (`background: linear-gradient(` / `#fff,` / `);`) still counts as
    // value position for the color gate.
    var insideDeclarationValue = false;

    // The property name of that still-open declaration, so a continuation line
    // of a multi-line `border-radius:` value is still recognized as one (see
    // [_isBorderRadiusProperty]).
    String? openPropertyName;

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final lineNo = firstLineNo + i;
      final path = '$relPath:$lineNo';

      final stripped = _stripCommentSegments(rawLine, insideAtStart: insideBlockComment);
      final line = stripped.text;
      insideBlockComment = stripped.stillInsideComment;
      final startedInsideDeclarationValue = insideDeclarationValue;
      final startedPropertyName = openPropertyName;
      insideDeclarationValue = _endsInsideDeclarationValue(line, insideAtStart: startedInsideDeclarationValue);
      openPropertyName = insideDeclarationValue ? _propertyNameAt(line, line.length, startedPropertyName) : null;
      if (line.trim().isEmpty) {
        continue;
      }
      if (_literalOkAnnotation.hasMatch(rawLine)) {
        continue;
      }
      if (line.trim().startsWith('//')) {
        continue;
      }

      // Hard-fail: raw hex/rgb/hsl colors. Only value-position hex counts - a
      // hex-only id selector (`#c0ffee { ... }`) is a selector, not a color.
      if (_hasValuePositionHexColor(line, insideValueAtStart: startedInsideDeclarationValue)) {
        findings.add(Finding.error(path, 'raw hex color literal in hand-authored twin CSS - use var(--utopia-color-*)'));
      }
      if (_rgbHslColor.hasMatch(line)) {
        findings.add(
          Finding.error(path, 'raw rgb()/rgba()/hsl()/hsla() color literal in hand-authored twin CSS - use var(--utopia-color-*)'),
        );
      }

      // Hard-fail: raw font-family / font-weight literals. Every declaration
      // on the line is checked (not just the first), and a var(--utopia-*)
      // reference somewhere in the value is not enough on its own - the rest
      // of the value must be free of raw literals too (a generic family
      // keyword is the one exemption, see [_isTokenCleanFontFamily]).
      for (final decl in _fontFamilyDecl.allMatches(line)) {
        if (_isTokenCleanFontFamily(decl.group(1)!)) continue;
        findings.add(Finding.error(path, 'raw font-family literal - use var(--utopia-text-style-*-font-family)'));
      }
      for (final decl in _fontWeightDecl.allMatches(line)) {
        if (_isTokenCleanFontWeight(decl.group(1)!)) continue;
        findings.add(Finding.error(path, 'raw font-weight literal - use var(--utopia-font-weight-*) or var(--utopia-text-style-*-font-weight)'));
      }

      // px literals: hard-fail if the value equals a current spacing/radius/
      // border token value, warn otherwise (0, percentages and fractions are
      // never flagged - `_pxValue` only matches `<number>px` sequences, and a
      // bare `0`/percentage never matches it).
      for (final match in _pxValue.allMatches(line)) {
        final raw = match.group(1)!;
        final value = double.parse(raw);
        if (value == 0) continue;
        // The radius.full literal (`border-radius: 9999px`) is exempt, but
        // only where it can be one: matching by bare value alone would let
        // every other property escape the gate whenever a rebrand moves
        // radius.full onto an ordinary step value (radius.full: 16 would
        // exempt `padding: 16px` too).
        if (value == radiusFullPx &&
            _isBorderRadiusProperty(_propertyNameAt(line, match.start, startedPropertyName))) {
          continue;
        }
        if (currentTokenPx.contains(value)) {
          findings.add(
            Finding.error(
              path,
              'raw ${_formatPx(value)}px matches a current spacing/radius/border token value - use the var(--utopia-*) reference instead',
            ),
          );
        } else {
          findings.add(Finding.warning(path, 'raw ${_formatPx(value)}px literal with no matching token - consider var(--utopia-*) or a utopia-literal-ok annotation'));
        }
      }

      // ms literals: warn only (no ms token family is hard-failed by SPEC 4.5).
      for (final match in _msValue.allMatches(line)) {
        final raw = match.group(1)!;
        findings.add(Finding.warning(path, 'raw ${raw}ms literal - consider var(--utopia-duration-*) or a utopia-literal-ok annotation'));
      }
    }

    return findings;
  }

  /// Strips CSS comment text from [line], carrying block-comment state across
  /// calls via [insideAtStart] and the returned `stillInsideComment` so a
  /// literal mentioned only in a multi-line doc comment's prose (e.g. this
  /// file's own header, or a component rule's explanatory paragraph) is never
  /// mistaken for a real declaration. Handles at most one open/close
  /// transition per line, which covers every comment style used in this
  /// twin's hand-authored CSS (single-line `/* ... */`, and doc-comment blocks
  /// with no code on the opening/closing lines).
  static ({String text, bool stillInsideComment}) _stripCommentSegments(String line, {required bool insideAtStart}) {
    var result = line;
    var inside = insideAtStart;
    while (true) {
      if (inside) {
        final end = result.indexOf('*/');
        if (end == -1) {
          return (text: '', stillInsideComment: true);
        }
        result = result.substring(end + 2);
        inside = false;
        continue;
      }
      final start = result.indexOf('/*');
      if (start == -1) {
        return (text: result, stillInsideComment: false);
      }
      final end = result.indexOf('*/', start + 2);
      if (end == -1) {
        return (text: result.substring(0, start), stillInsideComment: true);
      }
      result = result.substring(0, start) + result.substring(end + 2);
    }
  }

  /// Whether [text] carries a hex color literal in declaration-value
  /// position, i.e. one this gate should flag. The test is the line-scoped
  /// heuristic in [_isHexInValuePosition]: a hex separated from its
  /// declaration's start by a `:` reads as a value, unless a `{` follows it on
  /// the same line, which makes it part of a selector instead. So a hex-only id
  /// selector is exempt exactly while its `{` shares the line
  /// (`#c0ffee { ... }`, `a:hover #c0ffee { ... }`); a selector *list* that
  /// carries its `{` on a later line (`a:hover,` / `#c0ffee,` / `.x {`) is not
  /// recognized as one and still trips the gate, which a `utopia-literal-ok`
  /// annotation on that line silences. [insideValueAtStart] says whether [text]
  /// itself begins inside an already-open declaration value (a value continued
  /// from the previous line).
  static bool _hasValuePositionHexColor(String text, {bool insideValueAtStart = false}) => _hexColor
      .allMatches(text)
      .any((match) => _isHexInValuePosition(text, match.start, match.end, insideValueAtStart: insideValueAtStart));

  /// Whether the hex literal spanning `[start, end)` of [text] sits in
  /// declaration-value position: a `:` separates it from the start of its
  /// declaration (the last `;`/`{`/`}` before it, or the start of an
  /// already-open value per [insideValueAtStart]), and it is not followed by a
  /// `{` that would make it part of a selector instead.
  static bool _isHexInValuePosition(String text, int start, int end, {required bool insideValueAtStart}) {
    final before = text.substring(0, start);
    final declarationStart = _lastIndexOfAny(before, const [';', '{', '}']);
    final afterColon = declarationStart == -1
        ? insideValueAtStart || before.contains(':')
        : before.substring(declarationStart + 1).contains(':');
    if (!afterColon) return false;
    final after = text.substring(end);
    final brace = after.indexOf('{');
    if (brace == -1) return true;
    final terminator = _firstIndexOfAny(after, const [';', '}']);
    return terminator != null && terminator < brace;
  }

  /// The lower-cased property name of the declaration whose value covers
  /// offset [offset] of [text], or `null` when [text] carries no declaration
  /// start before it. [carriedPropertyName] is the property of a declaration
  /// left open by the previous line, used when [offset] sits inside that
  /// continued value. Line-scoped like the rest of these heuristics: a
  /// declaration whose `prop:` was written on an earlier line is only known
  /// through [carriedPropertyName].
  static String? _propertyNameAt(String text, int offset, String? carriedPropertyName) {
    final before = text.substring(0, offset);
    final declarationStart = _lastIndexOfAny(before, const [';', '{', '}']);
    final segment = declarationStart == -1 ? before : before.substring(declarationStart + 1);
    final colon = segment.indexOf(':');
    if (colon == -1) {
      return declarationStart == -1 ? carriedPropertyName : null;
    }
    return segment.substring(0, colon).trim().toLowerCase();
  }

  /// A per-corner `border-radius` longhand (`border-top-left-radius`,
  /// `border-start-end-radius`, vendor-prefixed variants included).
  static final RegExp _borderRadiusLonghand = RegExp(r'^(?:-[a-z]+-)?border-[a-z-]+-radius$');

  /// Whether [property] is a declaration the `radius.full` px exemption
  /// applies to: the `border-radius` shorthand (plain or vendor-prefixed) or
  /// one of its per-corner longhands.
  static bool _isBorderRadiusProperty(String? property) {
    if (property == null) return false;
    return property.endsWith('border-radius') || _borderRadiusLonghand.hasMatch(property);
  }

  /// Whether [line] leaves a declaration value open at its end (so the next
  /// line continues that value), carrying the previous line's state in
  /// [insideAtStart].
  static bool _endsInsideDeclarationValue(String line, {required bool insideAtStart}) {
    final terminator = _lastIndexOfAny(line, const [';', '{', '}']);
    if (terminator == -1) return insideAtStart || line.contains(':');
    return line.substring(terminator + 1).contains(':');
  }

  static int _lastIndexOfAny(String text, List<String> needles) =>
      needles.map(text.lastIndexOf).fold(-1, (a, b) => a > b ? a : b);

  static int? _firstIndexOfAny(String text, List<String> needles) {
    int? first;
    for (final needle in needles) {
      final index = text.indexOf(needle);
      if (index != -1 && (first == null || index < first)) first = index;
    }
    return first;
  }

  /// Whether a `font-family` declaration [value] is token-clean: it must
  /// reference at least one `var(--utopia-*)` custom property, and everything
  /// left once a trailing `!important` and the `var(...)` references are
  /// removed must be a CSS generic family keyword
  /// ([_cssGenericFontFamilies]). A mixed value like
  /// `Arial, var(--utopia-font-body)` still ships a raw family name and is
  /// not clean.
  static bool _isTokenCleanFontFamily(String value) {
    if (!_utopiaVarReference.hasMatch(value)) return false;
    return _stripVarReferences(value.replaceFirst(_importantFlag, ''))
        .split(',')
        .map((part) => part.trim().toLowerCase())
        .where((part) => part.isNotEmpty)
        .every(_cssGenericFontFamilies.contains);
  }

  /// Whether a `font-weight` declaration [value] is token-clean: nothing but
  /// `var(--utopia-*)` references and an optional trailing `!important`.
  /// `font-weight` has no generic keyword worth exempting - `bold`/`700` are
  /// exactly the literals this gate exists to catch.
  static bool _isTokenCleanFontWeight(String value) {
    if (!_utopiaVarReference.hasMatch(value)) return false;
    return _stripVarReferences(value.replaceFirst(_importantFlag, '')).replaceAll(',', '').trim().isEmpty;
  }

  /// Removes every balanced `var(...)` span (fallbacks included) from [value],
  /// leaving only the literal text around the token references.
  static String _stripVarReferences(String value) {
    final buffer = StringBuffer();
    var rest = value;
    while (true) {
      final match = _varReferenceOpener.firstMatch(rest);
      if (match == null) {
        buffer.write(rest);
        return buffer.toString();
      }
      buffer.write(rest.substring(0, match.start));
      var depth = 1;
      var index = match.end;
      while (index < rest.length && depth > 0) {
        if (rest[index] == '(') depth++;
        if (rest[index] == ')') depth--;
        index++;
      }
      rest = rest.substring(index);
    }
  }

  static String _formatPx(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  /// Extracts every spacing/radius/border custom property's *own literal* px
  /// value from a generated `tokens.css` (skips `var(...)` aliases, e.g.
  /// `--utopia-theme-border-radius: var(--utopia-radius-sm);`, since aliases
  /// do not introduce a new literal value).
  static Set<double> _extractSpacingRadiusBorderPx(String tokensCss) {
    final values = <double>{};
    // The name class allows digits: numeric token steps (`spacing.2xl` ->
    // `--utopia-spacing-2xl`) belong in the hard-fail set like any other step.
    final declRegExp = RegExp(r'--utopia-(spacing|radius|border)-[a-z0-9-]+:\s*([^;]+);');
    for (final match in declRegExp.allMatches(tokensCss)) {
      final value = match.group(2)!.trim();
      if (value.startsWith('var(')) continue;
      final pxMatch = RegExp(r'^(-?\d*\.?\d+)px$').firstMatch(value);
      if (pxMatch != null) {
        values.add(double.parse(pxMatch.group(1)!));
      }
    }
    return values;
  }

  // --- Gate 2: id coverage, both directions ---

  List<Finding> _checkIdCoverage() {
    final findings = <Finding>[];
    final htmlFiles = ['components.html', 'gallery.html']
        .map((name) => File(p.join(twinDir.path, name)))
        .where((f) => f.existsSync())
        .toList();

    final idsInHtml = <String>{};
    for (final file in htmlFiles) {
      idsInHtml.addAll(_extractDataUtopiaIds(file.readAsStringSync()));
    }

    // components.html carries the authoritative "every manifest id has a
    // specimen or note entry" contract (SPEC 4.4); gallery.html is a
    // best-effort mirror and is included above only for the reverse
    // (stale-id) direction, not the forward completeness check.
    final componentsHtml = File(p.join(twinDir.path, 'components.html'));
    final idsInComponentsHtml = componentsHtml.existsSync()
        ? _extractDataUtopiaIds(componentsHtml.readAsStringSync())
        : <String>{};

    for (final id in manifestComponentIds) {
      if (!idsInComponentsHtml.contains(id)) {
        findings.add(Finding.error(id, 'manifest component "$id" has no data-utopia-id in components.html (styled specimen or note entry required)'));
      }
    }

    for (final id in idsInHtml) {
      if (!manifestComponentIds.contains(id)) {
        findings.add(Finding.error(id, 'data-utopia-id="$id" in the twin HTML does not exist in the manifest (stale id - rename or remove)'));
      }
    }

    return findings;
  }

  /// Matches `data-utopia-id` in either quoting style (HTML allows both, and a
  /// single-quoted id is still an id the coverage gate must see).
  static final RegExp _dataUtopiaIdAttr = RegExp(r'''data-utopia-id=("|')([a-z0-9-]+)\1''');

  static Set<String> _extractDataUtopiaIds(String html) {
    return _dataUtopiaIdAttr.allMatches(html).map((m) => m.group(2)!).toSet();
  }

  // --- Gate 3: generated stylesheet freshness ---

  List<Finding> _checkTokensCssFreshness(File tokensCssFile) {
    if (!tokensCssFile.existsSync()) {
      return const [Finding.error('tokens.css', 'missing - run generate_twin')];
    }
    final regenerated = generateCss(tokenDocument, inputPath: tokensInputPath, profileVersion: profileVersion);
    final onDisk = tokensCssFile.readAsStringSync();
    if (regenerated != onDisk) {
      return const [Finding.error('tokens.css', 'stale - run generate_twin')];
    }
    return const [];
  }

  /// The same regenerate-and-byte-compare for `tokens.tailwind.css`. Unlike
  /// `tokens.css` the Tailwind variant is optional (`generate_twin
  /// --skip-tailwind`), so an absent file is not a finding - only a committed
  /// one that no longer matches what its generator produces today, which is
  /// exactly how a rename in the Tailwind namespace mapping would otherwise
  /// slip past the gates.
  List<Finding> _checkTailwindCssFreshness(File tailwindCssFile) {
    if (!tailwindCssFile.existsSync()) {
      return const [];
    }
    final regenerated = generateTailwind(tokenDocument, inputPath: tokensInputPath, profileVersion: profileVersion);
    if (regenerated != tailwindCssFile.readAsStringSync()) {
      return const [Finding.error('tokens.tailwind.css', 'stale - run generate_twin')];
    }
    return const [];
  }

  // --- Gate 4: DESIGN.md front matter freshness ---

  /// The `tokens.css` freshness gate's twin for `DESIGN.md` (SPEC 4.6): the
  /// YAML front matter is GENERATED from the token document, so it must be
  /// byte-identical to what `generate_twin` writes today.
  ///
  /// Regenerates through the generator's own [buildFrontMatterBody] +
  /// [spliceDesignMd] - the same pair `generate_twin` calls - so the gate can
  /// never disagree with the generator about what "current" means, and
  /// byte-compares the result against the file on disk. Because
  /// [spliceDesignMd] preserves the body byte-for-byte, any difference is
  /// necessarily in the front matter block (or in the block's markers).
  ///
  /// Like `tokens.tailwind.css`, an absent `DESIGN.md` is not a finding:
  /// `generate_twin --skip-design-md` makes it an opt-out artifact, and a
  /// generated-only twin (RFC-B5 auto-partial mode) legitimately carries none.
  List<Finding> _checkDesignMdFrontMatterFreshness(File designMdFile) {
    if (!designMdFile.existsSync()) {
      return const [];
    }
    final onDisk = designMdFile.readAsStringSync();
    final splice = spliceDesignMd(onDisk, buildFrontMatterBody(tokenDocument));
    if (splice.content == onDisk) {
      return const [];
    }
    if (splice.warning != null) {
      // The splice had to fall back (no front matter block, or no closing
      // marker): report the structural problem rather than "stale", since
      // regenerating will restructure the file rather than only refresh values.
      return const [
        Finding.error('DESIGN.md', 'front matter block is missing or malformed - regenerate via generate_twin'),
      ];
    }
    return const [Finding.error('DESIGN.md', 'front matter stale - regenerate via generate_twin')];
  }
}
