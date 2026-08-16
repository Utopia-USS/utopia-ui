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

// Generation + validation over a synthetic, utopia_ui-shaped source tree
// (pubspec + barrel + one src file + one overlay + a two-section twin, written
// to a temp dir): the cases the real repo's own sources do not currently
// contain - an overlay `tokenBindingsAdd` escape hatch (and therefore the only
// `origin: "overlay"` bindings on the library path), a component class used as
// another component's prop type, a component without a twin section, and an
// unnamed extension.
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
    _write(p.join(fixtureRoot.path, 'twin', 'components.html'), _twinComponentsHtml);
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

  List<Map<String, dynamic>> bindings(Map<String, dynamic> manifest, String id) =>
      (component(manifest, id)['tokenBindings'] as List).cast<Map<String, dynamic>>();

  /// Rewrites [manifest] into the protocol 0.2 form a pre-origin generator
  /// wrote: `tokenBindings` as bare strings, `schemaVersion` back to "0.2.0".
  /// Used to prove the old (overlay-directory) validation path still works for
  /// documents written for the older minor.
  Map<String, dynamic> asLegacyDocument(Map<String, dynamic> manifest) {
    final copy = jsonDecode(jsonEncode(manifest)) as Map<String, dynamic>;
    copy['schemaVersion'] = '0.2.0';
    for (final component in (copy['components'] as List).cast<Map<String, dynamic>>()) {
      component['tokenBindings'] = (component['tokenBindings'] as List)
          .cast<Map<String, dynamic>>()
          .map((b) => b['path'])
          .toList();
    }
    return copy;
  }

  group('overlay tokenBindingsAdd', () {
    test('generation merges the added binding into tokenBindings, stamping each entry with its origin', () {
      expect(bindings(generated(), 'host-card'), [
        {'path': 'textStyles.text', 'origin': 'source'},
        {'path': 'theme.borderRadius', 'origin': 'overlay'},
      ]);
    });

    test('the generated manifest validates cleanly (the added binding is not reported stale)', () {
      final errors = errorsOf(generated());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('with the overlay removed (the pub-cache case), the origin marker alone keeps the binding legitimate', () {
      final manifest = generated();
      File(p.join(overlayDir.path, 'host-card.yaml')).deleteSync();

      final errors = errorsOf(manifest);
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('a 0.2 document (bare strings, no origin) still needs the overlay: removing it reports the binding stale', () {
      final manifest = asLegacyDocument(generated());
      File(p.join(overlayDir.path, 'host-card.yaml')).deleteSync();

      final errors = errorsOf(manifest);
      expect(errors.map((f) => f.message), contains('stale binding "theme.borderRadius": not found in source'));
    });

    test('a 0.2 document validates cleanly while the overlay directory is there (backward compatibility)', () {
      final errors = errorsOf(asLegacyDocument(generated()));
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('a binding in neither the source nor the overlay is still reported stale', () {
      final manifest = generated();
      (component(manifest, 'host-card')['tokenBindings'] as List).add({
        'path': 'colors.primary',
        'origin': 'source',
      });

      final errors = errorsOf(manifest);
      expect(errors.map((f) => f.message), contains('stale binding "colors.primary": not found in source'));
    });

    test('a source binding mislabelled origin "overlay" is reported (stale origin marker)', () {
      final manifest = generated();
      bindings(manifest, 'host-card').firstWhere((b) => b['path'] == 'textStyles.text')['origin'] = 'overlay';

      final errors = errorsOf(manifest);
      expect(
        errors.map((f) => f.message),
        contains(
          'binding "textStyles.text" is marked origin "overlay" but the extractor finds it in source '
          '(stale origin marker - regenerate)',
        ),
      );
    });

    test('an added binding missing from the manifest is reported (the manifest predates the overlay entry)', () {
      final manifest = generated();
      bindings(manifest, 'host-card').removeWhere((b) => b['path'] == 'theme.borderRadius');

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
      bindings(manifest, 'host-card').removeWhere((b) => b['path'] == 'theme.borderRadius');
      File(p.join(overlayDir.path, 'host-card.yaml')).deleteSync();

      final errors = errorsOf(manifest);
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });
  });

  group('twin binding (SPEC 3.4 / 4.4)', () {
    test('is emitted exactly for the ids the twin renders', () {
      final manifest = generated();
      expect(component(manifest, 'host-card')['twin'], {
        'file': 'components.html',
        'selector': '[data-utopia-id="host-card"]',
      });
      // The twin has no section for slot-chip, so the field is absent rather
      // than invented.
      expect(component(manifest, 'slot-chip').containsKey('twin'), isFalse);
    });

    test('the generated twin binding passes the validator gate', () {
      final errors = errorsOf(generated());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('a twin binding for an id the twin file does not render is reported', () {
      final manifest = generated();
      component(manifest, 'slot-chip')['twin'] = {
        'file': 'components.html',
        'selector': '[data-utopia-id="slot-chip"]',
      };

      final errors = errorsOf(manifest);
      expect(
        errors.map((f) => f.message),
        contains('twin file "components.html" does not contain the selector\'s data-utopia-id ("slot-chip")'),
      );
    });

    test('a selector pointing at another component is reported', () {
      final manifest = generated();
      (component(manifest, 'host-card')['twin'] as Map<String, dynamic>)['selector'] =
          '[data-utopia-id="slot-chip"]';

      final errors = errorsOf(manifest);
      expect(
        errors.map((f) => f.message),
        contains('twin selector "[data-utopia-id="slot-chip"]" targets a different component than "host-card"'),
      );
    });

    test('with no twin bundle at all, generation emits no twin fields and still validates', () {
      Directory(p.join(fixtureRoot.path, 'twin')).deleteSync(recursive: true);
      final manifest = generated();

      expect(
        (manifest['components'] as List).cast<Map<String, dynamic>>().where((c) => c.containsKey('twin')),
        isEmpty,
      );
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

    test('validates cleanly without the flag too: the origin marker replaces the directory lookup', () {
      final errors = errorsOf(generatedFromCustomDir());
      expect(errors, isEmpty, reason: errors.map((f) => f.toLine()).join('; '));
    });

    test('a 0.2 document still needs the flag: without it the added binding reports stale', () {
      final errors = errorsOf(asLegacyDocument(generatedFromCustomDir()));
      expect(errors.map((f) => f.message), contains('stale binding "theme.borderRadius": not found in source'));
    });

    // Three `dart run` subprocesses; the default 30s budget is tight under a
    // full-suite run.
    test(timeout: const Timeout(Duration(minutes: 2)),
        'CLI: validate_manifest passes with or without --overlay-dir; a 0.2 document needs it', () async {
      final manifestFile = File(p.join(fixtureRoot.path, 'manifest', 'utopia.manifest.json'));
      manifestFile.parent.createSync(recursive: true);
      manifestFile.writeAsStringSync(renderManifestJson(generatedFromCustomDir()));
      final legacyManifestFile = File(p.join(fixtureRoot.path, 'manifest', 'legacy.manifest.json'))
        ..writeAsStringSync(renderManifestJson(asLegacyDocument(generatedFromCustomDir())));

      Future<ProcessResult> run(File target, List<String> extraArgs) => Process.run('dart', [
        'run',
        'bin/validate_manifest.dart',
        target.path,
        '--sources',
        fixtureRoot.path,
        '--schema',
        schemaFile.path,
        ...extraArgs,
      ], workingDirectory: Directory.current.path);

      final withFlag = await run(manifestFile, ['--overlay-dir', p.join('design', 'library-overlay')]);
      expect(withFlag.exitCode, 0, reason: 'stdout=${withFlag.stdout} stderr=${withFlag.stderr}');

      final withoutFlag = await run(manifestFile, const []);
      expect(withoutFlag.exitCode, 0, reason: 'stdout=${withoutFlag.stdout} stderr=${withoutFlag.stderr}');

      final legacyWithoutFlag = await run(legacyManifestFile, const []);
      expect(legacyWithoutFlag.exitCode, 1, reason: 'stdout=${legacyWithoutFlag.stdout}');
      expect(legacyWithoutFlag.stdout.toString(), contains('stale binding "theme.borderRadius"'));
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

/// The synthetic twin bundle's `components.html`: a section for `host-card`
/// only. The header comment names `slot-chip` in prose, so the scan proves it
/// strips HTML comments before reading `data-utopia-id` roots (SPEC 4.4) -
/// otherwise slot-chip would be handed a twin binding it does not have.
const String _twinComponentsHtml = '''
<!doctype html>
<!--
  Twin sections. Every component root carries data-utopia-id="<manifest id>".
  No section exists yet for data-utopia-id="slot-chip".
-->
<section data-utopia-id="host-card">
  <div class="host-card">host</div>
</section>
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
