/// `validate_tokens` - runs the Utopia Design Protocol token-document
/// validation gates (protocol SPEC section 2.7) against a token document.
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
import 'package:utopia_design_tools/src/dtcg/token_fixer.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('json', help: 'Emit machine-readable JSON output instead of text.', negatable: false)
    ..addFlag('fix', help: 'Rewrite derivation-carrying values and color hex to a coherent state.', negatable: false)
    ..addOption('schema', help: 'Path to tokens.schema.json (overrides auto-discovery).')
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('validate_tokens: ${e.message}');
    stderr.writeln(parser.usage);
    exitCode = 2;
    return;
  }

  if (args['help'] as bool) {
    stdout.writeln('Usage: dart run utopia_design_tools:validate_tokens [<file>] [--json] [--fix] [--schema <path>]');
    stdout.writeln(parser.usage);
    exitCode = 0;
    return;
  }

  final asJson = args['json'] as bool;
  final doFix = args['fix'] as bool;
  final schemaOverride = args['schema'] as String?;
  final positional = args.rest;

  final targetFile = _resolveTargetFile(positional);
  if (targetFile == null) {
    exitCode = 2;
    stderr.writeln(_bootstrapMessage());
    return;
  }

  if (!targetFile.existsSync()) {
    exitCode = 2;
    stderr.writeln('validate_tokens: file not found: ${targetFile.path}');
    return;
  }

  final schemaFile = schemaOverride != null ? File(schemaOverride) : RepoLocator.findTokensSchema();
  if (schemaFile == null || !schemaFile.existsSync()) {
    exitCode = 2;
    stderr.writeln(
      'validate_tokens: could not resolve protocol/schemas/tokens.schema.json. '
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
    stderr.writeln('validate_tokens: ${targetFile.path} is not valid JSON: ${e.message}');
    return;
  }

  final JsonSchema schema;
  try {
    schema = loadSchema(schemaFile.readAsStringSync());
    // json_schema throws ArgumentError (an Error) on non-JSON input and
    // FormatException on structural problems - convert both to exit 2.
  } catch (e) {
    exitCode = 2;
    stderr.writeln('validate_tokens: ${schemaFile.path} is not a valid JSON Schema: $e');
    return;
  }
  final validator = TokenValidator(schema);

  if (doFix) {
    _runFix(targetFile: targetFile, rawJson: rawJson, validator: validator, asJson: asJson);
    return;
  }

  final findings = validator.validate(rawJson);
  final report = FindingReport(findings);
  if (asJson) {
    stdout.writeln(report.toJson());
  } else {
    stdout.writeln(report.toText());
  }
  exitCode = report.exitCode;
}

/// Runs the `--fix` path: applies the two mechanical repair classes
/// (protocol SPEC 2.5, 2.7 gate 4) to [rawJson], writes the result back to
/// [targetFile] only when at least one repair was made, then re-validates
/// and reports the outcome.
///
/// Exit codes: 0 when the post-fix document is clean (including the no-op
/// case where nothing needed fixing), 1 when errors remain that `--fix`
/// cannot repair.
void _runFix({
  required File targetFile,
  required Map<String, dynamic> rawJson,
  required TokenValidator validator,
  required bool asJson,
}) {
  final fixes = TokenFixer.fix(rawJson);

  if (fixes.isEmpty) {
    if (asJson) {
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert({'status': 'ok', 'fixed': <dynamic>[], 'message': 'nothing to fix'}),
      );
    } else {
      stdout.writeln('nothing to fix');
    }
    exitCode = 0;
    return;
  }

  final jsonText = '${const JsonEncoder.withIndent('  ').convert(rawJson)}\n';
  try {
    targetFile.writeAsStringSync(jsonText);
  } on FileSystemException catch (e) {
    exitCode = 2;
    stderr.writeln('validate_tokens: failed to write ${targetFile.path}: ${e.message}');
    return;
  }

  final findings = validator.validate(rawJson);
  final report = FindingReport(findings);

  if (asJson) {
    final map = {
      'status': report.hasErrors ? 'fail' : 'ok',
      'fixed': fixes.map((f) => f.toJsonEntry()).toList(),
      'errors': report.errors.map((f) => f.toJsonEntry()).toList(),
      'warnings': report.warnings.map((f) => f.toJsonEntry()).toList(),
    };
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(map));
  } else {
    for (final fix in fixes) {
      stdout.writeln(fix.toLine());
    }
    stdout.writeln(report.toText());
  }
  exitCode = report.exitCode;
}

/// Resolves the file to validate: the first positional argument if given,
/// else `design/tokens.json` if it exists, else `tokens/utopia.tokens.json`
/// if it exists, else `null` (caller prints the bootstrap message).
File? _resolveTargetFile(List<String> positional) {
  if (positional.isNotEmpty) {
    return File(positional.first);
  }
  final designTokens = File(p.join('design', 'tokens.json'));
  if (designTokens.existsSync()) {
    return designTokens;
  }
  final canonicalTokens = File(p.join('tokens', 'utopia.tokens.json'));
  if (canonicalTokens.existsSync()) {
    return canonicalTokens;
  }
  return null;
}

String _bootstrapMessage() {
  final packageRoot = RepoLocator.resolveUtopiaUiPackageRoot() ?? RepoLocator.findUtopiaUiRepoRoot();
  if (packageRoot == null) {
    return 'no token document found, and the utopia_ui package could not be resolved from here. '
        'Run this inside a project that depends on utopia_ui (flutter pub add utopia_ui && flutter pub get), '
        'then bootstrap with: mkdir -p design && cp <utopia_ui>/tokens/utopia.tokens.json design/tokens.json';
  }
  final sourcePath = p.join(packageRoot.path, 'tokens', 'utopia.tokens.json');
  return 'no token document found. Bootstrap one by copying the packaged default into your project '
      '(POSIX: mkdir -p design && cp $sourcePath design/tokens.json): '
      'source file: $sourcePath -> target: design/tokens.json';
}
