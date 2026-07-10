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
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_design_tools/src/manifest/generator.dart';
import 'package:utopia_design_tools/src/manifest/validator.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output path, relative to the utopia_ui repo root.')
    ..addOption('overlay-dir', help: 'Overlay directory, relative to the utopia_ui repo root.')
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
      '[--overlay-dir <dir>] [--timestamp] [--json]',
    );
    stdout.writeln(parser.usage);
    exitCode = 0;
    return;
  }

  final asJson = args['json'] as bool;

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
  final validator = ManifestValidator(schema, utopiaUiRoot: repoRoot);
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
