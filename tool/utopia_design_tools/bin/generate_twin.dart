/// `generate_twin` - generates the HTML twin's generated surfaces (protocol
/// SPEC section 4) from a token document: `twin/tokens.css`,
/// `twin/tokens.tailwind.css`, and the front matter of `twin/DESIGN.md`.
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
import 'package:utopia_design_tools/src/twin/css_generator.dart';
import 'package:utopia_design_tools/src/twin/design_md_generator.dart';
import 'package:utopia_design_tools/src/twin/tailwind_generator.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output directory for the generated twin files.')
    ..addFlag('json', help: 'Emit machine-readable JSON output instead of text.', negatable: false)
    ..addFlag('skip-tailwind', help: 'Do not generate tokens.tailwind.css.', negatable: false)
    ..addFlag('skip-design-md', help: 'Do not generate DESIGN.md front matter.', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('generate_twin: ${e.message}');
    stderr.writeln(parser.usage);
    exitCode = 2;
    return;
  }

  if (args['help'] as bool) {
    stdout.writeln(
      'Usage: dart run utopia_design_tools:generate_twin [<tokens-file>] [-o <twin-dir>] [--json] '
      '[--skip-tailwind] [--skip-design-md]',
    );
    stdout.writeln(parser.usage);
    exitCode = 0;
    return;
  }

  final asJson = args['json'] as bool;
  final skipTailwind = args['skip-tailwind'] as bool;
  final skipDesignMd = args['skip-design-md'] as bool;
  final positional = args.rest;

  final targetFile = _resolveTargetFile(positional);
  if (targetFile == null) {
    exitCode = 2;
    stderr.writeln(_bootstrapMessage());
    return;
  }

  if (!targetFile.existsSync()) {
    exitCode = 2;
    stderr.writeln('generate_twin: file not found: ${targetFile.path}');
    return;
  }

  final schemaFile = RepoLocator.findTokensSchema();
  if (schemaFile == null || !schemaFile.existsSync()) {
    exitCode = 2;
    stderr.writeln(
      'generate_twin: could not resolve protocol/schemas/tokens.schema.json. '
      'Run from inside a utopia_ui checkout / a project that resolves the utopia_ui package.',
    );
    return;
  }

  final Map<String, dynamic> rawJson;
  try {
    rawJson = jsonDecode(targetFile.readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    exitCode = 2;
    stderr.writeln('generate_twin: ${targetFile.path} is not valid JSON: ${e.message}');
    return;
  }

  final JsonSchema schema;
  try {
    schema = loadSchema(schemaFile.readAsStringSync());
    // json_schema throws ArgumentError (an Error) on non-JSON input and
    // FormatException on structural problems - convert both to exit 2.
  } catch (e) {
    exitCode = 2;
    stderr.writeln('generate_twin: ${schemaFile.path} is not a valid JSON Schema: $e');
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
      stderr.writeln('generate_twin: ${targetFile.path} failed validation; nothing written.');
      stdout.writeln(report.toText());
    }
    return;
  }

  final document = TokenDocument.parse(rawJson);
  final profileVersion = (document.rootExtensions?['profileVersion'] as String?) ?? protocolVersion;

  final outputOption = args['output'] as String?;
  final outputDir = Directory(outputOption ?? _defaultTwinDir());
  outputDir.createSync(recursive: true);

  final writtenPaths = <String>[];

  final cssFile = File(p.join(outputDir.path, 'tokens.css'));
  cssFile.writeAsStringSync(generateCss(document, inputPath: targetFile.path, profileVersion: profileVersion));
  writtenPaths.add(cssFile.path);

  if (!skipTailwind) {
    final tailwindFile = File(p.join(outputDir.path, 'tokens.tailwind.css'));
    tailwindFile.writeAsStringSync(
      generateTailwind(document, inputPath: targetFile.path, profileVersion: profileVersion),
    );
    writtenPaths.add(tailwindFile.path);
  }

  if (!skipDesignMd) {
    final designMdFile = File(p.join(outputDir.path, 'DESIGN.md'));
    final existingContent = designMdFile.existsSync() ? designMdFile.readAsStringSync() : null;
    final frontMatterBody = buildFrontMatterBody(document);
    final splice = spliceDesignMd(existingContent, frontMatterBody);
    if (splice.warning != null) {
      stderr.writeln('generate_twin: warning: ${splice.warning}');
    }
    designMdFile.writeAsStringSync(splice.content);
    writtenPaths.add(designMdFile.path);
  }

  if (asJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert({'status': 'ok', 'paths': writtenPaths}));
  } else {
    for (final path in writtenPaths) {
      stdout.writeln('wrote $path');
    }
  }
  exitCode = 0;
}

/// Resolves the file to generate from: the first positional argument if
/// given, else `design/tokens.json` if it exists, else
/// `tokens/utopia.tokens.json` if it exists, else `null` (caller prints the
/// bootstrap message). Identical resolution order to `validate_tokens` and
/// `generate_theme`.
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

/// The default `-o` target: `<utopia_ui root>/twin` when run inside this
/// repo checkout, else `./twin` under the current working directory (a
/// consumer project regenerating its own design surface).
String _defaultTwinDir() {
  final repoRoot = RepoLocator.findUtopiaUiRepoRoot();
  if (repoRoot != null) {
    return p.join(repoRoot.path, 'twin');
  }
  return p.join('twin');
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
