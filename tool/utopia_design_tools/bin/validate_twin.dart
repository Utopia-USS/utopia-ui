/// `validate_twin` - runs the Utopia Design Protocol HTML twin validation
/// gates (protocol SPEC section 4.5 and `ledger/checkpoints/A5-spec.md`)
/// against a twin bundle (`twin/components.html`, `components.css`,
/// `gallery.html`, `tokens.css`).
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
import 'package:utopia_design_tools/src/dtcg/token_document.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/twin/twin_validator.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('twin-dir', help: 'Path to the twin/ directory to validate.')
    ..addOption('manifest', help: 'Path to utopia.manifest.json (overrides auto-discovery).')
    ..addOption('tokens', help: 'Path to the token document backing the tokens.css freshness gate (overrides auto-discovery).')
    ..addFlag('json', help: 'Emit machine-readable JSON output instead of text.', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('validate_twin: ${e.message}');
    stderr.writeln(parser.usage);
    exitCode = 2;
    return;
  }

  if (args['help'] as bool) {
    stdout.writeln('Usage: dart run utopia_design_tools:validate_twin [--twin-dir <dir>] [--manifest <path>] [--tokens <path>] [--json]');
    stdout.writeln(parser.usage);
    exitCode = 0;
    return;
  }

  final asJson = args['json'] as bool;
  final twinDirOption = args['twin-dir'] as String?;
  final manifestOption = args['manifest'] as String?;
  final tokensOption = args['tokens'] as String?;

  final twinDir = twinDirOption != null ? Directory(twinDirOption) : _resolveDefaultTwinDir();
  if (twinDir == null) {
    exitCode = 2;
    stderr.writeln(
      'validate_twin: could not resolve a twin/ directory. Pass --twin-dir <dir>, or run from inside a '
      'utopia_ui checkout / a project that resolves the utopia_ui package.',
    );
    return;
  }
  if (!twinDir.existsSync()) {
    exitCode = 2;
    stderr.writeln('validate_twin: directory not found: ${twinDir.path}');
    return;
  }

  final manifestFile = manifestOption != null ? File(manifestOption) : _resolveDefaultManifestFile();
  if (manifestFile == null || !manifestFile.existsSync()) {
    exitCode = 2;
    stderr.writeln(
      'validate_twin: could not resolve manifest/utopia.manifest.json. Pass --manifest <path>, or run from '
      'inside a utopia_ui checkout / a project that resolves the utopia_ui package.',
    );
    return;
  }

  final tokensFile = tokensOption != null ? File(tokensOption) : _resolveDefaultTokensFile();
  if (tokensFile == null || !tokensFile.existsSync()) {
    exitCode = 2;
    stderr.writeln(
      'validate_twin: could not resolve a token document for the tokens.css freshness gate. Pass --tokens '
      '<path>, or run from inside a utopia_ui checkout / a project with design/tokens.json or '
      'tokens/utopia.tokens.json.',
    );
    return;
  }

  final Map<String, dynamic> manifestJson;
  try {
    manifestJson = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    exitCode = 2;
    stderr.writeln('validate_twin: ${manifestFile.path} is not valid JSON: ${e.message}');
    return;
  }
  final componentsRaw = manifestJson['components'];
  if (componentsRaw is! List) {
    exitCode = 2;
    stderr.writeln('validate_twin: ${manifestFile.path} has no "components" array.');
    return;
  }
  final manifestComponentIds = componentsRaw
      .whereType<Map<String, dynamic>>()
      .map((c) => c['id'])
      .whereType<String>()
      .toSet();

  final Map<String, dynamic> tokensJson;
  try {
    tokensJson = jsonDecode(tokensFile.readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    exitCode = 2;
    stderr.writeln('validate_twin: ${tokensFile.path} is not valid JSON: ${e.message}');
    return;
  }
  final tokenDocument = TokenDocument.parse(tokensJson);
  final profileVersion = (tokenDocument.rootExtensions?['profileVersion'] as String?) ?? protocolVersion;

  final validator = TwinValidator(
    twinDir: twinDir,
    manifestComponentIds: manifestComponentIds,
    tokenDocument: tokenDocument,
    tokensInputPath: RepoLocator.normalizeInputPath(tokensFile.path),
    profileVersion: profileVersion,
  );
  final findings = validator.validate();
  final report = FindingReport(findings);

  if (asJson) {
    stdout.writeln(report.toJson());
  } else {
    stdout.writeln(report.toText());
  }
  exitCode = report.exitCode;
}

/// Resolves the default `--twin-dir`: `<utopia_ui root>/twin` when run inside
/// this repo checkout or a consumer project that resolves the `utopia_ui`
/// package, else `null`.
Directory? _resolveDefaultTwinDir() {
  final repoRoot = RepoLocator.findUtopiaUiRepoRoot();
  if (repoRoot != null) {
    return Directory(p.join(repoRoot.path, 'twin'));
  }
  final packageRoot = RepoLocator.resolveUtopiaUiPackageRoot();
  if (packageRoot != null) {
    return Directory(p.join(packageRoot.path, 'twin'));
  }
  return null;
}

/// Resolves the default manifest file, mirroring `validate_manifest`'s
/// resolution order.
File? _resolveDefaultManifestFile() {
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

/// Resolves the default token document, mirroring `validate_tokens`/
/// `generate_twin`'s resolution order: `design/tokens.json` under the current
/// working directory if present, else `tokens/utopia.tokens.json` under the
/// resolved `utopia_ui` root.
File? _resolveDefaultTokensFile() {
  final designTokens = File(p.join('design', 'tokens.json'));
  if (designTokens.existsSync()) {
    return designTokens;
  }
  final repoRoot = RepoLocator.findUtopiaUiRepoRoot();
  if (repoRoot != null) {
    final candidate = File(p.join(repoRoot.path, 'tokens', 'utopia.tokens.json'));
    if (candidate.existsSync()) return candidate;
  }
  final packageRoot = RepoLocator.resolveUtopiaUiPackageRoot();
  if (packageRoot != null) {
    final candidate = File(p.join(packageRoot.path, 'tokens', 'utopia.tokens.json'));
    if (candidate.existsSync()) return candidate;
  }
  final canonicalTokens = File(p.join('tokens', 'utopia.tokens.json'));
  if (canonicalTokens.existsSync()) {
    return canonicalTokens;
  }
  return null;
}
