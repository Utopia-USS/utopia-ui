// Generation + validation over a synthetic, utopia_ui-shaped source tree
// (pubspec + barrel + one src file + one overlay, written to a temp dir): the
// cases the real repo's own sources do not currently contain - an overlay
// `tokenBindingsAdd` escape hatch, a component class used as another
// component's prop type, and an unnamed extension.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/manifest/generator.dart';
import 'package:utopia_design_tools/src/manifest/validator.dart';

void main() {
  final repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  final schemaFile = File(p.join(repoRoot.path, 'protocol', 'schemas', 'manifest.schema.json'));
  late final schema = loadSchema(schemaFile.readAsStringSync());

  late Directory fixtureRoot;
  late Directory overlayDir;

  setUp(() {
    fixtureRoot = Directory.systemTemp.createTempSync('synthetic_utopia_ui_');
    // The overlay directory validate_manifest resolves for a bare-id document,
    // mirroring generate_manifest's own default.
    overlayDir = Directory(p.join(fixtureRoot.path, 'tool', 'utopia_design_tools', 'overlay'));
    _write(p.join(fixtureRoot.path, 'pubspec.yaml'), 'name: utopia_ui\nversion: 9.9.9\n');
    _write(p.join(fixtureRoot.path, 'lib', 'utopia_ui.dart'), "export 'src/demo.dart';\n");
    _write(p.join(fixtureRoot.path, 'lib', 'src', 'demo.dart'), _demoSource);
    _write(p.join(overlayDir.path, 'host-card.yaml'), _hostCardOverlay);
  });

  tearDown(() => fixtureRoot.deleteSync(recursive: true));

  GenerationResult generate() => generateManifest(utopiaUiRoot: fixtureRoot, overlayDir: overlayDir);

  Map<String, dynamic> generated() {
    final result = generate();
    expect(result.isOk, isTrue, reason: result.errors.join('; '));
    return result.manifest!;
  }

  List<Finding> errorsOf(Map<String, dynamic> manifest, {Directory? libraryOverlayDir}) =>
      ManifestValidator(schema, utopiaUiRoot: fixtureRoot, libraryOverlayDir: libraryOverlayDir)
          .validate(manifest)
          .where((f) => f.severity == FindingSeverity.error)
          .toList();

  Map<String, dynamic> component(Map<String, dynamic> manifest, String id) =>
      (manifest['components'] as List).cast<Map<String, dynamic>>().firstWhere((c) => c['id'] == id);

  group('overlay tokenBindingsAdd', () {
    test('generation merges the added binding into tokenBindings', () {
      expect(component(generated(), 'host-card')['tokenBindings'], ['textStyles.text', 'theme.borderRadius']);
    });

    test('the generated manifest validates cleanly (the added binding is not reported stale)', () {
      final errors = errorsOf(generated());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('with the overlay removed, the same binding is reported stale again', () {
      final manifest = generated();
      File(p.join(overlayDir.path, 'host-card.yaml')).deleteSync();

      final errors = errorsOf(manifest);
      expect(errors.map((f) => f.message), contains('stale binding "theme.borderRadius": not found in source'));
    });

    test('a binding in neither the source nor the overlay is still reported stale', () {
      final manifest = generated();
      (component(manifest, 'host-card')['tokenBindings'] as List).add('colors.primary');

      final errors = errorsOf(manifest);
      expect(errors.map((f) => f.message), contains('stale binding "colors.primary": not found in source'));
    });

    test('an added binding missing from the manifest is reported (the manifest predates the overlay entry)', () {
      final manifest = generated();
      (component(manifest, 'host-card')['tokenBindings'] as List).remove('theme.borderRadius');

      final errors = errorsOf(manifest);
      expect(
        errors.map((f) => f.message),
        contains(
          'missing binding "theme.borderRadius": declared by overlay tokenBindingsAdd but not in the '
          'manifest (stale manifest - regenerate)',
        ),
      );
    });

    test('with the overlay removed (the pub-cache case), the same manifest reports nothing missing', () {
      final manifest = generated();
      (component(manifest, 'host-card')['tokenBindings'] as List).remove('theme.borderRadius');
      File(p.join(overlayDir.path, 'host-card.yaml')).deleteSync();

      final errors = errorsOf(manifest);
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });
  });

  group('a custom overlay directory (generate_manifest --overlay-dir)', () {
    late Directory customOverlayDir;

    setUp(() {
      // The overlay moves out of generation's default location entirely, so
      // only a validator that was told about it can subtract the added binding.
      customOverlayDir = Directory(p.join(fixtureRoot.path, 'design', 'library-overlay'));
      _write(p.join(customOverlayDir.path, 'host-card.yaml'), _hostCardOverlay);
      File(p.join(overlayDir.path, 'host-card.yaml')).deleteSync();
    });

    Map<String, dynamic> generatedFromCustomDir() {
      final result = generateManifest(utopiaUiRoot: fixtureRoot, overlayDir: customOverlayDir);
      expect(result.isOk, isTrue, reason: result.errors.join('; '));
      return result.manifest!;
    }

    test('validates cleanly when the same directory is threaded into the validator', () {
      final errors = errorsOf(generatedFromCustomDir(), libraryOverlayDir: customOverlayDir);
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('reports the added binding stale when it is not (the default directory holds no overlay)', () {
      final errors = errorsOf(generatedFromCustomDir());
      expect(errors.map((f) => f.message), contains('stale binding "theme.borderRadius": not found in source'));
    });

    test('CLI: validate_manifest --overlay-dir passes, omitting it reports the stale binding', () async {
      final manifestFile = File(p.join(fixtureRoot.path, 'manifest', 'utopia.manifest.json'));
      manifestFile.parent.createSync(recursive: true);
      manifestFile.writeAsStringSync(renderManifestJson(generatedFromCustomDir()));

      Future<ProcessResult> run(List<String> extraArgs) => Process.run('dart', [
        'run',
        'bin/validate_manifest.dart',
        manifestFile.path,
        '--sources',
        fixtureRoot.path,
        '--schema',
        schemaFile.path,
        ...extraArgs,
      ], workingDirectory: Directory.current.path);

      final withFlag = await run(['--overlay-dir', p.join('design', 'library-overlay')]);
      expect(withFlag.exitCode, 0, reason: 'stdout=${withFlag.stdout} stderr=${withFlag.stderr}');

      final withoutFlag = await run(const []);
      expect(withoutFlag.exitCode, 1, reason: 'stdout=${withoutFlag.stdout} stderr=${withoutFlag.stderr}');
      expect(withoutFlag.stdout.toString(), contains('stale binding "theme.borderRadius"'));
    });
  });

  group('a component class used as a declared prop type', () {
    test('is listed once, in components, never a second time as a model', () {
      final manifest = generated();
      final componentNames = (manifest['components'] as List).cast<Map<String, dynamic>>().map((c) => c['name']);
      expect(componentNames, containsAll(['UtopiaHostCard', 'UtopiaSlotChip']));
      expect(manifest['models'], isEmpty);
    });

    test('the prop keeps type "model" with modelName naming the class', () {
      final ctor = (component(generated(), 'host-card')['constructors'] as List).cast<Map<String, dynamic>>().single;
      final chip = (ctor['props'] as List).cast<Map<String, dynamic>>().single;
      expect(chip['name'], 'chip');
      expect(chip['type'], 'model');
      expect(chip['modelName'], 'UtopiaSlotChip');
    });

    test('that modelName resolves against the components section (no dangling-reference finding)', () {
      final errors = errorsOf(generated());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });
  });

  group('extensions', () {
    test('a named extension becomes a helper; an unnamed one is skipped', () {
      final helpers = (generated()['helpers'] as List).cast<Map<String, dynamic>>();
      expect(helpers, hasLength(1));
      expect(helpers.single['name'], 'UtopiaDemoStringX');
      expect(helpers.single['kind'], 'extension');
      expect(helpers.single['signature'], 'extension UtopiaDemoStringX on String');
      expect(helpers.single['description'], 'Demo string helpers.');
    });
  });
}

/// The synthetic barrel-exported source file: two components (one taking the
/// other as a declared prop type), a named extension and an unnamed one.
const String _demoSource = '''
import 'package:flutter/widgets.dart';

/// A host card that slots a chip.
class UtopiaHostCard extends StatelessWidget {
  /// Creates a host card.
  const UtopiaHostCard({super.key, required this.chip});

  /// The chip rendered inside the card.
  final UtopiaSlotChip chip;

  @override
  Widget build(BuildContext context) => Text('host', style: context.textStyles.text);
}

/// A chip that doubles as a prop type.
class UtopiaSlotChip extends StatelessWidget {
  /// Creates a slot chip.
  const UtopiaSlotChip({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// Demo string helpers.
extension UtopiaDemoStringX on String {
  /// Whether this string is blank.
  bool get isBlank => trim().isEmpty;
}

extension on String {
  bool get isNotBlank => trim().isNotEmpty;
}
''';

/// The overlay for `host-card`, adding a binding the AST extractor cannot see
/// (the escape hatch generation merges into `tokenBindings`).
const String _hostCardOverlay = '''
states:
  - hover
tokenBindingsAdd:
  - theme.borderRadius
''';

void _write(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}
