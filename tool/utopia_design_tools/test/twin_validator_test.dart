import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/token_document.dart';
import 'package:utopia_design_tools/src/twin/css_generator.dart';
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

  TwinValidator validatorFor(Directory twinDir) => TwinValidator(
    twinDir: twinDir,
    manifestComponentIds: manifestIds,
    tokenDocument: tokenDocument,
    tokensInputPath: RepoLocator.normalizeInputPath(tokensFile.path),
    profileVersion: '0.2.0',
  );

  List<Finding> errorsOnly(List<Finding> findings) =>
      findings.where((f) => f.severity == FindingSeverity.error).toList();

  /// Copies the real twin into a scratch dir and applies [doctor] to it.
  Directory doctoredTwin(void Function(Directory twin) doctor) {
    final scratch = Directory.systemTemp.createTempSync('twin_validator_test');
    addTearDown(() => scratch.deleteSync(recursive: true));
    for (final entity in realTwinDir.listSync()) {
      if (entity is File) {
        entity.copySync(p.join(scratch.path, p.basename(entity.path)));
      }
    }
    doctor(scratch);
    return scratch;
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

    test('doctored tokens.css trips the freshness gate', () {
      final twin = doctoredTwin((dir) {
        final css = File(p.join(dir.path, 'tokens.css'));
        css.writeAsStringSync(css.readAsStringSync().replaceFirst('--utopia-x: 4', '--utopia-x: 5'));
      });
      final errors = errorsOnly(validatorFor(twin).validate());
      expect(errors.any((f) => f.message.contains('stale')), isTrue);
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
      final rebrandedJson = jsonDecode(tokensFile.readAsStringSync()) as Map<String, dynamic>;
      final primaryValue = (rebrandedJson['color'] as Map<String, dynamic>)['primary']['\$value'] as Map<String, dynamic>;
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

    test('header absent: falls back to today\'s auto-discovery instead of crashing', () async {
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
