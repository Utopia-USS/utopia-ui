/// `generate_twin` - generates the HTML twin's generated surfaces (protocol
/// SPEC section 4) from a token document: `twin/tokens.css`,
/// `twin/tokens.tailwind.css`, and the front matter of `twin/DESIGN.md`.
///
/// It also drives the two maintainer-side surfaces that exist to remove
/// hand-copying from the hand-authored half of the twin, neither of which
/// generates component markup or CSS:
///
/// - `--scaffold <component-id>` prints a `components.html` section skeleton
///   for one manifest component to stdout (writes nothing).
/// - `--compose-gallery` composes `twin/gallery.html` from
///   `twin/gallery.src.html` + the specimen subtrees of
///   `twin/components.html`. A default run does this too whenever the twin
///   directory carries a `gallery.src.html`, per SPEC 6.1's fan-out-by-
///   presence rule.
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
import 'package:utopia_design_tools/src/twin/gallery_composer.dart';
import 'package:utopia_design_tools/src/twin/section_scaffold.dart';
import 'package:utopia_design_tools/src/twin/tailwind_generator.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output directory for the generated twin files.')
    ..addOption(
      'scaffold',
      help: 'Print a components.html section skeleton for the given manifest component id to stdout and exit '
          '(writes nothing).',
      valueHelp: 'component-id',
    )
    ..addOption('manifest', help: 'Path to utopia.manifest.json (overrides auto-discovery, --scaffold only).')
    ..addFlag('json', help: 'Emit machine-readable JSON output instead of text.', negatable: false)
    ..addFlag(
      'compose-gallery',
      help: 'Compose gallery.html from gallery.src.html + components.html and exit (no token generation).',
      negatable: false,
    )
    ..addFlag('skip-tailwind', help: 'Do not generate tokens.tailwind.css.', negatable: false)
    ..addFlag('skip-design-md', help: 'Do not generate DESIGN.md front matter.', negatable: false)
    ..addFlag('skip-gallery', help: 'Do not compose gallery.html even when gallery.src.html exists.', negatable: false)
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
      '[--skip-tailwind] [--skip-design-md] [--skip-gallery]\n'
      '       dart run utopia_design_tools:generate_twin --scaffold <component-id> [--manifest <path>]\n'
      '       dart run utopia_design_tools:generate_twin --compose-gallery [-o <twin-dir>] [--json]',
    );
    stdout.writeln(parser.usage);
    exitCode = 0;
    return;
  }

  final asJson = args['json'] as bool;
  final skipTailwind = args['skip-tailwind'] as bool;
  final skipDesignMd = args['skip-design-md'] as bool;
  final skipGallery = args['skip-gallery'] as bool;
  final scaffoldId = args['scaffold'] as String?;
  final composeGalleryOnly = args['compose-gallery'] as bool;
  final positional = args.rest;

  if (scaffoldId != null && composeGalleryOnly) {
    exitCode = 2;
    stderr.writeln('generate_twin: --scaffold and --compose-gallery do different jobs; pass one at a time.');
    return;
  }

  // --scaffold reads the manifest, not the token document: it prints a
  // components.html section skeleton and returns before anything is resolved,
  // written or validated.
  if (scaffoldId != null) {
    exitCode = _runScaffold(scaffoldId, manifestOption: args['manifest'] as String?);
    return;
  }

  if (composeGalleryOnly) {
    final outputDir = Directory((args['output'] as String?) ?? _defaultTwinDir());
    final composed = _composeGalleryInto(outputDir, required: true);
    if (composed == null) {
      exitCode = 1;
      return;
    }
    if (asJson) {
      stdout.writeln(const JsonEncoder.withIndent('  ').convert({'status': 'ok', 'paths': [composed]}));
    } else {
      stdout.writeln('wrote $composed');
    }
    exitCode = 0;
    return;
  }

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

  final headerInputPath = RepoLocator.normalizeInputPath(targetFile.path);

  // Everything is rendered before anything is written: a document that passes
  // the token gates can still be incoherent for codegen (a typography
  // sub-property aliasing a non-dimension token, a per-layer shadow alias to a
  // multi-layer shadow), and those are deliberate StateErrors carrying an
  // actionable message. Report them like generate_theme does - exit 1 with the
  // message, no half-written twin and no raw stack trace.
  final String cssContent;
  final String? tailwindContent;
  final String? frontMatterBody;
  try {
    cssContent = generateCss(document, inputPath: headerInputPath, profileVersion: profileVersion);
    tailwindContent = skipTailwind
        ? null
        : generateTailwind(document, inputPath: headerInputPath, profileVersion: profileVersion);
    frontMatterBody = skipDesignMd ? null : buildFrontMatterBody(document);
  } on StateError catch (e) {
    exitCode = 1;
    // The generators' messages already carry the tool-name prefix (they are
    // written to be printed verbatim), so it is not doubled here.
    stderr.writeln(e.message.startsWith('generate_twin: ') ? e.message : 'generate_twin: ${e.message}');
    return;
  }

  final outputOption = args['output'] as String?;
  final outputDir = Directory(outputOption ?? _defaultTwinDir());
  outputDir.createSync(recursive: true);

  final writtenPaths = <String>[];

  final cssFile = File(p.join(outputDir.path, 'tokens.css'));
  cssFile.writeAsStringSync(cssContent);
  writtenPaths.add(cssFile.path);

  if (tailwindContent != null) {
    final tailwindFile = File(p.join(outputDir.path, 'tokens.tailwind.css'));
    tailwindFile.writeAsStringSync(tailwindContent);
    writtenPaths.add(tailwindFile.path);
  }

  if (frontMatterBody != null) {
    final designMdFile = File(p.join(outputDir.path, 'DESIGN.md'));
    final existingContent = designMdFile.existsSync() ? designMdFile.readAsStringSync() : null;
    final splice = spliceDesignMd(existingContent, frontMatterBody);
    if (splice.warning != null) {
      stderr.writeln('generate_twin: warning: ${splice.warning}');
    }
    designMdFile.writeAsStringSync(splice.content);
    writtenPaths.add(designMdFile.path);
  }

  // Fan-out by presence (SPEC 6.1): the gallery is composed only for a twin
  // that has materialized a gallery.src.html skeleton. A generated-only
  // consumer twin (tokens.css + DESIGN.md, no hand-authored surface) has
  // nothing to compose and gets no gallery written as a side effect; the
  // maintainer twin in this repo has one, so a plain `generate_twin` keeps it
  // current instead of letting it drift until someone remembers the flag.
  if (!skipGallery) {
    final composed = _composeGalleryInto(outputDir, required: false);
    if (composed == null && _gallerySourceFile(outputDir).existsSync()) {
      exitCode = 1;
      return;
    }
    if (composed != null) writtenPaths.add(composed);
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

/// Prints the `components.html` section skeleton for [componentId] to stdout
/// and returns the process exit code. Writes nothing: the twin's markup stays
/// hand-authored, and this only removes the mechanical part of adding a
/// section (the manifest comment, heading, description and state stubs).
int _runScaffold(String componentId, {required String? manifestOption}) {
  final manifestFile = manifestOption != null ? File(manifestOption) : _resolveDefaultManifestFile();
  if (manifestFile == null || !manifestFile.existsSync()) {
    stderr.writeln(
      'generate_twin: could not resolve manifest/utopia.manifest.json. Pass --manifest <path>, or run from '
      'inside a utopia_ui checkout / a project that resolves the utopia_ui package.',
    );
    return 2;
  }

  final Map<String, dynamic> manifestJson;
  try {
    manifestJson = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    stderr.writeln('generate_twin: ${manifestFile.path} is not valid JSON: ${e.message}');
    return 2;
  }

  final components = parseScaffoldComponents(manifestJson);
  final match = components.where((c) => c.id == componentId).firstOrNull;
  if (match == null) {
    final known = components.map((c) => c.id).toList()..sort();
    stderr.writeln(
      'generate_twin: unknown component id "$componentId" - ${manifestFile.path} declares no such component.\n'
      'Known ids: ${known.join(', ')}',
    );
    return 2;
  }

  stdout.write(buildSectionScaffold(match));
  return 0;
}

/// Composes `gallery.html` in [twinDir] from `gallery.src.html` +
/// `components.html` and returns the written path, or `null` when it was not
/// written.
///
/// A missing `gallery.src.html` is a hard error when [required] (the user
/// asked for `--compose-gallery` explicitly) and a silent skip otherwise (a
/// default run over a twin that never materialized the source skeleton).
/// A malformed marker, an unknown id or a missing `components.html` is always
/// reported and always leaves the existing `gallery.html` untouched.
String? _composeGalleryInto(Directory twinDir, {required bool required}) {
  final sourceFile = _gallerySourceFile(twinDir);
  if (!sourceFile.existsSync()) {
    if (required) {
      stderr.writeln(
        'generate_twin: ${sourceFile.path} not found - --compose-gallery composes gallery.html from that '
        'hand-authored skeleton plus components.html.',
      );
    }
    return null;
  }

  final componentsFile = File(p.join(twinDir.path, 'components.html'));
  if (!componentsFile.existsSync()) {
    stderr.writeln(
      'generate_twin: ${componentsFile.path} not found - the gallery composes its specimens from that file.',
    );
    return null;
  }

  final String composed;
  try {
    composed = composeGallery(
      source: sourceFile.readAsStringSync(),
      componentsHtml: componentsFile.readAsStringSync(),
    );
  } on StateError catch (e) {
    stderr.writeln('generate_twin: ${e.message}');
    return null;
  }

  final galleryFile = File(p.join(twinDir.path, 'gallery.html'));
  galleryFile.writeAsStringSync(composed);
  return galleryFile.path;
}

File _gallerySourceFile(Directory twinDir) => File(p.join(twinDir.path, 'gallery.src.html'));

/// Resolves the default manifest file, mirroring `validate_twin`'s resolution
/// order.
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
  return 'no token document found. Bootstrap one by copying the packaged default into your project:\n'
      '\n'
      '  mkdir -p design && cp -n $sourcePath design/tokens.json\n'
      '\n'
      '(cp -n refuses to overwrite an existing design/tokens.json; on Windows use '
      'copy "$sourcePath" design\\tokens.json after creating the design directory)';
}
