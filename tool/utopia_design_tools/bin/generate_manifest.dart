/// `generate_manifest` - runs the Utopia Design Protocol manifest generator
/// (protocol SPEC section 3) over a `utopia_ui` checkout: parses the barrel
/// and every file it exports, classifies components/models/helpers, extracts
/// `tokenBindings`, merges per-component overlay YAML, self-validates the
/// result against `protocol/schemas/manifest.schema.json`, and writes
/// `manifest/utopia.manifest.json`.
///
/// Maintainer-style, like `export_tokens`: requires the `utopia_ui` sources
/// (parser-based extraction, no analysis context, no Flutter import in this
/// bin). Pure Dart: `dart run` works standalone.
///
/// `--project` mode (SPEC 3.8) instead runs from a CONSUMER project: extracts
/// its opt-in custom components (an overlay YAML registers each one) and
/// writes both `design/project.manifest.json` and `design/merged.manifest.json`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/manifest/generator.dart';
import 'package:utopia_design_tools/src/manifest/project_generator.dart';
import 'package:utopia_design_tools/src/manifest/validator.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output path, relative to the utopia_ui repo root.')
    ..addOption('overlay-dir', help: 'Overlay directory, relative to the utopia_ui repo root (or project root in --project mode).')
    ..addFlag('project', help: "Run in project mode (SPEC 3.8): extract a consumer project's custom components.", negatable: false)
    ..addOption('project-dir', help: '--project mode only: the consumer project root (default: walk up from the current directory).')
    ..addFlag('timestamp', help: 'Stamp generatedAt with the current UTC time.', negatable: false)
    ..addFlag('json', help: 'Emit machine-readable JSON output instead of text.', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('generate_manifest: ${e.message}');
    stderr.writeln(parser.usage);
    exitCode = 2;
    return;
  }

  if (args['help'] as bool) {
    stdout.writeln(
      'Usage: dart run utopia_design_tools:generate_manifest [-o <path>] '
      '[--overlay-dir <dir>] [--timestamp] [--json]\n'
      '       dart run utopia_design_tools:generate_manifest --project [--project-dir <dir>] '
      '[--overlay-dir <dir>] [--timestamp] [--json]',
    );
    stdout.writeln(parser.usage);
    exitCode = 0;
    return;
  }

  final asJson = args['json'] as bool;

  if (args['project'] as bool) {
    await _runProjectMode(args, asJson: asJson);
    return;
  }

  final repoRoot = RepoLocator.findUtopiaUiRepoRoot();
  if (repoRoot == null) {
    exitCode = 2;
    stderr.writeln(
      'generate_manifest: this is a maintainer-only tool - run it from inside a checkout of the '
      'utopia_ui repository (no pubspec.yaml with name: utopia_ui was found above the current '
      'directory).',
    );
    return;
  }

  final overlayDirOption = args['overlay-dir'] as String?;
  final overlayDir = Directory(
    overlayDirOption != null
        ? (p.isAbsolute(overlayDirOption) ? overlayDirOption : p.join(repoRoot.path, overlayDirOption))
        : p.join(repoRoot.path, 'tool', 'utopia_design_tools', 'overlay'),
  );

  final result = generateManifest(
    utopiaUiRoot: repoRoot,
    overlayDir: overlayDir,
    withTimestamp: args['timestamp'] as bool,
  );

  if (!result.isOk) {
    exitCode = 1;
    if (asJson) {
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'status': 'fail',
          'errors': result.errors.map((e) => {'message': e}).toList(),
        }),
      );
    } else {
      for (final error in result.errors) {
        stdout.writeln('ERROR generate_manifest: $error');
      }
      stdout.writeln('${result.errors.length} error(s), 0 warning(s)');
    }
    return;
  }

  final manifest = result.manifest!;

  // Self-validate before writing: the manifest this generator produces must
  // pass the same gates `validate_manifest` re-checks, so bindings/schema
  // drift is caught at generation time rather than the next validate run.
  final schemaFile = File(p.join(repoRoot.path, 'protocol', 'schemas', 'manifest.schema.json'));
  if (!schemaFile.existsSync()) {
    exitCode = 2;
    stderr.writeln('generate_manifest: could not resolve protocol/schemas/manifest.schema.json under ${repoRoot.path}.');
    return;
  }
  final schema = loadSchema(schemaFile.readAsStringSync());
  // The overlay directory generation just merged `tokenBindingsAdd` from is
  // passed through: the bindings gate subtracts those entries, so a custom
  // --overlay-dir would otherwise make self-validation report every added
  // binding as stale and refuse to write.
  final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot, libraryOverlayDir: overlayDir);
  final selfCheckFindings = validator.validate(manifest);
  final selfCheckReport = FindingReport(selfCheckFindings);
  if (selfCheckReport.hasErrors) {
    exitCode = 1;
    if (asJson) {
      stdout.writeln(selfCheckReport.toJson());
    } else {
      stderr.writeln('generate_manifest: self-validation of the generated manifest failed; not writing output.');
      stdout.writeln(selfCheckReport.toText());
    }
    return;
  }

  final outputOption = args['output'] as String?;
  final outputPath = outputOption ?? p.join('manifest', 'utopia.manifest.json');
  final outputFile = File(p.isAbsolute(outputPath) ? outputPath : p.join(repoRoot.path, outputPath));
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(renderManifestJson(manifest));

  final componentCount = (manifest['components'] as List).length;
  final modelCount = (manifest['models'] as List? ?? const []).length;
  final helperCount = (manifest['helpers'] as List? ?? const []).length;

  if (asJson) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'status': 'ok',
        'path': outputFile.path,
        'components': componentCount,
        'models': modelCount,
        'helpers': helperCount,
      }),
    );
  } else {
    stdout.writeln(
      'wrote ${outputFile.path} ($componentCount components, $modelCount models, $helperCount helpers)',
    );
  }
  exitCode = 0;
}

/// `--project` mode (SPEC 3.8): extracts a consumer project's opt-in custom
/// components and writes both `design/project.manifest.json` and
/// `design/merged.manifest.json`.
Future<void> _runProjectMode(ArgResults args, {required bool asJson}) async {
  final projectDirOption = args['project-dir'] as String?;
  final projectRoot = projectDirOption != null
      ? Directory(projectDirOption)
      : RepoLocator.findConsumerProjectRoot();
  if (projectRoot == null) {
    exitCode = 2;
    stderr.writeln(
      'generate_manifest --project: no consumer project found - run from inside a project with a '
      'pubspec.yaml (not utopia_ui itself), or pass --project-dir <dir>.',
    );
    return;
  }
  if (!File(p.join(projectRoot.path, 'pubspec.yaml')).existsSync()) {
    exitCode = 2;
    stderr.writeln('generate_manifest --project: no pubspec.yaml found at ${projectRoot.path}.');
    return;
  }

  final utopiaUiRoot = RepoLocator.resolveUtopiaUiPackageRoot(start: projectRoot) ?? RepoLocator.findUtopiaUiRepoRoot();
  if (utopiaUiRoot == null) {
    exitCode = 2;
    stderr.writeln(
      'generate_manifest --project: could not resolve the utopia_ui package from ${projectRoot.path} '
      '(expected .dart_tool/package_config.json to resolve a "utopia_ui" entry - run "flutter pub get" '
      'or "dart pub get" in the project first).',
    );
    return;
  }

  final overlayDirOption = args['overlay-dir'] as String?;
  final overlayDir = Directory(
    overlayDirOption != null
        ? (p.isAbsolute(overlayDirOption) ? overlayDirOption : p.join(projectRoot.path, overlayDirOption))
        : p.join(projectRoot.path, 'design', 'overlay'),
  );

  // No overlays at all is a configuration/usage state, not a generation
  // failure: exit 2 with the opt-in explanation (A11 spec; the in-library
  // check stays as an API-level backstop).
  final hasOverlays =
      overlayDir.existsSync() && overlayDir.listSync().whereType<File>().any((f) => f.path.endsWith('.yaml'));
  if (!hasOverlays) {
    exitCode = 2;
    stderr.writeln(
      'generate_manifest --project: no overlay files found under ${overlayDir.path}. Registration is '
      'OPT-IN: a component joins the project manifest exactly when it has an overlay YAML. Create '
      'design/overlay/<local-part>.yaml (e.g. states: [hover], notes: "...") for each custom component '
      'to register (SPEC 3.8).',
    );
    return;
  }

  final result = generateProjectManifest(
    projectRoot: projectRoot,
    overlayDir: overlayDir,
    utopiaUiRoot: utopiaUiRoot,
    withTimestamp: args['timestamp'] as bool,
  );

  if (!result.isOk) {
    exitCode = 1;
    if (asJson) {
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'status': 'fail',
          'errors': result.errors.map((e) => {'message': e}).toList(),
        }),
      );
    } else {
      for (final error in result.errors) {
        stdout.writeln('ERROR generate_manifest --project: $error');
      }
      stdout.writeln('${result.errors.length} error(s), 0 warning(s)');
    }
    return;
  }

  for (final warning in result.warnings) {
    stderr.writeln('WARN generate_manifest --project: $warning');
  }

  final projectManifest = result.projectManifest!;
  final mergedManifest = result.mergedManifest!;

  // Self-validate both outputs before writing anything (same pattern as
  // library mode): schema/namespace/freshness drift is caught here, not on
  // the next validate_manifest run.
  final schemaFile = File(p.join(utopiaUiRoot.path, 'protocol', 'schemas', 'manifest.schema.json'));
  if (!schemaFile.existsSync()) {
    exitCode = 2;
    stderr.writeln('generate_manifest --project: could not resolve protocol/schemas/manifest.schema.json under ${utopiaUiRoot.path}.');
    return;
  }
  final schema = loadSchema(schemaFile.readAsStringSync());
  final validator = ManifestValidator(
    schema,
    utopiaUiRoot: utopiaUiRoot,
    projectRoot: projectRoot,
    projectOverlayDir: overlayDir,
  );
  final selfCheckFindings = [
    ...validator.validate(projectManifest),
    ...validator.validate(mergedManifest),
  ];
  final selfCheckReport = FindingReport(selfCheckFindings);
  if (selfCheckReport.hasErrors) {
    exitCode = 1;
    if (asJson) {
      stdout.writeln(selfCheckReport.toJson());
    } else {
      stderr.writeln('generate_manifest --project: self-validation of the generated manifests failed; not writing output.');
      stdout.writeln(selfCheckReport.toText());
    }
    return;
  }

  final projectManifestFile = File(p.join(projectRoot.path, 'design', 'project.manifest.json'));
  final mergedManifestFile = File(p.join(projectRoot.path, 'design', 'merged.manifest.json'));
  projectManifestFile.parent.createSync(recursive: true);
  projectManifestFile.writeAsStringSync(renderManifestJson(projectManifest));
  mergedManifestFile.writeAsStringSync(renderManifestJson(mergedManifest));

  final componentCount = (projectManifest['components'] as List).length;
  final modelCount = (projectManifest['models'] as List? ?? const []).length;
  final helperCount = (projectManifest['helpers'] as List? ?? const []).length;

  if (asJson) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'status': 'ok',
        'projectManifestPath': projectManifestFile.path,
        'mergedManifestPath': mergedManifestFile.path,
        'components': componentCount,
        'models': modelCount,
        'helpers': helperCount,
      }),
    );
  } else {
    stdout.writeln(projectManifestFile.path);
    stdout.writeln(mergedManifestFile.path);
    stdout.writeln('($componentCount project components, $modelCount project models, $helperCount project helpers)');
  }
  exitCode = 0;
}
