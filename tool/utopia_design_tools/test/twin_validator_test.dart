import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/token_document.dart';
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
}
