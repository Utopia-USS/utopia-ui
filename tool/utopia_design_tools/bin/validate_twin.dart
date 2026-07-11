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

  final resolvedTokens = tokensOption != null
      ? (file: File(tokensOption), headerInputPath: null as String?)
      : _resolveTokensFileForTwin(twinDir);
  final tokensFile = resolvedTokens.file;
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

  if (!File(p.join(twinDir.path, 'components.html')).existsSync()) {
    stderr.writeln(
      'validate_twin: info: components.html absent - id-coverage gate skipped (generated-only twin, RFC-B5); '
      'literals linter and tokens.css freshness still enforced.',
    );
  }

  final validator = TwinValidator(
    twinDir: twinDir,
    manifestComponentIds: manifestComponentIds,
    tokenDocument: tokenDocument,
    // When the target twin's own tokens.css header named the resolved file,
    // reuse that exact recorded string - it is what the freshness
    // byte-compare must reproduce, and re-deriving it via
    // normalizeInputPath (which only special-cases paths under the
    // utopia_ui root) would rewrite it to an absolute path instead for any
    // twin whose owning root is a consumer project.
    tokensInputPath: resolvedTokens.headerInputPath ?? RepoLocator.normalizeInputPath(tokensFile.path),
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

/// Resolves the token document backing the `tokens.css` freshness gate
/// (gate 3) for [twinDir], the twin actually being validated: binds the
/// freshness check to that twin instead of "whichever token document
/// auto-discovery happens to find from the current working directory",
/// which can silently name a *different* twin's source (e.g. bare
/// `validate_twin` in a consumer app resolving `twin/` to the installed
/// `utopia_ui` package's own default twin, while `design/tokens.json`
/// auto-discovery finds the app's rebranded tokens - a false "stale" every
/// time, since the two never describe the same twin).
///
/// Reads `twinDir/tokens.css`'s generated-header first line (`/* GENERATED
/// by utopia_design_tools:generate_twin from <path> - do not edit. */`,
/// written by `generate_twin`) and resolves `<path>` against the twin dir's
/// owning root - `twinDir.parent`, which is the utopia_ui root in the
/// package layout and the consumer project root in the project layout,
/// mirroring how `generate_twin` derives `_defaultTwinDir` from that same
/// root. The header's own path string is returned as `headerInputPath`
/// alongside the resolved file, so the caller can feed the freshness gate's
/// regenerate-and-byte-compare the exact string the on-disk header carries,
/// rather than re-deriving one (`RepoLocator.normalizeInputPath` only
/// special-cases paths under the utopia_ui root, and would otherwise
/// rewrite a consumer-project path to an absolute one and always disagree).
/// Falls back to [_resolveDefaultTokensFile] (with a `null` header path,
/// signalling the caller to derive one itself) when `tokens.css` or its
/// header is absent, or the header's path does not resolve to a real file.
({File? file, String? headerInputPath}) _resolveTokensFileForTwin(Directory twinDir) {
  final tokensCssFile = File(p.join(twinDir.path, 'tokens.css'));
  if (tokensCssFile.existsSync()) {
    final firstLine = tokensCssFile.readAsLinesSync().firstOrNull;
    final match = firstLine == null ? null : _generatedHeaderPath.firstMatch(firstLine);
    if (match != null) {
      final headerPath = match.group(1)!;
      final candidate = File(p.join(twinDir.parent.path, headerPath));
      if (candidate.existsSync()) return (file: candidate, headerInputPath: headerPath);
    }
  }
  return (file: _resolveDefaultTokensFile(), headerInputPath: null);
}

/// Matches `generate_twin`'s `tokens.css` header line, capturing the
/// recorded input path: `/* GENERATED by utopia_design_tools:generate_twin
/// from <path> - do not edit. */`.
final RegExp _generatedHeaderPath = RegExp(
  r'^/\* GENERATED by utopia_design_tools:generate_twin from (.+) - do not edit\. \*/$',
);

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
