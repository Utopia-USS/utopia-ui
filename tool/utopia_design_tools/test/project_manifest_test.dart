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

// Tests for generate_manifest --project (protocol SPEC 3.8): opt-in
// extraction, namespaced ids, the class-override mechanism, composes across
// the merge, model/enum extraction, determinism, and the CLI surface, per
// ledger/checkpoints/A11-spec.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/manifest/generator.dart';
import 'package:utopia_design_tools/src/manifest/project_generator.dart';
import 'package:utopia_design_tools/src/manifest/validator.dart';

void main() {
  final repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  final projectRoot = Directory(p.join(Directory.current.path, 'test', 'fixtures', 'project_consumer'));
  final overlayDir = Directory(p.join(projectRoot.path, 'design', 'overlay'));
  final schemaFile = File(p.join(repoRoot.path, 'protocol', 'schemas', 'manifest.schema.json'));
  late final schema = loadSchema(schemaFile.readAsStringSync());

  ProjectGenerationResult generate() => generateProjectManifest(
    projectRoot: projectRoot,
    overlayDir: overlayDir,
    utopiaUiRoot: repoRoot,
  );

  group('project extraction (opt-in)', () {
    test('generation succeeds against the fixture', () {
      final result = generate();
      expect(result.isOk, isTrue, reason: result.errors.join('; '));
    });

    test('MarketTile (overlay by direct filename match) is extracted with a namespaced id', () {
      final result = generate();
      final components = result.projectManifest!['components'] as List;
      final marketTile = components.cast<Map<String, dynamic>>().firstWhere((c) => c['name'] == 'MarketTile');
      expect(marketTile['id'], 'demo_consumer:market-tile');
    });

    test('UnregisteredWidget (no overlay) is NOT extracted', () {
      final result = generate();
      final components = result.projectManifest!['components'] as List;
      expect(components.cast<Map<String, dynamic>>().any((c) => c['name'] == 'UnregisteredWidget'), isFalse);
    });

    test("class-override: DemoRatingStars is bound via star-rating.yaml's class: key", () {
      final result = generate();
      final components = result.projectManifest!['components'] as List;
      final rating = components.cast<Map<String, dynamic>>().firstWhere((c) => c['name'] == 'DemoRatingStars');
      expect(rating['id'], 'demo_consumer:star-rating');
    });

    test('MarketTile composes card + chip (library ids resolve unnamespaced)', () {
      final result = generate();
      final components = result.projectManifest!['components'] as List;
      final marketTile = components.cast<Map<String, dynamic>>().firstWhere((c) => c['name'] == 'MarketTile');
      final composes = (marketTile['composes'] as List?)?.cast<String>() ?? const <String>[];
      expect(composes, containsAll(['card', 'chip']));
    });

    test('overlay states/notes land on the project component', () {
      final result = generate();
      final components = result.projectManifest!['components'] as List;
      final marketTile = components.cast<Map<String, dynamic>>().firstWhere((c) => c['name'] == 'MarketTile');
      expect(marketTile['states'], ['hover']);
      expect(marketTile['notes'], isNotNull);
    });

    test('Quote model and TileDensity enum are captured', () {
      final result = generate();
      final models = result.projectManifest!['models'] as List;
      final quote = models.cast<Map<String, dynamic>>().firstWhere((m) => m['name'] == 'Quote');
      expect(quote['kind'], 'class');

      final components = result.projectManifest!['components'] as List;
      final marketTile = components.cast<Map<String, dynamic>>().firstWhere((c) => c['name'] == 'MarketTile');
      final ctor = (marketTile['constructors'] as List).cast<Map<String, dynamic>>().single;
      final props = (ctor['props'] as List).cast<Map<String, dynamic>>();

      final quoteProp = props.firstWhere((p) => p['name'] == 'quote');
      expect(quoteProp['type'], 'model');
      expect(quoteProp['modelName'], 'Quote');

      final densityProp = props.firstWhere((p) => p['name'] == 'density');
      expect(densityProp['type'], 'enum');
      expect(densityProp['enumName'], 'TileDensity');
      expect((densityProp['values'] as List).cast<String>(), ['compact', 'regular']);
    });

    test("overlay tokenBindingsAdd is merged into the component's tokenBindings, stamped origin \"overlay\"", () {
      final components = (generate().projectManifest!['components'] as List).cast<Map<String, dynamic>>();

      // Bindings extraction is whole-file, so both classes in market_tile.dart
      // share the file's five source bindings; only the overlay's addition
      // differs per component.
      const sourceBindings = ['colors.border', 'colors.primary', 'colors.text', 'tokens.spacing.md', 'tokens.spacing.sm'];
      List<Map<String, String>> expected(String overlayBinding) => [
        for (final path in sourceBindings.take(3)) {'path': path, 'origin': 'source'},
        {'path': overlayBinding, 'origin': 'overlay'},
        for (final path in sourceBindings.skip(3)) {'path': path, 'origin': 'source'},
      ];

      final marketTile = components.firstWhere((c) => c['name'] == 'MarketTile');
      expect(marketTile['tokenBindings'], expected('theme.cardShadow'));

      // The class-override case: the overlay is resolved by the id's local
      // part ("star-rating"), not by the class's derived kebab-case.
      final rating = components.firstWhere((c) => c['name'] == 'DemoRatingStars');
      expect(rating['tokenBindings'], expected('theme.tileHeight'));
    });

    test('project components carry no twin binding (the twin bundle ships with utopia_ui, SPEC 4.1)', () {
      final components = (generate().projectManifest!['components'] as List).cast<Map<String, dynamic>>();
      expect(components.where((c) => c.containsKey('twin')), isEmpty);
    });

    test('project document carries the flavor markers (package, utopiaUiVersion, no merged)', () {
      final result = generate();
      final doc = result.projectManifest!;
      expect(doc['package'], 'demo_consumer');
      expect(doc['utopiaUiVersion'], isNotNull);
      expect(doc.containsKey('merged'), isFalse);
    });
  });

  group('merged manifest', () {
    test('library half is byte-faithful (deep-equal) to the shipped manifest', () {
      final result = generate();
      final merged = result.mergedManifest!;
      final shipped = jsonDecode(File(p.join(repoRoot.path, 'manifest', 'utopia.manifest.json')).readAsStringSync())
          as Map<String, dynamic>;

      final mergedLibraryComponents = (merged['components'] as List)
          .cast<Map<String, dynamic>>()
          .where((c) => !(c['id'] as String).contains(':'))
          .toList();
      expect(mergedLibraryComponents, shipped['components']);
    });

    test('project components are appended after the library half', () {
      final result = generate();
      final components = (result.mergedManifest!['components'] as List).cast<Map<String, dynamic>>();
      final firstProjectIndex = components.indexWhere((c) => (c['id'] as String).contains(':'));
      final lastLibraryIndex = components.lastIndexWhere((c) => !(c['id'] as String).contains(':'));
      expect(firstProjectIndex, greaterThan(lastLibraryIndex));
    });

    test('merged: true and flavor markers are present', () {
      final result = generate();
      final merged = result.mergedManifest!;
      expect(merged['merged'], isTrue);
      expect(merged['package'], 'demo_consumer');
      expect(merged['utopiaUiVersion'], isNotNull);
    });

    test('merged document passes every validate_manifest gate', () {
      final result = generate();
      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot, projectRoot: projectRoot);
      final findings = validator.validate(result.mergedManifest!);
      final errors = findings.where((f) => f.severity == FindingSeverity.error).toList();
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('project document passes every validate_manifest gate', () {
      final result = generate();
      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot, projectRoot: projectRoot);
      final findings = validator.validate(result.projectManifest!);
      final errors = findings.where((f) => f.severity == FindingSeverity.error).toList();
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('a stripped project namespace (demo_consumer:market-tile -> market-tile) reports the '
        'bare-id/stale-merge finding first, ahead of the file/class-not-found noise', () {
      final result = generate();
      final merged = jsonDecode(jsonEncode(result.mergedManifest)) as Map<String, dynamic>;
      final components = (merged['components'] as List).cast<Map<String, dynamic>>();
      final marketTile = components.firstWhere((c) => c['id'] == 'demo_consumer:market-tile');
      marketTile['id'] = 'market-tile';

      final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot, projectRoot: projectRoot);
      final errors = validator.validate(merged).where((f) => f.severity == FindingSeverity.error).toList();

      expect(errors, isNotEmpty);
      expect(errors.first.path, 'components[market-tile]');
      expect(
        errors.first.message,
        'bare id not present in the shipped library manifest - project components must be namespaced '
            '"<package>:<local-part>" (stale or hand-edited merged view - regenerate)',
      );
    });
  });

  group('shipped library manifest input guard', () {
    test('valid JSON that is not an object fails generation with a clean error, not a CastError', () {
      final fakeUtopiaUiRoot = Directory.systemTemp.createTempSync('fake_utopia_ui_');
      addTearDown(() => fakeUtopiaUiRoot.deleteSync(recursive: true));
      File(p.join(fakeUtopiaUiRoot.path, 'pubspec.yaml')).writeAsStringSync('name: utopia_ui\nversion: 9.9.9\n');
      final libraryManifestFile = File(p.join(fakeUtopiaUiRoot.path, 'manifest', 'utopia.manifest.json'));
      libraryManifestFile.parent.createSync(recursive: true);
      libraryManifestFile.writeAsStringSync('[]\n');

      final result = generateProjectManifest(
        projectRoot: projectRoot,
        overlayDir: overlayDir,
        utopiaUiRoot: fakeUtopiaUiRoot,
      );

      expect(result.isOk, isFalse);
      expect(result.errors.single, contains('is not a manifest object'));
    });
  });

  group('determinism', () {
    test('two generation runs produce byte-identical JSON rendering', () {
      final run1 = generate();
      final run2 = generate();
      expect(renderManifestJson(run1.projectManifest!), renderManifestJson(run2.projectManifest!));
      expect(renderManifestJson(run1.mergedManifest!), renderManifestJson(run2.mergedManifest!));
    });
  });

  group('CLI (generate_manifest --project)', () {
    final toolDir = Directory(p.join(Directory.current.path));

    // Work on a throwaway copy of the fixture, not the tracked checkout:
    // generate_manifest --project writes design/*.manifest.json IN PLACE, and
    // those outputs must not linger as source-tree diffs after a test run.
    late Directory scratchProjectRoot;

    setUp(() {
      scratchProjectRoot = Directory.systemTemp.createTempSync('project_manifest_cli_');
      _copyDirectory(projectRoot, scratchProjectRoot);
    });

    tearDown(() {
      scratchProjectRoot.deleteSync(recursive: true);
    });

    Future<ProcessResult> runGenerate(List<String> extraArgs) => Process.run('dart', [
      'run',
      'bin/generate_manifest.dart',
      '--project',
      '--project-dir',
      scratchProjectRoot.path,
      ...extraArgs,
    ], workingDirectory: toolDir.path);

    Future<ProcessResult> runValidate(String manifestPath, List<String> extraArgs) => Process.run('dart', [
      'run',
      'bin/validate_manifest.dart',
      manifestPath,
      '--sources',
      repoRoot.path,
      '--project-dir',
      scratchProjectRoot.path,
      ...extraArgs,
    ], workingDirectory: toolDir.path);

    test('generate_manifest --project exits 0 and writes both files', () async {
      final projectManifestFile = File(p.join(scratchProjectRoot.path, 'design', 'project.manifest.json'));
      final mergedManifestFile = File(p.join(scratchProjectRoot.path, 'design', 'merged.manifest.json'));

      final result = await runGenerate([]);
      expect(result.exitCode, 0, reason: 'stdout=${result.stdout} stderr=${result.stderr}');
      expect(projectManifestFile.existsSync(), isTrue);
      expect(mergedManifestFile.existsSync(), isTrue);
    });

    test('validate_manifest on the written merged.manifest.json exits 0', () async {
      await runGenerate([]);
      final mergedManifestFile = File(p.join(scratchProjectRoot.path, 'design', 'merged.manifest.json'));
      final result = await runValidate(mergedManifestFile.path, []);
      expect(result.exitCode, 0, reason: 'stdout=${result.stdout}');
    });

    test('doctored utopiaUiVersion in the written merged.manifest.json -> validate_manifest exit 1', () async {
      await runGenerate([]);
      final mergedManifestFile = File(p.join(scratchProjectRoot.path, 'design', 'merged.manifest.json'));
      final doc = jsonDecode(mergedManifestFile.readAsStringSync()) as Map<String, dynamic>;
      doc['utopiaUiVersion'] = '0.0.1-doctored';
      final doctoredFile = File(p.join(scratchProjectRoot.path, 'doctored-merged.json'));
      doctoredFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(doc));

      final result = await runValidate(doctoredFile.path, []);
      expect(result.exitCode, 1, reason: 'stdout=${result.stdout}');
      expect(result.stdout.toString(), contains('stale merged view'));
    });
  });
}

/// Recursively copies every file under [source] into [destination]
/// (destination directories are created as needed).
void _copyDirectory(Directory source, Directory destination) {
  for (final entity in source.listSync()) {
    final name = p.basename(entity.path);
    final destPath = p.join(destination.path, name);
    if (entity is Directory) {
      Directory(destPath).createSync(recursive: true);
      _copyDirectory(entity, Directory(destPath));
    } else if (entity is File) {
      Directory(destination.path).createSync(recursive: true);
      entity.copySync(destPath);
    }
  }
}
