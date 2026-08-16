/// `generate_theme` - generates a Dart `UtopiaThemeData` factory from a token
/// document (protocol SPEC section 5).
///
/// Pure Dart: does not import Flutter, so `dart run` works standalone, both
/// inside this repo checkout and in a consumer project that has installed
/// `utopia_design_tools` as a dev dependency. The generated *output* file
/// imports Flutter (and `utopia_ui`) - that import only exists in the text
/// this tool writes, never in this entrypoint itself.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/token_document.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/theme_gen/dart_emitter.dart';
import 'package:utopia_design_tools/src/theme_gen/theme_spec.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output path for the generated Dart file.')
    ..addFlag(
      'check',
      help:
          'Compare the generated output against the existing output file instead of writing it; '
          'exit 1 when it is stale or missing. Pass the same arguments as the generating run.',
      negatable: false,
    )
    ..addFlag('json', help: 'Emit machine-readable JSON output instead of text.', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('generate_theme: ${e.message}');
    stderr.writeln(parser.usage);
    exitCode = 2;
    return;
  }

  if (args['help'] as bool) {
    stdout.writeln(
      'Usage: dart run utopia_design_tools:generate_theme [<tokens-file>] [-o <path>] [--check] [--json]',
    );
    stdout.writeln(parser.usage);
    exitCode = 0;
    return;
  }

  final asJson = args['json'] as bool;
  final checkOnly = args['check'] as bool;
  final positional = args.rest;

  final targetFile = _resolveTargetFile(positional);
  if (targetFile == null) {
    exitCode = 2;
    stderr.writeln(_bootstrapMessage());
    return;
  }

  if (!targetFile.existsSync()) {
    exitCode = 2;
    stderr.writeln('generate_theme: file not found: ${targetFile.path}');
    return;
  }

  final schemaFile = RepoLocator.findTokensSchema();
  if (schemaFile == null || !schemaFile.existsSync()) {
    exitCode = 2;
    stderr.writeln(
      'generate_theme: could not resolve protocol/schemas/tokens.schema.json. '
      'Run from inside a utopia_ui checkout / a project that resolves the utopia_ui package.',
    );
    return;
  }

  final Map<String, dynamic> rawJson;
  try {
    rawJson = jsonDecode(targetFile.readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    exitCode = 2;
    stderr.writeln('generate_theme: ${targetFile.path} is not valid JSON: ${e.message}');
    return;
  }

  final JsonSchema schema;
  try {
    schema = loadSchema(schemaFile.readAsStringSync());
    // json_schema throws ArgumentError (an Error) on non-JSON input and
    // FormatException on structural problems - convert both to exit 2.
  } catch (e) {
    exitCode = 2;
    stderr.writeln('generate_theme: ${schemaFile.path} is not a valid JSON Schema: $e');
    return;
  }

  final validator = TokenValidator(schema);
  final findings = validator.validate(rawJson);
  final report = FindingReport(findings);

  if (report.hasErrors) {
    exitCode = 1;
    if (asJson) {
      stdout.writeln(report.toJson());
    } else {
      stderr.writeln('generate_theme: ${targetFile.path} failed validation; nothing written.');
      stdout.writeln(report.toText());
    }
    return;
  }

  final ThemeSpec spec;
  final String generated;
  try {
    final document = TokenDocument.parse(rawJson);
    spec = ThemeSpec.fromDocument(document);
    // Normalized like generate_twin's header path: an in-repo input is
    // recorded relative to the utopia_ui root, so the generated identity
    // header does not vary with the directory the tool happened to be invoked
    // from. The Regenerate: line keeps the path as invoked instead - the
    // normalized one is relative to the utopia_ui root, which is not
    // necessarily the directory the printed command would be run from, and a
    // command that resolves nowhere is worse than none.
    generated = emitDart(
      spec,
      inputPath: RepoLocator.normalizeInputPath(targetFile.path),
      regeneratePath: targetFile.path,
    );
  } on StateError catch (e) {
    exitCode = 1;
    // ThemeSpec's messages already carry the tool-name prefix (they are
    // written to be printed verbatim), so it is not doubled here.
    stderr.writeln(e.message.startsWith('generate_theme: ') ? e.message : 'generate_theme: ${e.message}');
    return;
  }

  final outputOption = args['output'] as String?;
  final outputPath = outputOption ?? p.join('lib', 'theme', 'utopia_theme.g.dart');
  final outputFile = File(outputPath);

  if (checkOnly) {
    _runCheck(outputFile: outputFile, generated: generated, tokensPath: targetFile.path, asJson: asJson);
    return;
  }

  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(generated);

  if (asJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert({'status': 'ok', 'path': outputFile.path}));
  } else {
    stdout.writeln('wrote ${outputFile.path}');
    // The last mile: without wiring, UtopiaTheme.of silently falls back to
    // defaultTheme and a completed rebrand produces no visible change.
    stdout.writeln('next step: wrap your app root with UtopiaTheme(data: buildUtopiaTheme(), child: ...)');
  }
  exitCode = 0;
}

/// Runs the `--check` path: regenerates in memory and compares the result
/// against the bytes already on disk at [outputFile]. Writes nothing, ever -
/// not the output file and not its parent directory.
///
/// Exit codes: 0 when the file matches byte-for-byte, 1 when it is stale or
/// absent (both mean the same thing to a caller: regenerate and commit the
/// result), 2 when an existing file cannot be read.
///
/// The comparison is byte-exact against the text the writing path would have
/// produced, so it only holds for the arguments the generating run used: the
/// emitted `// Regenerate:` header line keeps the token path as invoked, so
/// checking the same pair of files from another working directory reports a
/// stale file over that one line. Hence "pass the same arguments" in --check's
/// help text.
void _runCheck({
  required File outputFile,
  required String generated,
  required String tokensPath,
  required bool asJson,
}) {
  final regenerateCommand =
      'dart run utopia_design_tools:generate_theme ${_shellArg(tokensPath)} -o ${_shellArg(outputFile.path)}';

  if (!outputFile.existsSync()) {
    exitCode = 1;
    if (asJson) {
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'status': 'missing',
          'path': outputFile.path,
          'regenerate': regenerateCommand,
        }),
      );
    } else {
      stderr.writeln('generate_theme: ${outputFile.path} does not exist - generate it via: $regenerateCommand');
    }
    return;
  }

  final List<int> existing;
  try {
    existing = outputFile.readAsBytesSync();
  } on FileSystemException catch (e) {
    exitCode = 2;
    stderr.writeln('generate_theme: failed to read ${outputFile.path}: ${e.message}');
    return;
  }

  // The writing path uses writeAsStringSync, which encodes UTF-8 - so this is
  // a comparison against exactly the bytes a regeneration would leave behind.
  if (!_bytesEqual(existing, utf8.encode(generated))) {
    exitCode = 1;
    if (asJson) {
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'status': 'stale',
          'path': outputFile.path,
          'regenerate': regenerateCommand,
        }),
      );
    } else {
      stderr.writeln('generate_theme: ${outputFile.path} is stale - regenerate via: $regenerateCommand');
    }
    return;
  }

  exitCode = 0;
  if (asJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert({'status': 'ok', 'path': outputFile.path}));
  } else {
    stdout.writeln('up to date: ${outputFile.path}');
  }
}

/// Renders [value] as one shell argument of a copy-pasteable command line.
///
/// A path holding a space (or any other character a shell would read as
/// syntax) is wrapped in single quotes, with embedded single quotes closed and
/// reopened the POSIX way (`'\''`); a plain path is left exactly as it was, so
/// the common message reads as an ordinary command rather than a quoted one.
/// Without this, `--check` on a project under `~/My Projects` printed a
/// "regenerate via" line that the shell would split into two arguments.
String _shellArg(String value) {
  if (value.isNotEmpty && !RegExp('[^A-Za-z0-9_@%+=:,./-]').hasMatch(value)) {
    return value;
  }
  return "'${value.replaceAll("'", r"'\''")}'";
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Resolves the file to generate from: the first positional argument if
/// given, else `design/tokens.json` if it exists, else
/// `tokens/utopia.tokens.json` if it exists, else `null` (caller prints the
/// bootstrap message). Identical resolution order to `validate_tokens`.
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
  return 'no token document found. Bootstrap one by copying the packaged default into your project:\n'
      '\n'
      '  mkdir -p design && cp -n $sourcePath design/tokens.json\n'
      '\n'
      '(cp -n refuses to overwrite an existing design/tokens.json; on Windows use '
      'copy "$sourcePath" design\\tokens.json after creating the design directory)';
}
