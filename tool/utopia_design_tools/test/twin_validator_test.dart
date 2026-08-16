@Timeout(Duration(minutes: 5))
// These tests drive the real CLI entrypoints through `Process.run`, and each
// `dart run` compiles the tool from source. On a loaded CI runner that is
// ~10s per invocation, so a test making three of them sits right on the
// package:test default of 30s. Timing out there is not a clean failure: the
// timeout fires `addTearDown`, the scratch directory is deleted under the
// still-running child process, and the assertion reports whatever exit code
// the child gave for the vanished file - which reads as a logic bug in the
// tool rather than as the timeout it is.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/token_document.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart' show protocolVersion;
import 'package:utopia_design_tools/src/twin/css_generator.dart';
import 'package:utopia_design_tools/src/twin/design_md_generator.dart';
import 'package:utopia_design_tools/src/twin/tailwind_generator.dart';
import 'package:utopia_design_tools/src/twin/twin_validator.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

/// Gates of `validate_twin` (protocol SPEC 4.5 + tokens.css freshness),
/// exercised against the real committed twin (must pass every gate) and
/// against doctored scratch copies (each must trip exactly its gate).
void main() {
  final repoRoot = RepoLocator.findUtopiaUiRepoRoot()!;
  final realTwinDir = Directory(p.join(repoRoot.path, 'twin'));
  final tokensFile = File(p.join(repoRoot.path, 'tokens', 'utopia.tokens.json'));
  final tokenDocument = TokenDocument.parse(jsonDecode(tokensFile.readAsStringSync()) as Map<String, dynamic>);
  final manifestJson =
      jsonDecode(File(p.join(repoRoot.path, 'manifest', 'utopia.manifest.json')).readAsStringSync())
          as Map<String, dynamic>;
  final manifestIds = (manifestJson['components'] as List)
      .whereType<Map<String, dynamic>>()
      .map((c) => c['id'] as String)
      .toSet();

  TwinValidator validatorFor(Directory twinDir, {TokenDocument? document}) => TwinValidator(
    twinDir: twinDir,
    manifestComponentIds: manifestIds,
    tokenDocument: document ?? tokenDocument,
    tokensInputPath: RepoLocator.normalizeInputPath(tokensFile.path),
    profileVersion: protocolVersion,
  );

  List<Finding> errorsOnly(List<Finding> findings) =>
      findings.where((f) => f.severity == FindingSeverity.error).toList();

  List<Finding> warningsOnly(List<Finding> findings) =>
      findings.where((f) => f.severity == FindingSeverity.warning).toList();

  /// A fresh mutable copy of the repo's token document JSON, for fixtures that
  /// have to diverge from it (a rebranded `radius.full`, an extra numeric
  /// spacing step).
  Map<String, dynamic> tokensJsonCopy() => jsonDecode(tokensFile.readAsStringSync()) as Map<String, dynamic>;

  /// Copies the real twin into a scratch dir and applies [doctor] to it. When
  /// [document] is given, every GENERATED surface (both stylesheets and
  /// DESIGN.md's front matter) is regenerated from it first - exactly what
  /// `generate_twin` would write for that document - so the freshness gates
  /// stay green and only the gate under test can fire.
  Directory doctoredTwin(void Function(Directory twin) doctor, {TokenDocument? document}) {
    final scratch = Directory.systemTemp.createTempSync('twin_validator_test');
    addTearDown(() => scratch.deleteSync(recursive: true));
    for (final entity in realTwinDir.listSync()) {
      if (entity is File) {
        entity.copySync(p.join(scratch.path, p.basename(entity.path)));
      }
    }
    if (document != null) {
      final inputPath = RepoLocator.normalizeInputPath(tokensFile.path);
      File(p.join(scratch.path, 'tokens.css'))
          .writeAsStringSync(generateCss(document, inputPath: inputPath, profileVersion: protocolVersion));
      File(p.join(scratch.path, 'tokens.tailwind.css'))
          .writeAsStringSync(generateTailwind(document, inputPath: inputPath, profileVersion: protocolVersion));
      final designMd = File(p.join(scratch.path, 'DESIGN.md'));
      designMd.writeAsStringSync(
        spliceDesignMd(
          designMd.existsSync() ? designMd.readAsStringSync() : null,
          buildFrontMatterBody(document),
        ).content,
      );
    }
    doctor(scratch);
    return scratch;
  }

  /// Appends [css] to the twin's `components.css` as extra rules.
  void appendCss(Directory twin, String css) {
    final file = File(p.join(twin.path, 'components.css'));
    file.writeAsStringSync('${file.readAsStringSync()}\n$css\n');
  }

  /// Splices [inserted] into `components.html` just before its `</head>` line
  /// and returns the real file line number the first inserted line lands on
  /// (so a finding's reported line can be checked against it).
  int spliceIntoHead(Directory twin, List<String> inserted) {
    final html = File(p.join(twin.path, 'components.html'));
    final lines = const LineSplitter().convert(html.readAsStringSync());
    final headIndex = lines.indexWhere((l) => l.contains('</head>'));
    lines.insertAll(headIndex, inserted);
    html.writeAsStringSync('${lines.join('\n')}\n');
    return headIndex + 1;
  }

  test('the real committed twin passes every gate', () {
    final findings = validatorFor(realTwinDir).validate();
    expect(
      errorsOnly(findings),
      isEmpty,
      reason: 'expected a clean twin, got: ${findings.map((f) => f.toLine()).join('; ')}',
    );
    // Gate 5 (forward coverage) is warning-only and deliberately reports the
    // committed twin's real gallery/tier-1 drift, so the committed twin is not
    // warning-free; every OTHER gate still has to be silent on it. Which ids
    // are missing is not asserted here - that is live twin state, covered by
    // the synthetic fixtures below instead.
    final otherWarnings = warningsOnly(findings).where((f) => !f.message.startsWith('twin coverage: ')).toList();
    expect(
      otherWarnings,
      isEmpty,
      reason: 'expected only coverage warnings, got: ${otherWarnings.map((f) => f.toLine()).join('; ')}',
    );
  });

  group('doctored twins each trip their gate', () {
    test('raw hex color in components.css', () {
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'components.css'));
        css.writeAsStringSync('${css.readAsStringSync()}\n.doctored { color: #ff0000; }\n');
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('raw hex color')), isTrue);
    });

    test('raw px matching a token value in components.css', () {
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'components.css'));
        css.writeAsStringSync('${css.readAsStringSync()}\n.doctored { padding: 16px; }\n');
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('raw 16px matches a current')), isTrue);
    });

    test('utopia-literal-ok annotation silences the literal gate', () {
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'components.css'));
        css.writeAsStringSync(
          '${css.readAsStringSync()}\n.doctored { padding: 16px; } /* utopia-literal-ok: test exception */\n',
        );
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('missing manifest id in components.html (coverage, manifest -> twin)', () {
      final twin = doctoredTwin((dir) {
        final html = File(p.join(dir.path, 'components.html'));
        html.writeAsStringSync(html.readAsStringSync().replaceAll('data-utopia-id="button"', ''));
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('button')), isTrue);
    });

    test('stale id in components.html (coverage, twin -> manifest)', () {
      final twin = doctoredTwin((dir) {
        final html = File(p.join(dir.path, 'components.html'));
        html.writeAsStringSync(
          html.readAsStringSync().replaceFirst('</body>', '<section data-utopia-id="ghost"></section></body>'),
        );
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('ghost')), isTrue);
    });

    test('raw rgb() color in components.css', () {
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'components.css'));
        css.writeAsStringSync('${css.readAsStringSync()}\n.doctored { color: rgb(255 0 0); }\n');
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('raw rgb()')), isTrue);
    });

    test('raw font-family and font-weight literals in components.css', () {
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'components.css'));
        css.writeAsStringSync(
          '${css.readAsStringSync()}\n.doctored { font-family: Arial; font-weight: 700; }\n',
        );
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('raw font-family')), isTrue);
      expect(errors.any((f) => f.message.contains('raw font-weight')), isTrue);
    });

    test('@font-face descriptors are exempt from the literals gate', () {
      // Descriptors DEFINE a face (var() is invalid in descriptor position),
      // so the block can never be token-clean - the linter must stay silent
      // inside it while still flagging the same literals outside it.
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'components.css'));
        css.writeAsStringSync(
          '${css.readAsStringSync()}\n'
          '@font-face {\n'
          "  font-family: 'Doctored Face';\n"
          '  font-weight: 800;\n'
          "  src: url('fonts/Doctored.ttf') format('truetype');\n"
          '}\n'
          '.doctored-after { font-weight: 800; }\n',
        );
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.where((f) => f.message.contains('raw font-family')), isEmpty);
      final weightErrors = errors.where((f) => f.message.contains('raw font-weight')).toList();
      expect(weightErrors, hasLength(1), reason: 'only the declaration after the block is flagged');
    });

    test('non-token px and ms literals warn (not error)', () {
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'components.css'));
        css.writeAsStringSync('${css.readAsStringSync()}\n.doctored { width: 137px; transition: all 175ms; }\n');
      });
      final findings = validatorFor(twin).validate();
      final warnings = findings.where((f) => f.severity == FindingSeverity.warning).toList();
      expect(warnings.any((f) => f.message.contains('raw 137px')), isTrue);
      expect(warnings.any((f) => f.message.contains('raw 175ms')), isTrue);
      expect(errorsOnly(findings), isEmpty);
    });

    test('raw color inside an inline <style> block in components.html', () {
      final twin = doctoredTwin((dir) {
        final html = File(p.join(dir.path, 'components.html'));
        html.writeAsStringSync(
          html.readAsStringSync().replaceFirst('</head>', '<style>.injected { color: #ff00aa; }</style></head>'),
        );
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('raw hex color')), isTrue);
    });

    test('raw color in a style attribute; raw px there is allowed', () {
      final twin = doctoredTwin((dir) {
        final html = File(p.join(dir.path, 'components.html'));
        html.writeAsStringSync(
          html.readAsStringSync().replaceFirst(
            '</body>',
            '<div data-utopia-id="button" style="color: #ff0000; height: 12px;"></div></body>',
          ),
        );
      });
      final findings = validatorFor(twin).validate();
      final errors = errorsOnly(findings);
      expect(errors.any((f) => f.message.contains('raw color literal in a style attribute')), isTrue);
      expect(findings.any((f) => f.message.contains('12px')), isFalse, reason: 'style-attribute px is scaffolding');
    });

    test('CSS sharing the <style> opening line is linted at its real line number', () {
      var openerLineNo = 0;
      final twin = doctoredTwin((dir) {
        openerLineNo = spliceIntoHead(dir, ['<style> .opener { color: #ff00aa; }', '</style>']);
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(
        errors.any((f) => f.message.contains('raw hex color') && f.path.endsWith('components.html:$openerLineNo')),
        isTrue,
        reason: errors.map((f) => f.toLine()).join('; '),
      );
    });

    test('CSS sharing the </style> closing line is linted at its real line number', () {
      var closerLineNo = 0;
      final twin = doctoredTwin((dir) {
        closerLineNo = spliceIntoHead(dir, ['<style>', '.closer { border-width: 16px; }</style>']) + 1;
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(
        errors.any(
          (f) => f.message.contains('raw 16px matches a current') && f.path.endsWith('components.html:$closerLineNo'),
        ),
        isTrue,
        reason: errors.map((f) => f.toLine()).join('; '),
      );
    });

    test('uppercase units, color functions and property names are caught too', () {
      final twin = doctoredTwin((dir) {
        appendCss(dir, '.doctored { padding: 16PX; color: RGB(255 0 0); transition: all 200MS; }');
        appendCss(dir, '.doctored-font { Font-Family: Arial; Font-Weight: 700; }');
      });
      final findings = validatorFor(twin).validate();
      final errors = errorsOnly(findings);
      expect(errors.any((f) => f.message.contains('raw 16px matches a current')), isTrue);
      expect(errors.any((f) => f.message.contains('raw rgb()')), isTrue);
      expect(errors.any((f) => f.message.contains('raw font-family')), isTrue);
      expect(errors.any((f) => f.message.contains('raw font-weight')), isTrue);
      expect(warningsOnly(findings).any((f) => f.message.contains('raw 200ms')), isTrue);
    });

    test('a numeric token step name is still in the px hard-fail set', () {
      final tokensJson = tokensJsonCopy();
      (tokensJson['spacing'] as Map<String, dynamic>)['2xl'] = <String, dynamic>{
        r'$type': 'dimension',
        r'$value': <String, dynamic>{'value': 41, 'unit': 'px'},
      };
      final document = TokenDocument.parse(tokensJson);
      final twin = doctoredTwin(
        (dir) => appendCss(dir, '.doctored { padding: 41px; }'),
        document: document,
      );
      final errors = errorsOnly(validatorFor(twin, document: document).validate());
      expect(
        errors.any((f) => f.message.contains('raw 41px matches a current')),
        isTrue,
        reason: errors.map((f) => f.toLine()).join('; '),
      );
    });

    test('font-family: a var() reference plus a generic family passes, without a trailing ;', () {
      final twin = doctoredTwin(
        (dir) => appendCss(dir, '.doctored { font-family: var(--utopia-text-style-text-font-family), sans-serif }'),
      );
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('font-family: a raw family mixed with a var() reference is still flagged', () {
      final twin = doctoredTwin(
        (dir) => appendCss(dir, '.doctored { font-family: Arial, var(--utopia-text-style-text-font-family); }'),
      );
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('raw font-family')), isTrue);
    });

    test('the last declaration in a block carries no ; and is still checked', () {
      final twin = doctoredTwin((dir) {
        appendCss(dir, '.doctored-family {\n  color: var(--utopia-color-text);\n  font-family: Arial\n}');
        appendCss(dir, '.doctored-weight {\n  color: var(--utopia-color-text);\n  font-weight: 700\n}');
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('raw font-family')), isTrue);
      expect(errors.any((f) => f.message.contains('raw font-weight')), isTrue);
    });

    test('a px literal with no integer part reads as a fraction, not its digits', () {
      final twin = doctoredTwin((dir) => appendCss(dir, '.doctored { width: .5px; }'));
      final findings = validatorFor(twin).validate();
      expect(warningsOnly(findings).any((f) => f.message.contains('raw 0.5px')), isTrue);
      expect(findings.any((f) => f.message.contains('raw 5px')), isFalse);
      expect(errorsOnly(findings), isEmpty, reason: errorsOnly(findings).map((f) => f.toLine()).join('; '));
    });

    test('the radius.full px exemption follows the bound token document, not a hard-coded 9999', () {
      final tokensJson = tokensJsonCopy();
      ((tokensJson['radius'] as Map<String, dynamic>)['full'] as Map<String, dynamic>)[r'$value'] =
          <String, dynamic>{'value': 4321, 'unit': 'px'};
      final document = TokenDocument.parse(tokensJson);
      final twin = doctoredTwin(
        (dir) => appendCss(dir, '.pill { border-radius: 4321px; }\n.stale-pill { border-radius: 9999px; }'),
        document: document,
      );
      final findings = validatorFor(twin, document: document).validate();
      expect(findings.any((f) => f.message.contains('4321px')), isFalse, reason: 'the rebranded radius.full is exempt');
      expect(warningsOnly(findings).any((f) => f.message.contains('raw 9999px')), isTrue);
      expect(errorsOnly(findings), isEmpty, reason: errorsOnly(findings).map((f) => f.toLine()).join('; '));
    });

    test('a single-quoted data-utopia-id counts for id coverage', () {
      final twin = doctoredTwin((dir) {
        final html = File(p.join(dir.path, 'components.html'));
        html.writeAsStringSync(
          html.readAsStringSync().replaceAll('data-utopia-id="button"', "data-utopia-id='button'"),
        );
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('hex literals count in value position only, not as an id selector', () {
      final selectorOnly = doctoredTwin(
        (dir) => appendCss(dir, '#c0ffee { color: var(--utopia-color-text); }'),
      );
      final selectorErrors = errorsOnly(validatorFor(selectorOnly).validate());
      expect(selectorErrors, isEmpty, reason: selectorErrors.map((f) => f.toLine()).join('; '));

      final valuePosition = doctoredTwin((dir) => appendCss(dir, '.doctored { color: #fff; }'));
      expect(
        errorsOnly(validatorFor(valuePosition).validate()).any((f) => f.message.contains('raw hex color')),
        isTrue,
      );

      // A value spread over several lines is still value position on its
      // continuation lines.
      final multiLine = doctoredTwin(
        (dir) => appendCss(dir, '.doctored {\n  background: linear-gradient(\n    #fff,\n    #000\n  );\n}'),
      );
      expect(
        errorsOnly(validatorFor(multiLine).validate()).where((f) => f.message.contains('raw hex color')).length,
        2,
      );
    });

    test('the radius.full px exemption applies to border-radius declarations only', () {
      // A rebrand can land radius.full on an ordinary value: matching the
      // exemption by bare value alone would then exempt every 16px in the
      // twin, not just the pill radius.
      final tokensJson = tokensJsonCopy();
      ((tokensJson['radius'] as Map<String, dynamic>)['full'] as Map<String, dynamic>)[r'$value'] =
          <String, dynamic>{'value': 16, 'unit': 'px'};
      final document = TokenDocument.parse(tokensJson);
      final twin = doctoredTwin(
        (dir) => appendCss(
          dir,
          '.pill { border-radius: 16px; }\n'
          '.corner { border-top-left-radius: 16px; }\n'
          '.multiline {\n  border-radius:\n    16px;\n}\n'
          '.padded { padding: 16px; }',
        ),
        document: document,
      );
      final errors = errorsOnly(validatorFor(twin, document: document).validate());
      expect(
        errors.any((f) => f.message.contains('raw 16px matches a current')),
        isTrue,
        reason: 'padding: 16px must still hard-fail',
      );
      expect(
        errors,
        hasLength(1),
        reason: 'every border-radius form stays exempt: ${errors.map((f) => f.toLine()).join('; ')}',
      );
    });

    test('a trailing !important does not break an otherwise token-clean font declaration', () {
      final twin = doctoredTwin((dir) {
        appendCss(dir, '.doctored { font-family: var(--utopia-text-style-text-font-family), sans-serif !important; }');
        appendCss(dir, '.doctored-weight { font-weight: var(--utopia-font-weight-bold) !important; }');
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('a raw font literal next to an !important flag is still flagged', () {
      final twin = doctoredTwin(
        (dir) => appendCss(dir, '.doctored { font-family: Arial !important; font-weight: 700 !important; }'),
      );
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('raw font-family')), isTrue);
      expect(errors.any((f) => f.message.contains('raw font-weight')), isTrue);
    });

    test('the ui-* and CSS Fonts 4 generic family keywords count as clean fallbacks', () {
      final twin = doctoredTwin(
        (dir) => appendCss(
          dir,
          '.doctored {\n'
          '  font-family: var(--utopia-text-style-text-font-family), ui-sans-serif, ui-serif, ui-rounded;\n'
          '}\n'
          '.doctored-more { font-family: var(--utopia-text-style-text-font-family), math, emoji, fangsong; }',
        ),
      );
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('doctored tokens.css trips the freshness gate', () {
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'tokens.css'));
        css.writeAsStringSync(css.readAsStringSync().replaceFirst('--utopia-x: 4', '--utopia-x: 5'));
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('stale')), isTrue);
    });

    test('doctored tokens.tailwind.css trips the freshness gate too', () {
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'tokens.tailwind.css'));
        css.writeAsStringSync(css.readAsStringSync().replaceFirst('--spacing-md: 12px;', '--spacing-md: 13px;'));
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(
        errors.any((f) => f.path == 'tokens.tailwind.css' && f.message.contains('stale')),
        isTrue,
        reason: errors.map((f) => f.toLine()).join('; '),
      );
    });

    test('an absent tokens.tailwind.css is not a finding (generate_twin --skip-tailwind)', () {
      final twin = doctoredTwin((dir) => File(p.join(dir.path, 'tokens.tailwind.css')).deleteSync());
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });
  });

  // --- gates 4-6, on synthetic fixtures ---
  //
  // These never read the committed twin/: gates 5 and 6 report drift the
  // repo's own twin genuinely carries today (and which other sessions are
  // actively editing), so every assertion below is made against a scratch
  // bundle built from scratch, with a synthetic manifest id/state set.

  /// Builds a `<scratch>/twin/` bundle carrying a freshly generated
  /// `tokens.css` (so the freshness gate stays silent and only the gate under
  /// test can speak) plus whichever files the test needs.
  Directory syntheticTwin({String? designMd, String? galleryHtml, String? componentsHtml, String? componentsCss}) {
    final scratch = Directory.systemTemp.createTempSync('twin_validator_synthetic_');
    addTearDown(() => scratch.deleteSync(recursive: true));
    final twin = Directory(p.join(scratch.path, 'twin'))..createSync();
    File(p.join(twin.path, 'tokens.css')).writeAsStringSync(
      generateCss(tokenDocument, inputPath: RepoLocator.normalizeInputPath(tokensFile.path), profileVersion: protocolVersion),
    );
    if (designMd != null) File(p.join(twin.path, 'DESIGN.md')).writeAsStringSync(designMd);
    if (galleryHtml != null) File(p.join(twin.path, 'gallery.html')).writeAsStringSync(galleryHtml);
    if (componentsHtml != null) File(p.join(twin.path, 'components.html')).writeAsStringSync(componentsHtml);
    if (componentsCss != null) File(p.join(twin.path, 'components.css')).writeAsStringSync(componentsCss);
    return twin;
  }

  /// A validator bound to a synthetic manifest (ids + their `states[]`) rather
  /// than the repo's own.
  TwinValidator syntheticValidator(
    Directory twinDir, {
    required Set<String> ids,
    Map<String, List<String>> states = const {},
  }) => TwinValidator(
    twinDir: twinDir,
    manifestComponentIds: ids,
    manifestComponentStates: states,
    tokenDocument: tokenDocument,
    tokensInputPath: RepoLocator.normalizeInputPath(tokensFile.path),
    profileVersion: protocolVersion,
  );

  /// A `DESIGN.md` whose front matter is exactly what `generate_twin` writes
  /// today (so gate 4 passes), followed by [body].
  String designMdWith(String body, {TokenDocument? document}) =>
      '---\n${buildFrontMatterBody(document ?? tokenDocument)}---\n\n$body';

  group('gate 4: DESIGN.md front matter freshness (SPEC 4.6)', () {
    List<Finding> designMdFindings(Directory twin, {Set<String> ids = const {'button'}}) =>
        syntheticValidator(twin, ids: ids).validate().where((f) => f.path == 'DESIGN.md').toList();

    /// The repo's token document with `color.primary` rebranded - a document
    /// whose front matter necessarily differs from the real one.
    TokenDocument rebrandedDocument() {
      final json = tokensJsonCopy();
      final primaryValue =
          ((json['color'] as Map<String, dynamic>)['primary'] as Map<String, dynamic>)[r'$value']
              as Map<String, dynamic>;
      expect(primaryValue['hex'], isNot('#112233'));
      primaryValue['hex'] = '#112233';
      primaryValue['components'] = [0x11 / 255, 0x22 / 255, 0x33 / 255];
      return TokenDocument.parse(json);
    }

    test('front matter regenerated from the bound token document passes, hand-edited body and all', () {
      final twin = syntheticTwin(
        designMd: designMdWith('## Overview\n\nA body hand-edited long after the skeleton was written.\n'),
      );
      final findings = designMdFindings(twin);
      expect(findings, isEmpty, reason: findings.map((f) => f.toLine()).join('; '));
    });

    test('front matter generated from a different token document is stale (error)', () {
      final twin = syntheticTwin(
        designMd: designMdWith('## Overview\n\nBody.\n', document: rebrandedDocument()),
      );
      final findings = designMdFindings(twin);
      expect(findings.map((f) => f.severity), everyElement(FindingSeverity.error));
      expect(
        findings.single.message,
        'front matter stale - regenerate via generate_twin',
        reason: findings.map((f) => f.toLine()).join('; '),
      );
    });

    test('a DESIGN.md with no front matter block at all is reported as malformed (error)', () {
      final twin = syntheticTwin(designMd: '## Overview\n\nSomebody dropped the front matter markers.\n');
      final findings = designMdFindings(twin);
      expect(findings.single.severity, FindingSeverity.error);
      expect(findings.single.message, contains('missing or malformed'));
    });

    test('an opening front matter marker with no closing one is malformed too', () {
      final twin = syntheticTwin(designMd: '---\nname: Utopia\n\n## Overview\n\nBody.\n');
      final findings = designMdFindings(twin);
      expect(findings.single.severity, FindingSeverity.error);
      expect(findings.single.message, contains('missing or malformed'));
    });

    test('an absent DESIGN.md is not a finding (generate_twin --skip-design-md)', () {
      expect(designMdFindings(syntheticTwin()), isEmpty);
    });
  });

  group('gate 5: forward coverage of gallery.html and the DESIGN.md tier-1 list', () {
    String galleryWith(Iterable<String> ids, {String extra = ''}) =>
        '<!doctype html>\n<html>\n<body>\n$extra\n'
        '${ids.map((id) => '  <div class="utopia-$id" data-utopia-id="$id">$id specimen</div>').join('\n')}\n'
        '</body>\n</html>\n';

    String tierOneWith(Iterable<String> ids, {String extra = ''}) => designMdWith(
      '## Components\n\n$extra\n${ids.map((id) => '- `data-utopia-id="$id"`').join('\n')}\n\n'
      "## Do's and Don'ts\n\n- Do keep this list current.\n",
    );

    List<Finding> coverageFindings(List<Finding> findings, String fileSuffix) =>
        findings.where((f) => f.path.endsWith(fileSuffix) && f.message.startsWith('twin coverage: ')).toList();

    test('a manifest id with no specimen warns, summarizes, and leaves the exit code at 0', () {
      final twin = syntheticTwin(galleryHtml: galleryWith(['button']));
      final findings = syntheticValidator(twin, ids: {'button', 'collapsible'}).validate();

      expect(errorsOnly(findings), isEmpty, reason: findings.map((f) => f.toLine()).join('; '));
      expect(FindingReport(findings).exitCode, 0);
      final coverage = coverageFindings(findings, 'gallery.html');
      expect(coverage.map((f) => f.severity), everyElement(FindingSeverity.warning));
      expect(
        coverage.map((f) => f.message),
        containsAll([
          contains('manifest component "collapsible" has no specimen in gallery.html'),
          'twin coverage: 1 covered, 0 omitted, 1 missing (of 2 manifest components)',
        ]),
      );
    });

    test('an omit marker declares the gap: the gate goes fully silent, summary included', () {
      // A declared omission is documentation, not a finding (SPEC 4.1 scopes
      // the gate to "missing ids WITHOUT one"), so a file whose every gap
      // carries a marker reports nothing at all - not even the summary line.
      final twin = syntheticTwin(
        galleryHtml: galleryWith(
          ['button'],
          extra: '<!-- utopia-twin-omit: collapsible -- pure-behaviour widget, nothing to render -->',
        ),
      );
      final coverage = coverageFindings(
        syntheticValidator(twin, ids: {'button', 'collapsible'}).validate(),
        'gallery.html',
      );
      expect(coverage, isEmpty, reason: coverage.map((f) => f.toLine()).join('; '));
    });

    test('the summary is emitted only alongside a real missing id', () {
      final twin = syntheticTwin(
        galleryHtml: galleryWith(
          ['button'],
          extra: '<!-- utopia-twin-omit: collapsible -- pure-behaviour widget, nothing to render -->',
        ),
      );
      final coverage = coverageFindings(
        syntheticValidator(twin, ids: {'button', 'collapsible', 'card'}).validate(),
        'gallery.html',
      );
      expect(
        coverage.map((f) => f.message),
        containsAll([
          contains('manifest component "card" has no specimen in gallery.html'),
          'twin coverage: 1 covered, 1 omitted, 1 missing (of 3 manifest components)',
        ]),
      );
    });

    test('an omit marker naming an id the manifest does not have is a dead omit', () {
      final twin = syntheticTwin(
        galleryHtml: galleryWith(
          ['button'],
          extra: '<!-- utopia-twin-omit: ghost-component -- removed from the library last release -->',
        ),
      );
      final coverage = coverageFindings(syntheticValidator(twin, ids: {'button'}).validate(), 'gallery.html');
      expect(coverage.map((f) => f.message), contains(contains('dead omit')));
    });

    test('an unparseable omit marker warns and silences nothing', () {
      final twin = syntheticTwin(
        galleryHtml: galleryWith(['button'], extra: '<!-- utopia-twin-omit: collapsible no separator here -->'),
      );
      final coverage = coverageFindings(
        syntheticValidator(twin, ids: {'button', 'collapsible'}).validate(),
        'gallery.html',
      );
      expect(coverage.map((f) => f.message), contains(contains('unparseable omit marker')));
      expect(coverage.map((f) => f.message), contains(contains('has no specimen')));
    });

    test('a marker silences the file it lives in, not the other one', () {
      final twin = syntheticTwin(
        galleryHtml: galleryWith(
          ['button'],
          extra: '<!-- utopia-twin-omit: collapsible -- pure-behaviour widget -->',
        ),
        designMd: tierOneWith(['button']),
      );
      final findings = syntheticValidator(twin, ids: {'button', 'collapsible'}).validate();
      expect(coverageFindings(findings, 'gallery.html').map((f) => f.message), isNot(contains(contains('collapsible'))));
      expect(
        coverageFindings(findings, 'DESIGN.md').map((f) => f.message),
        contains(contains('manifest component "collapsible" is missing from the tier-1 list')),
      );
    });

    test('the tier-1 list counts a bare backticked id as covered', () {
      final twin = syntheticTwin(designMd: tierOneWith(['button'], extra: '- Collapsible - `collapsible`'));
      expect(
        coverageFindings(syntheticValidator(twin, ids: {'button', 'collapsible'}).validate(), 'DESIGN.md'),
        isEmpty,
      );
    });

    test('a component named only in prose is not covered (the check is structural)', () {
      final twin = syntheticTwin(galleryHtml: '<html><head><title>header</title></head>\n<body><h1>header</h1>\n<p>The header row sits on top.</p></body></html>\n');
      expect(
        coverageFindings(syntheticValidator(twin, ids: {'header'}).validate(), 'gallery.html').map((f) => f.message),
        contains(contains('manifest component "header" has no specimen')),
      );
    });

    test('a DESIGN.md with no "## Components" section reports one skip warning', () {
      final twin = syntheticTwin(designMd: designMdWith('## Overview\n\nNo components section here.\n'));
      final coverage = coverageFindings(syntheticValidator(twin, ids: {'button'}).validate(), 'DESIGN.md');
      expect(coverage.single.message, contains('no "## Components" section'));
    });

    test('a twin that tracks the manifest exactly stays silent (no summary line)', () {
      final twin = syntheticTwin(galleryHtml: galleryWith(['button']), designMd: tierOneWith(['button']));
      final findings = syntheticValidator(twin, ids: {'button'}).validate();
      expect(findings, isEmpty, reason: findings.map((f) => f.toLine()).join('; '));
    });

    test('an absent gallery.html / DESIGN.md is not a finding (auto-partial twin)', () {
      final findings = syntheticValidator(syntheticTwin(), ids: {'button', 'collapsible'}).validate();
      expect(findings, isEmpty, reason: findings.map((f) => f.toLine()).join('; '));
    });
  });

  group('gate 6: manifest states vs the twin .is-* classes', () {
    String componentsHtmlWith(Map<String, String> bodyById) =>
        '<!doctype html>\n<html>\n<body>\n'
        '${bodyById.entries.map((e) => '  <section class="twin-section" data-utopia-id="${e.key}">\n    ${e.value}\n  </section>').join('\n')}\n'
        '</body>\n</html>\n';

    List<Finding> stateFindings(List<Finding> findings) =>
        findings.where((f) => f.message.startsWith('state drift: ')).toList();

    test('a manifest state with no .is-* class anywhere in the twin warns (and does not fail the run)', () {
      final twin = syntheticTwin(
        componentsHtml: componentsHtmlWith({'button': '<button class="utopia-button" data-utopia-id="button">Go</button>'}),
        componentsCss: '.utopia-button { opacity: 1; }\n',
      );
      final findings = syntheticValidator(twin, ids: {'button'}, states: {'button': ['hover']}).validate();
      expect(errorsOnly(findings), isEmpty, reason: findings.map((f) => f.toLine()).join('; '));
      expect(FindingReport(findings).exitCode, 0);
      expect(stateFindings(findings).single.path, 'button');
      expect(stateFindings(findings).single.message, contains('manifest state "hover" has no .is-* class'));
      expect(stateFindings(findings).single.message, contains('add .is-hover'));
    });

    test('an .is-* class the manifest does not declare warns too (the other direction)', () {
      final twin = syntheticTwin(
        componentsHtml: componentsHtmlWith({
          'button': '<button class="utopia-button is-loading is-on" data-utopia-id="button">Go</button>',
        }),
      );
      final findings = stateFindings(
        syntheticValidator(twin, ids: {'button'}, states: {'button': ['loading']}).validate(),
      );
      expect(findings.single.message, contains('.is-on in the twin has no matching entry'));
    });

    test("a camelCase manifest state matches the twin's .is-readonly class", () {
      final twin = syntheticTwin(componentsCss: '.utopia-switch.is-readonly { opacity: 1; }\n');
      expect(
        stateFindings(syntheticValidator(twin, ids: {'switch'}, states: {'switch': ['readOnly']}).validate()),
        isEmpty,
      );
    });

    test('a kebab-cased .is-read-only spelling matches the same state', () {
      final twin = syntheticTwin(
        componentsHtml: componentsHtmlWith({
          'switch': '<div class="utopia-switch is-read-only" data-utopia-id="switch"></div>',
        }),
      );
      expect(
        stateFindings(syntheticValidator(twin, ids: {'switch'}, states: {'switch': ['readOnly']}).validate()),
        isEmpty,
      );
    });

    test('a state defined only in components.css counts, attributed through its compound selector', () {
      final twin = syntheticTwin(
        componentsCss: '.utopia-sidebar--gradient .utopia-sidebar-tile.is-selected { opacity: 1; }\n',
      );
      expect(
        stateFindings(syntheticValidator(twin, ids: {'sidebar'}, states: {'sidebar': ['selected']}).validate()),
        isEmpty,
      );
    });

    test('the longest matching id owns a class, so switch-field never reads as switch', () {
      final twin = syntheticTwin(
        componentsCss: '.utopia-switch.is-on { opacity: 1; }\n.utopia-switch-field.is-disabled { opacity: 1; }\n',
      );
      final findings = stateFindings(
        syntheticValidator(
          twin,
          ids: {'switch', 'switch-field'},
          states: {
            'switch': ['on'],
            'switch-field': ['disabled'],
          },
        ).validate(),
      );
      expect(findings, isEmpty, reason: findings.map((f) => f.toLine()).join('; '));
    });

    test('a .is-* class named only in a CSS comment is not a definition', () {
      final twin = syntheticTwin(componentsCss: '/* .utopia-button.is-hover is still to be built. */\n');
      final findings = stateFindings(
        syntheticValidator(twin, ids: {'button'}, states: {'button': ['hover']}).validate(),
      );
      expect(findings.single.message, contains('manifest state "hover" has no .is-* class'));
    });

    test('a nested component of another id does not leak its states to the section', () {
      // switch-field's specimens wrap a <span class="utopia-switch is-on">:
      // the .is-on belongs to switch, and switch-field must neither be
      // credited with it nor reported for carrying an undeclared state.
      final twin = syntheticTwin(
        componentsHtml: componentsHtmlWith({
          'switch-field': '<div class="utopia-switch-field is-readonly" data-utopia-id="switch-field">\n'
              '      <span class="utopia-switch is-on" aria-hidden="true"></span>\n'
              '    </div>',
        }),
      );
      final findings = stateFindings(
        syntheticValidator(
          twin,
          ids: {'switch', 'switch-field'},
          states: {
            'switch': ['on'],
            'switch-field': ['readOnly'],
          },
        ).validate(),
      );
      // switch-field: its own .is-readonly matches, the nested .is-on is not
      // its own. switch: its section is absent from this components.html, so
      // its "on" state has no class to match anywhere - the one honest
      // finding here, and it is filed against switch, not switch-field.
      expect(findings.map((f) => f.path), everyElement('switch'));
      expect(findings.single.message, contains('manifest state "on" has no .is-* class'));
    });

    test('an element with no utopia-* class at all falls back to the section it sits in', () {
      // The scaffold's stub markup and hand-written wrappers carry only
      // twin-* classes; a state class on one of those is the section's own.
      final twin = syntheticTwin(
        componentsHtml: componentsHtmlWith({
          'button': '<div class="twin-specimen is-loading" data-utopia-id="button"></div>',
        }),
      );
      expect(
        stateFindings(syntheticValidator(twin, ids: {'button'}, states: {'button': ['loading']}).validate()),
        isEmpty,
      );
    });

    test('the missing-class hint spells the state the way the scaffold does', () {
      // One truth for the spelling: components.css and generate_twin
      // --scaffold both write .is-readonly, so the hint must not suggest a
      // kebab-cased .is-read-only nobody uses.
      final twin = syntheticTwin(componentsCss: '.utopia-text-field { opacity: 1; }\n');
      final findings = stateFindings(
        syntheticValidator(twin, ids: {'text-field'}, states: {'text-field': ['readOnly']}).validate(),
      );
      expect(findings.single.message, contains('add .is-readonly to'));
      expect(findings.single.message, isNot(contains('.is-read-only')));
    });

    test('a component declaring no states is skipped in both directions', () {
      final twin = syntheticTwin(
        componentsHtml: componentsHtmlWith({'card': '<div class="utopia-card is-whatever" data-utopia-id="card"></div>'}),
      );
      expect(stateFindings(syntheticValidator(twin, ids: {'card'}, states: {'card': []}).validate()), isEmpty);
    });
  });

  group('CLI level: --tokens auto-discovery binds to the target twin (real bin/validate_twin.dart)', () {
    // These exercise bin/validate_twin.dart's _resolveTokensFileForTwin: when
    // --tokens is not passed, the freshness gate's token document must come
    // from the TARGET twin's own tokens.css generated-header, resolved
    // against the twin dir's owning root (its parent) - not from whatever
    // design/tokens.json or tokens/utopia.tokens.json auto-discovery finds
    // relative to the current working directory (here, this repo's own
    // default tokens, which the scratch fixtures below deliberately diverge
    // from).
    final toolPackageDir = Directory.current;
    final manifestFile = File(p.join(repoRoot.path, 'manifest', 'utopia.manifest.json'));

    Future<ProcessResult> runValidateTwin(List<String> args) => Process.run('dart', [
      'run',
      'bin/validate_twin.dart',
      '--manifest',
      manifestFile.path,
      ...args,
    ], workingDirectory: toolPackageDir.path);

    test('header present: the header-resolved path wins over CWD auto-discovery', () async {
      final scratchRoot = Directory.systemTemp.createTempSync('validate_twin_header_present_');
      addTearDown(() => scratchRoot.deleteSync(recursive: true));

      // A rebranded token document (color.primary hex+components changed)
      // living under the scratch root, deliberately different from this
      // repo's own tokens/utopia.tokens.json that CWD auto-discovery would
      // otherwise find.
      final rebrandedJson = tokensJsonCopy();
      final primaryColor = (rebrandedJson['color'] as Map<String, dynamic>)['primary'] as Map<String, dynamic>;
      final primaryValue = primaryColor[r'$value'] as Map<String, dynamic>;
      final defaultPrimaryHex = primaryValue['hex'] as String;
      primaryValue['hex'] = '#112233';
      primaryValue['components'] = [0x11 / 255, 0x22 / 255, 0x33 / 255];
      // Sanity: the rebrand really does diverge from this repo's own
      // default tokens (what CWD auto-discovery would otherwise resolve) -
      // otherwise a passing gate below would prove nothing about which
      // path was actually used.
      expect(defaultPrimaryHex, isNot('#112233'));

      final designDir = Directory(p.join(scratchRoot.path, 'design'))..createSync(recursive: true);
      File(p.join(designDir.path, 'tokens.json')).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rebrandedJson));

      final rebrandedDocument = TokenDocument.parse(rebrandedJson);
      final twinDir = Directory(p.join(scratchRoot.path, 'twin'))..createSync(recursive: true);
      File(p.join(twinDir.path, 'tokens.css')).writeAsStringSync(
        generateCss(rebrandedDocument, inputPath: 'design/tokens.json', profileVersion: protocolVersion),
      );

      final result = await runValidateTwin(['--twin-dir', twinDir.path]);
      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      expect(result.stdout as String, isNot(contains('stale')));
    });

    test("header absent: falls back to today's auto-discovery instead of crashing", () async {
      final scratchRoot = Directory.systemTemp.createTempSync('validate_twin_header_absent_');
      addTearDown(() => scratchRoot.deleteSync(recursive: true));

      final twinDir = Directory(p.join(scratchRoot.path, 'twin'))..createSync(recursive: true);
      // A hand-authored tokens.css with no GENERATED header line at all -
      // the resolver must fall back to _resolveDefaultTokensFile (which,
      // run from this repo's root, finds tokens/utopia.tokens.json) rather
      // than failing outright.
      File(p.join(twinDir.path, 'tokens.css')).writeAsStringSync(':root {\n  --utopia-x: 4;\n}\n');

      final result = await runValidateTwin(['--twin-dir', twinDir.path]);
      // The hand-authored tokens.css never byte-matches a real regeneration,
      // so the freshness gate still fires - the point of this test is that
      // resolution itself falls back cleanly (exit 1 from a real finding,
      // not exit 2 from failing to resolve any token document at all).
      expect(result.exitCode, 1, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      expect(result.stdout as String, contains('stale'));
    });
  });
}
