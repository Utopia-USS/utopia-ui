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
  });

  group('the real generated manifest passes every gate', () {
    test('generate then validate the whole repo end to end', () {
      final overlayDir = Directory(p.join(Directory.current.path, 'overlay'));
      final result = generateManifest(utopiaUiRoot: repoRoot, overlayDir: overlayDir);
      expect(result.isOk, isTrue, reason: result.errors.join('; '));

      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
      final errors = errorsOnly(validator.validate(result.manifest!));
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
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
