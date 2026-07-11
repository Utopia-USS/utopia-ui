/// The `validate_twin` gates (protocol SPEC section 4.5 and
/// `ledger/checkpoints/A5-spec.md`): a literals linter over the twin's
/// hand-authored CSS, id coverage between the manifest and the twin HTML
/// (both directions), and a `tokens.css` freshness check against the
/// resolved token document.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli/output.dart';
import '../dtcg/token_document.dart';
import '../twin/css_generator.dart';

/// Runs every `validate_twin` gate, reporting every [Finding] (no fail-fast),
/// mirroring `ManifestValidator`/`TokenValidator`'s style.
///
/// [twinDir] is the `twin/` directory to validate (`components.html`,
/// `components.css`, `gallery.html`, `tokens.css`). [manifestComponentIds] is
/// the set of component ids from the resolved manifest (gate 2). Gate 1's
/// spacing/radius/border hard-fail set is read directly from the twin's own
/// `tokens.css` (see `_extractSpacingRadiusBorderPx`) so the linter and the
/// freshness gate never disagree on what "current" means.
/// [tokenDocument]/[tokensInputPath]/[profileVersion] back gate 3's
/// regenerate-and-byte-compare check.
class TwinValidator {
  /// Creates a validator bound to the given twin directory and token
  /// document context.
  const TwinValidator({
    required this.twinDir,
    required this.manifestComponentIds,
    required this.tokenDocument,
    required this.tokensInputPath,
    required this.profileVersion,
  });

  /// The `twin/` directory being validated.
  final Directory twinDir;

  /// Every component id declared in the resolved manifest.
  final Set<String> manifestComponentIds;

  /// The parsed token document backing gate 3's regeneration.
  final TokenDocument tokenDocument;

  /// The token document's source path, recorded in the regenerated
  /// `tokens.css` header comment (must match the on-disk file's header for
  /// gate 3's byte-compare to pass).
  final String tokensInputPath;

  /// The token document's `profileVersion`, recorded the same way.
  final String profileVersion;

  /// Runs gates 1-3 and returns every finding.
  List<Finding> validate() {
    final findings = <Finding>[];

    final tokensCssFile = File(p.join(twinDir.path, 'tokens.css'));
    final currentTokenPx = tokensCssFile.existsSync()
        ? _extractSpacingRadiusBorderPx(tokensCssFile.readAsStringSync())
        : const <double>{};

    // Gate 1: literals linter over every hand-authored twin CSS file (i.e.
    // every *.css under twinDir except tokens.css / tokens.tailwind.css,
    // which are GENERATED and not in scope for this gate).
    for (final cssFile in _handAuthoredCssFiles()) {
      findings.addAll(_lintCssFile(cssFile, currentTokenPx));
    }

    // Gate 1b: the same linter over inline <style> blocks in the twin HTML
    // files (full rule set), plus a color/font-only check on style="..."
    // attributes (raw dimensions there are specimen scaffolding, allowed by
    // SPEC 4.5; raw colors and font literals are not).
    for (final htmlFile in _twinHtmlFiles()) {
      findings.addAll(_lintHtmlFile(htmlFile, currentTokenPx));
    }

    // Gate 2: id coverage, both directions, across every twin HTML file.
    findings.addAll(_checkIdCoverage());

    // Gate 3: tokens.css freshness (regenerate and byte-compare).
    findings.addAll(_checkTokensCssFreshness(tokensCssFile));

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

  static final RegExp _hexColor = RegExp(r'#[0-9a-fA-F]{3,8}\b');
  static final RegExp _rgbHslColor = RegExp(r'\b(rgb|rgba|hsl|hsla)\s*\(');
  static final RegExp _pxValue = RegExp(r'(-?\d+(?:\.\d+)?)px');
  static final RegExp _msValue = RegExp(r'(-?\d+(?:\.\d+)?)ms');
  static final RegExp _fontFamilyDecl = RegExp(r'font-family\s*:\s*([^;]+);');
  static final RegExp _fontWeightDecl = RegExp(r'font-weight\s*:\s*([^;]+);');
  static final RegExp _literalOkAnnotation = RegExp(r'utopia-literal-ok\s*:');

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
  List<Finding> _lintHtmlFile(File file, Set<double> currentTokenPx) {
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
        if (line.contains('</style>')) {
          insideStyleBlock = false;
          findings.addAll(_lintLines(blockLines, relPath, currentTokenPx, firstLineNo: blockFirstLineNo));
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
            _lintLines([line.substring(openEnd + 1, closeStart)], relPath, currentTokenPx, firstLineNo: lineNo),
          );
        } else {
          insideStyleBlock = true;
          blockFirstLineNo = lineNo + 1;
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
        if (_hexColor.hasMatch(value) || _rgbHslColor.hasMatch(value)) {
          findings.add(Finding.error(path, 'raw color literal in a style attribute - use var(--utopia-color-*)'));
        }
        final fontFamilyMatch = _fontFamilyDecl.firstMatch('$value;');
        if (fontFamilyMatch != null && !fontFamilyMatch.group(1)!.contains('var(--utopia-')) {
          findings.add(Finding.error(path, 'raw font-family literal in a style attribute - use var(--utopia-text-style-*-font-family)'));
        }
        final fontWeightMatch = _fontWeightDecl.firstMatch('$value;');
        if (fontWeightMatch != null && !fontWeightMatch.group(1)!.contains('var(--utopia-')) {
          findings.add(Finding.error(path, 'raw font-weight literal in a style attribute - use var(--utopia-font-weight-*)'));
        }
      }
    }
    return findings;
  }

  List<Finding> _lintCssFile(File file, Set<double> currentTokenPx) {
    final lines = const LineSplitter().convert(file.readAsStringSync());
    final relPath = p.relative(file.path, from: twinDir.parent.path);
    return _lintLines(lines, relPath, currentTokenPx);
  }

  List<Finding> _lintLines(List<String> lines, String relPath, Set<double> currentTokenPx, {int firstLineNo = 1}) {
    final findings = <Finding>[];

    // Tracks whether the scan is currently inside a `/* ... */` block that
    // spans multiple lines, so continuation lines of a multi-line doc
    // comment (which do not themselves start with `/*`) are not scanned for
    // literals mentioned in prose.
    var insideBlockComment = false;

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final lineNo = firstLineNo + i;
      final path = '$relPath:$lineNo';

      final stripped = _stripCommentSegments(rawLine, insideAtStart: insideBlockComment);
      final line = stripped.text;
      insideBlockComment = stripped.stillInsideComment;
      if (line.trim().isEmpty) {
        continue;
      }
      if (_literalOkAnnotation.hasMatch(rawLine)) {
        continue;
      }
      if (line.trim().startsWith('//')) {
        continue;
      }

      // Hard-fail: raw hex/rgb/hsl colors.
      if (_hexColor.hasMatch(line)) {
        findings.add(Finding.error(path, 'raw hex color literal in hand-authored twin CSS - use var(--utopia-color-*)'));
      }
      if (_rgbHslColor.hasMatch(line)) {
        findings.add(
          Finding.error(path, 'raw rgb()/rgba()/hsl()/hsla() color literal in hand-authored twin CSS - use var(--utopia-color-*)'),
        );
      }

      // Hard-fail: raw font-family / font-weight literals (a var() reference
      // on the declaration is fine; a bare literal value is not).
      final fontFamilyMatch = _fontFamilyDecl.firstMatch(line);
      if (fontFamilyMatch != null && !fontFamilyMatch.group(1)!.contains('var(--utopia-')) {
        findings.add(Finding.error(path, 'raw font-family literal - use var(--utopia-text-style-*-font-family)'));
      }
      final fontWeightMatch = _fontWeightDecl.firstMatch(line);
      if (fontWeightMatch != null && !fontWeightMatch.group(1)!.contains('var(--utopia-')) {
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
        if (raw == '9999') continue; // utopia-radius-full literal, never flagged.
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

  static String _formatPx(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  /// Extracts every spacing/radius/border custom property's *own literal* px
  /// value from a generated `tokens.css` (skips `var(...)` aliases, e.g.
  /// `--utopia-theme-border-radius: var(--utopia-radius-sm);`, since aliases
  /// do not introduce a new literal value).
  static Set<double> _extractSpacingRadiusBorderPx(String tokensCss) {
    final values = <double>{};
    final declRegExp = RegExp(r'--utopia-(spacing|radius|border)-[a-z-]+:\s*([^;]+);');
    for (final match in declRegExp.allMatches(tokensCss)) {
      final value = match.group(2)!.trim();
      if (value.startsWith('var(')) continue;
      final pxMatch = RegExp(r'^(-?\d+(?:\.\d+)?)px$').firstMatch(value);
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

  static final RegExp _dataUtopiaIdAttr = RegExp('data-utopia-id="([a-z0-9-]+)"');

  static Set<String> _extractDataUtopiaIds(String html) {
    return _dataUtopiaIdAttr.allMatches(html).map((m) => m.group(1)!).toSet();
  }

  // --- Gate 3: tokens.css freshness ---

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
}
