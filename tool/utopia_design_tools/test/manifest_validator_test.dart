// Table-driven tests over test/fixtures/manifest/{valid,invalid} plus a
// full run against the real generated manifest, per
// ledger/checkpoints/A3-spec.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/manifest/generator.dart';
import 'package:utopia_design_tools/src/manifest/twin_sections.dart';
import 'package:utopia_design_tools/src/manifest/validator.dart';

void main() {
  final repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  final fixturesDir = Directory(p.join(Directory.current.path, 'test', 'fixtures', 'manifest'));
  final schemaFile = File(p.join(repoRoot.path, 'protocol', 'schemas', 'manifest.schema.json'));

  late final schema = loadSchema(schemaFile.readAsStringSync());

  Map<String, dynamic> loadFixture(String relativePath) {
    final file = File(p.join(fixturesDir.path, relativePath));
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  List<Finding> errorsOnly(List<Finding> findings) =>
      findings.where((f) => f.severity == FindingSeverity.error).toList();

  group('valid fixture passes every gate', () {
    test('mini.manifest.json (no --sources: schema + id/derivation + referential integrity only)', () {
      final validator = ManifestValidator(schema);
      final doc = loadFixture('valid/mini.manifest.json');
      final errors = errorsOnly(validator.validate(doc));
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('mini.manifest.json validates cleanly with --sources pointing at the real repo '
        '(bindings + packageVersion gates included)', () {
      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
      final doc = loadFixture('valid/mini.manifest.json');
      // The fixture's packageVersion is stamped from the repo's own resolved
      // version rather than hardcoded, so this test passes at any pubspec.yaml
      // version (RELEASING.md bumps it) instead of failing as a phantom
      // drift-gate red. The negative wrong-package-version fixture below is
      // deliberately left mismatched and untouched.
      doc['packageVersion'] = readPackageVersion(File(p.join(repoRoot.path, 'pubspec.yaml')));
      final errors = errorsOnly(validator.validate(doc));
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('origin-and-twin.manifest.json (protocol 0.3.0 shapes: object tokenBindings + a twin binding)', () {
      final validator = ManifestValidator(schema);
      final doc = loadFixture('valid/origin-and-twin.manifest.json');
      final errors = errorsOnly(validator.validate(doc));
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });
  });

  group('protocol version compatibility (VERSIONING.md)', () {
    // The manifest fixtures were written for protocol 0.1/0.2, and the
    // generator now stamps 0.3.0: an older minor stays valid, which is the
    // whole point of an additive bump.
    test('a 0.2 document (bare-string tokenBindings, no origin) still validates cleanly', () {
      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
      final doc = loadFixture('valid/mini.manifest.json');
      doc['packageVersion'] = readPackageVersion(File(p.join(repoRoot.path, 'pubspec.yaml')));
      doc['schemaVersion'] = '0.2.0';

      final findings = validator.validate(doc);
      expect(errorsOnly(findings), isEmpty, reason: findings.map((f) => f.toLine()).join('; '));
      expect(findings.where((f) => f.path == 'schemaVersion'), isEmpty);
    });

    test('a newer minor warns instead of failing', () {
      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
      final doc = loadFixture('valid/mini.manifest.json');
      doc['packageVersion'] = readPackageVersion(File(p.join(repoRoot.path, 'pubspec.yaml')));
      doc['schemaVersion'] = '0.99.0';

      final findings = validator.validate(doc);
      expect(errorsOnly(findings), isEmpty, reason: findings.map((f) => f.toLine()).join('; '));
      expect(
        findings.where((f) => f.severity == FindingSeverity.warning).map((f) => f.message).single,
        'schemaVersion "0.99.0" is newer than this tool understands (protocol $manifestSchemaVersion)',
      );
    });

    test('a major mismatch fails', () {
      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
      final doc = loadFixture('valid/mini.manifest.json');
      doc['packageVersion'] = readPackageVersion(File(p.join(repoRoot.path, 'pubspec.yaml')));
      doc['schemaVersion'] = '1.0.0';

      final errors = errorsOnly(validator.validate(doc));
      expect(
        errors.map((f) => f.message),
        contains('schemaVersion "1.0.0" has a major version incompatible with this tool '
            '(protocol $manifestSchemaVersion)'),
      );
    });
  });

  group('the real generated manifest passes every gate', () {
    final overlayDir = Directory(p.join(Directory.current.path, 'overlay'));

    Map<String, dynamic> generated() {
      final result = generateManifest(utopiaUiRoot: repoRoot, overlayDir: overlayDir);
      expect(result.isOk, isTrue, reason: result.errors.join('; '));
      return result.manifest!;
    }

    List<Map<String, dynamic>> componentsOf(Map<String, dynamic> manifest) =>
        (manifest['components'] as List).cast<Map<String, dynamic>>();

    test('generate then validate the whole repo end to end', () {
      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
      final errors = errorsOnly(validator.validate(generated()));
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('it declares the protocol version this tool implements', () {
      expect(generated()['schemaVersion'], manifestSchemaVersion);
    });

    test('every tokenBindings entry is an object carrying a known origin', () {
      final entries = componentsOf(generated()).expand((c) => c['tokenBindings'] as List).toList();
      expect(entries, isNotEmpty);
      expect(
        entries.whereType<Map<String, dynamic>>().where((b) => b['path'] is String).length,
        entries.length,
        reason: 'every entry must carry a string path',
      );
      expect(
        entries.cast<Map<String, dynamic>>().map((b) => b['origin']).toSet(),
        everyElement(isIn(const ['source', 'overlay'])),
      );
    });

    test('the twin field is emitted exactly for the ids twin/components.html renders', () {
      // Derived from the twin bundle itself rather than a hardcoded id list,
      // so this stays true as the twin gains or loses sections.
      final twinIds = readTwinSectionIdsFor(repoRoot);
      final components = componentsOf(generated());
      final withTwin = components.where((c) => c.containsKey('twin')).map((c) => c['id'] as String).toSet();
      final allIds = components.map((c) => c['id'] as String).toSet();

      expect(withTwin, allIds.intersection(twinIds));
      for (final component in components.where((c) => c.containsKey('twin'))) {
        expect(component['twin'], {
          'file': 'components.html',
          'selector': '[data-utopia-id="${component['id']}"]',
        });
      }
    });
  });

  group('invalid fixtures each trip their gate', () {
    final cases = <String, String>{
      'invalid/wrong-package-version.manifest.json': 'packageVersion',
      'invalid/dangling-model-name.manifest.json': 'no entry in "models"',
      'invalid/dangling-composes.manifest.json': 'unknown component id',
      'invalid/bad-id-case.manifest.json': 'does not match the kebab-case derivation',
      'invalid/duplicate-id.manifest.json': 'duplicate component id',
      // unknown-state is a schema-level (enum) violation, so its message
      // text comes straight from json_schema rather than this package's own
      // refinement layer; match on the value instead of a custom message.
      'invalid/unknown-state.manifest.json': 'glowing',
      'invalid/stale-binding.manifest.json': 'stale binding',
      // An unknown origin value is a schema-level (oneOf) violation, so the
      // message comes from json_schema rather than this package's refinement
      // layer - match the failing definition instead of a custom message.
      'invalid/bad-binding-origin.manifest.json': 'definitions/tokenBinding/oneOf',
    };

    for (final entry in cases.entries) {
      test('${entry.key} produces an error containing "${entry.value}"', () {
        final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
        final doc = loadFixture(entry.key);
        final errors = errorsOnly(validator.validate(doc));
        expect(errors, isNotEmpty, reason: 'expected at least one error for ${entry.key}');
        expect(
          errors.any((f) => f.message.contains(entry.value)),
          isTrue,
          reason: 'none of ${errors.map((f) => f.toLine()).join('; ')} contained "${entry.value}"',
        );
      });
    }
  });

  group('wrong-typed sections stay findings, never crashes', () {
    // validate() reports every finding instead of failing fast, so a section
    // the schema gate already rejected must not throw a CastError on the way
    // through the later gates.
    for (final section in ['models', 'helpers']) {
      test('"$section": {} reports the schema finding and nothing else', () {
        final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
        final doc = loadFixture('valid/mini.manifest.json');
        doc['packageVersion'] = readPackageVersion(File(p.join(repoRoot.path, 'pubspec.yaml')));
        doc[section] = <String, dynamic>{};

        final errors = errorsOnly(validator.validate(doc));
        expect(errors.map((f) => f.path), [section], reason: errors.map((f) => f.toLine()).join('; '));
      });
    }

    test('a wrong-typed "package" reports the schema finding instead of throwing a CastError', () {
      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
      final doc = <String, dynamic>{'schemaVersion': '0.2.0', 'package': 123, 'components': <dynamic>[]};

      // A throw here fails the test outright; the findings are the schema
      // gate's own report on the wrong-typed value.
      final findings = validator.validate(doc);
      expect(findings, isNotEmpty);
      expect(
        errorsOnly(findings).map((f) => f.path),
        contains('package'),
        reason: findings.map((f) => f.toLine()).join('; '),
      );
    });
  });

  group('CLI (validate_manifest): valid JSON that is not a manifest object', () {
    final toolDir = Directory.current;

    for (final content in ['[]', '"not-a-manifest"', '42']) {
      test('$content exits 2 with a "not a manifest object" error', () async {
        final tempDir = Directory.systemTemp.createTempSync('validate_manifest_input_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final targetFile = File(p.join(tempDir.path, 'not-an-object.manifest.json'))..writeAsStringSync('$content\n');

        final result = await Process.run('dart', [
          'run',
          'bin/validate_manifest.dart',
          targetFile.path,
          '--sources',
          repoRoot.path,
        ], workingDirectory: toolDir.path);

        expect(result.exitCode, 2, reason: 'stdout=${result.stdout} stderr=${result.stderr}');
        expect(result.stderr.toString(), contains('is not a manifest object'));
      });
    }
  });

  group('SPEC 3.8 flavor gates: invalid fixtures each trip their gate', () {
    final projectRoot = Directory(p.join(Directory.current.path, 'test', 'fixtures', 'project_consumer'));
    final cases = <String, String>{
      'invalid/bare-id-in-project.manifest.json': 'bare id',
      'invalid/namespaced-id-in-library.manifest.json': 'contains namespaced id',
      'invalid/missing-utopia-ui-version.manifest.json': 'utopiaUiVersion is required',
      'invalid/utopia-ui-version-on-library.manifest.json': 'utopiaUiVersion must be absent',
      'invalid/stale-merged-library-entry.manifest.json': 'stale merged view',
      'invalid/model-collision-merged.manifest.json': 'duplicate model name',
      'invalid/merged-package-utopia-ui.manifest.json': 'must carry the consumer project package name',
    };

    for (final entry in cases.entries) {
      test('${entry.key} produces an error containing "${entry.value}"', () {
        final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot, projectRoot: projectRoot);
        final doc = loadFixture(entry.key);
        final errors = errorsOnly(validator.validate(doc));
        expect(errors, isNotEmpty, reason: 'expected at least one error for ${entry.key}');
        expect(
          errors.any((f) => f.message.contains(entry.value)),
          isTrue,
          reason: 'none of ${errors.map((f) => f.toLine()).join('; ')} contained "${entry.value}"',
        );
      });
    }
  });
}
