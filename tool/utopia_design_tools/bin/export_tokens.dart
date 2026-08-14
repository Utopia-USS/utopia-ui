/// `export_tokens` - exports `UtopiaThemeData.defaultTheme` to a DTCG token
/// document (protocol SPEC section 2). Maintainer-only: requires a checkout
/// of the `utopia_ui` repository plus the Flutter SDK, because capturing a
/// live `UtopiaThemeData` needs Flutter (see `lib/src/dtcg/theme_capture.dart`).
///
/// This entrypoint itself is pure Dart (`dart run` works standalone): it
/// shells out to `flutter test --no-pub test/export_runner_test.dart`, the
/// one place in this package that imports Flutter, and reads the JSON that
/// test writes to a temporary path.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output path, relative to the utopia_ui repo root.')
    ..addFlag('json', help: 'Emit machine-readable JSON output instead of text.', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('export_tokens: ${e.message}');
    stderr.writeln(parser.usage);
    exitCode = 2;
    return;
  }

  if (args['help'] as bool) {
    stdout.writeln('Usage: dart run utopia_design_tools:export_tokens [-o <path>] [--json]');
    stdout.writeln(parser.usage);
    exitCode = 0;
    return;
  }

  final asJson = args['json'] as bool;

  final repoRoot = RepoLocator.findUtopiaUiRepoRoot();
  if (repoRoot == null) {
    exitCode = 2;
    stderr.writeln(
      'export_tokens: this is a maintainer-only tool - run it from inside a checkout of the '
      'utopia_ui repository (no pubspec.yaml with name: utopia_ui was found above the current '
      'directory).',
    );
    return;
  }

  final toolPackageDir = Directory(p.join(repoRoot.path, 'tool', 'utopia_design_tools'));
  if (!toolPackageDir.existsSync()) {
    exitCode = 2;
    stderr.writeln('export_tokens: expected tool package directory not found: ${toolPackageDir.path}');
    return;
  }

  final dartToolDir = Directory(p.join(toolPackageDir.path, '.dart_tool'));
  if (!dartToolDir.existsSync()) {
    stderr.writeln('export_tokens: running "flutter pub get" in ${toolPackageDir.path} first...');
    final pubGet = await Process.run('flutter', ['pub', 'get'], workingDirectory: toolPackageDir.path);
    if (pubGet.exitCode != 0) {
      exitCode = 2;
      stderr.writeln('export_tokens: "flutter pub get" failed:');
      stderr.writeln(pubGet.stdout);
      stderr.writeln(pubGet.stderr);
      return;
    }
  }

  final tempDir = await Directory.systemTemp.createTemp('utopia_export_tokens_');
  final capturedFile = File(p.join(tempDir.path, 'captured.tokens.json'));
  try {
    final result = await Process.run(
      'flutter',
      ['test', '--no-pub', 'test/export_runner_test.dart'],
      workingDirectory: toolPackageDir.path,
      environment: {'UTOPIA_EXPORT_OUT': capturedFile.path},
    );
    if (result.exitCode != 0) {
      exitCode = 2;
      stderr.writeln('export_tokens: capture via "flutter test" failed:');
      stderr.writeln(result.stdout);
      stderr.writeln(result.stderr);
      return;
    }

    if (!capturedFile.existsSync()) {
      exitCode = 2;
      stderr.writeln(
        'export_tokens: "flutter test" ran but did not write the expected output file; the '
        'runner test may not have executed as expected.',
      );
      return;
    }

    final Map<String, dynamic> rawJson;
    try {
      rawJson = jsonDecode(capturedFile.readAsStringSync()) as Map<String, dynamic>;
    } on FormatException catch (e) {
      exitCode = 2;
      stderr.writeln('export_tokens: the capture runner produced invalid JSON: ${e.message}');
      return;
    }

    final schemaFile = RepoLocator.findTokensSchema(start: repoRoot);
    if (schemaFile == null || !schemaFile.existsSync()) {
      exitCode = 2;
      stderr.writeln('export_tokens: could not resolve protocol/schemas/tokens.schema.json under ${repoRoot.path}.');
      return;
    }

    final JsonSchema schema;
    try {
      schema = loadSchema(schemaFile.readAsStringSync());
      // json_schema throws ArgumentError (an Error) on non-JSON input and
      // FormatException on structural problems - convert both to exit 2.
    } catch (e) {
      exitCode = 2;
      stderr.writeln('export_tokens: ${schemaFile.path} is not a valid JSON Schema: $e');
      return;
    }
    final validator = TokenValidator(schema);
    final findings = validator.validate(rawJson);
    final report = FindingReport(findings);

    final outputOption = args['output'] as String?;
    final outputPath = outputOption ?? p.join('tokens', 'utopia.tokens.json');
    final outputFile = File(p.isAbsolute(outputPath) ? outputPath : p.join(repoRoot.path, outputPath));

    if (report.hasErrors) {
      exitCode = 1;
      if (asJson) {
        stdout.writeln(report.toJson());
      } else {
        stderr.writeln('export_tokens: the captured document failed self-validation; not writing ${outputFile.path}.');
        stdout.writeln(report.toText());
      }
      return;
    }

    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync(capturedFile.readAsStringSync());

    final tokenCount = _countTokens(rawJson);
    if (asJson) {
      stdout.writeln(
        const JsonEncoder.withIndent(
          '  ',
        ).convert({'status': 'ok', 'path': outputFile.path, 'tokenCount': tokenCount}),
      );
    } else {
      stdout.writeln('wrote ${outputFile.path} ($tokenCount tokens)');
    }
    exitCode = 0;
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

/// Counts every token leaf (`$type`+`$value` pair) in the captured document,
/// for the summary line printed on success.
int _countTokens(Map<String, dynamic> json) {
  var count = 0;
  void walk(Map<String, dynamic> node) {
    if (node.containsKey(r'$type') && node.containsKey(r'$value')) {
      count++;
      return;
    }
    for (final entry in node.entries) {
      if (entry.key.startsWith(r'$')) {
        continue;
      }
      final child = entry.value;
      if (child is Map<String, dynamic>) {
        walk(child);
      }
    }
  }

  walk(json);
  return count;
}
