/// `validate_manifest` - runs the Utopia Design Protocol manifest validation
/// gates (protocol SPEC section 3.7) against a component manifest document.
///
/// Pure Dart: does not import Flutter, so `dart run` works standalone, both
/// inside this repo checkout and in a consumer project that has installed
/// `utopia_design_tools` as a dev dependency.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/manifest/validator.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('json', help: 'Emit machine-readable JSON output instead of text.', negatable: false)
    ..addOption('sources', help: 'Path to a utopia_ui checkout to validate bindings/version against.')
    ..addOption('schema', help: 'Path to manifest.schema.json (overrides auto-discovery).')
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('validate_manifest: ${e.message}');
    stderr.writeln(parser.usage);
    exitCode = 2;
    return;
  }

  if (args['help'] as bool) {
    stdout.writeln('Usage: dart run utopia_design_tools:validate_manifest [<file>] [--json] [--sources <dir>]');
    stdout.writeln(parser.usage);
    exitCode = 0;
    return;
  }

  final asJson = args['json'] as bool;
  final sourcesOption = args['sources'] as String?;
  final schemaOverride = args['schema'] as String?;
  final positional = args.rest;

  final targetFile = _resolveTargetFile(positional);
  if (targetFile == null) {
    exitCode = 2;
    stderr.writeln(
      'validate_manifest: no manifest file found. Pass a path, or run from inside a utopia_ui '
      'checkout / a project that resolves the utopia_ui package (expects manifest/utopia.manifest.json).',
    );
    return;
  }

  if (!targetFile.existsSync()) {
    exitCode = 2;
    stderr.writeln('validate_manifest: file not found: ${targetFile.path}');
    return;
  }

  final schemaFile = schemaOverride != null
      ? File(schemaOverride)
      : _findManifestSchema(sourcesOption != null ? Directory(sourcesOption) : null);
  if (schemaFile == null || !schemaFile.existsSync()) {
    exitCode = 2;
    stderr.writeln(
      'validate_manifest: could not resolve protocol/schemas/manifest.schema.json. '
      'Pass --schema <path> to override, or run from inside a utopia_ui checkout / a project '
      'that resolves the utopia_ui package.',
    );
    return;
  }

  final Map<String, dynamic> rawJson;
  try {
    rawJson = jsonDecode(targetFile.readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    exitCode = 2;
    stderr.writeln('validate_manifest: ${targetFile.path} is not valid JSON: ${e.message}');
    return;
  }

  final JsonSchema schema;
  try {
    schema = loadSchema(schemaFile.readAsStringSync());
  } catch (e) {
    exitCode = 2;
    stderr.writeln('validate_manifest: ${schemaFile.path} is not a valid JSON Schema: $e');
    return;
  }

  final sourcesRoot = sourcesOption != null ? Directory(sourcesOption) : _resolveDefaultSourcesRoot(targetFile);
  final validator = ManifestValidator(schema, utopiaUiRoot: sourcesRoot);
  final findings = validator.validate(rawJson);
  final report = FindingReport(findings);

  if (asJson) {
    stdout.writeln(report.toJson());
  } else {
    stdout.writeln(report.toText());
  }
  exitCode = report.exitCode;
}

/// Resolves the file to validate: the first positional argument if given,
/// else `manifest/utopia.manifest.json` under the resolved utopia_ui root
/// (repo checkout or pub cache package root), else `null`.
File? _resolveTargetFile(List<String> positional) {
  if (positional.isNotEmpty) {
    return File(positional.first);
  }
  final repoRoot = RepoLocator.findUtopiaUiRepoRoot();
  if (repoRoot != null) {
    final candidate = File(p.join(repoRoot.path, 'manifest', 'utopia.manifest.json'));
    if (candidate.existsSync()) return candidate;
  }
  final packageRoot = RepoLocator.resolveUtopiaUiPackageRoot();
  if (packageRoot != null) {
    final candidate = File(p.join(packageRoot.path, 'manifest', 'utopia.manifest.json'));
    if (candidate.existsSync()) return candidate;
  }
  return null;
}

/// Resolves `protocol/schemas/manifest.schema.json`, preferring [sourcesRoot]
/// when given, then falling back to the same repo/pub-cache walk-up
/// `RepoLocator` uses for the token schema.
File? _findManifestSchema(Directory? sourcesRoot) {
  if (sourcesRoot != null) {
    final direct = File(p.join(sourcesRoot.path, 'protocol', 'schemas', 'manifest.schema.json'));
    if (direct.existsSync()) return direct;
  }
  final repoRoot = RepoLocator.findUtopiaUiRepoRoot();
  if (repoRoot != null) {
    final candidate = File(p.join(repoRoot.path, 'protocol', 'schemas', 'manifest.schema.json'));
    if (candidate.existsSync()) return candidate;
  }
  final packageRoot = RepoLocator.resolveUtopiaUiPackageRoot();
  if (packageRoot != null) {
    final candidate = File(p.join(packageRoot.path, 'protocol', 'schemas', 'manifest.schema.json'));
    if (candidate.existsSync()) return candidate;
  }
  return null;
}

/// Resolves the default `--sources` root when not explicitly passed: the
/// utopia_ui repo/package root containing [targetFile], if any.
Directory? _resolveDefaultSourcesRoot(File targetFile) {
  final start = targetFile.absolute.parent;
  return RepoLocator.findUtopiaUiRepoRoot(start: start) ?? RepoLocator.resolveUtopiaUiPackageRoot(start: start);
}
