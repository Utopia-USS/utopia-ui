import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/token_document.dart';
import 'package:utopia_design_tools/src/twin/css_generator.dart';
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
    profileVersion: '0.2.0',
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
  /// [document] is given, both generated stylesheets are regenerated from it
  /// first, so the freshness gates stay green and only the gate under test can
  /// fire.
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
          .writeAsStringSync(generateCss(document, inputPath: inputPath, profileVersion: '0.2.0'));
      File(p.join(scratch.path, 'tokens.tailwind.css'))
          .writeAsStringSync(generateTailwind(document, inputPath: inputPath, profileVersion: '0.2.0'));
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
      findings,
      isEmpty,
      reason: 'expected a clean twin, got: ${findings.map((f) => f.toLine()).join('; ')}',
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
        generateCss(rebrandedDocument, inputPath: 'design/tokens.json', profileVersion: '0.2.0'),
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
