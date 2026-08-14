/// Assembles the full manifest document: runs extraction, per-component
/// bindings extraction, overlay merge (with drift gates), sorts everything
/// into the schema's fixed key order, and renders to indented JSON.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'bindings.dart';
import 'extract.dart';
import 'overlay.dart';
import 'source_model.dart';
import 'twin_sections.dart';

/// The protocol/schema version this generator targets (protocol
/// SPEC.md / VERSIONING.md).
const String manifestSchemaVersion = '0.3.0';

/// `tokenBindings` provenance markers (SPEC 3.6, protocol 0.3.0): a binding
/// the extractor read out of the component's own Dart source, versus one the
/// overlay's `tokenBindingsAdd` escape hatch declared.
const String tokenBindingOriginSource = 'source';

/// See [tokenBindingOriginSource].
const String tokenBindingOriginOverlay = 'overlay';

/// Reads the `version:` field from a `pubspec.yaml` file. Returns `null` if
/// the file does not exist or has no top-level `version:` line.
String? readPackageVersion(File pubspecFile) {
  if (!pubspecFile.existsSync()) return null;
  for (final line in const LineSplitter().convert(pubspecFile.readAsStringSync())) {
    final match = RegExp(r'^version:\s*(\S+)\s*$').firstMatch(line);
    if (match != null) return match.group(1);
  }
  return null;
}

/// Reads the `name:` field from a `pubspec.yaml` file. Returns `null` if the
/// file does not exist or has no top-level `name:` line.
String? readPackageName(File pubspecFile) {
  if (!pubspecFile.existsSync()) return null;
  for (final line in const LineSplitter().convert(pubspecFile.readAsStringSync())) {
    final match = RegExp(r'^name:\s*(\S+)\s*$').firstMatch(line);
    if (match != null) return match.group(1);
  }
  return null;
}

/// The result of a generation run: either the assembled manifest (as an
/// ordered `Map`, ready to encode) plus its packageVersion, or a non-empty
/// list of fatal, actionable errors (extraction failures or overlay drift)
/// that must abort generation before anything is written.
class GenerationResult {
  /// Creates a successful result carrying the assembled [manifest].
  const GenerationResult.ok(this.manifest) : errors = const [];

  /// Creates a failed result carrying one or more fatal [errors]; [manifest]
  /// is `null`.
  const GenerationResult.failed(this.errors) : manifest = null;

  /// The assembled manifest, ready to render/write. `null` on failure.
  final Map<String, dynamic>? manifest;

  /// Fatal, actionable errors. Empty on success.
  final List<String> errors;

  /// Whether generation succeeded (no fatal errors).
  bool get isOk => errors.isEmpty;
}

/// Runs the full generation pipeline against the `utopia_ui` checkout at
/// [utopiaUiRoot], merging overlays from [overlayDir]. When [withTimestamp]
/// is `true`, stamps `generatedAt` with the current UTC time (omitted by
/// default for deterministic output).
GenerationResult generateManifest({
  required Directory utopiaUiRoot,
  required Directory overlayDir,
  bool withTimestamp = false,
}) {
  final packageVersion = readPackageVersion(File(p.join(utopiaUiRoot.path, 'pubspec.yaml')));
  if (packageVersion == null) {
    return GenerationResult.failed([
      'could not read a "version:" field from ${p.join(utopiaUiRoot.path, 'pubspec.yaml')}',
    ]);
  }

  final SourceModel model;
  try {
    model = SourceModel.parse(utopiaUiRoot);
  } on StateError catch (e) {
    return GenerationResult.failed([e.message]);
  }

  final extraction = extractAll(model);
  if (extraction.errors.isNotEmpty) {
    return GenerationResult.failed(extraction.errors);
  }

  resolveComposes(model, extraction.components);

  // Per-component tokenBindings: re-parse-free, since SourceModel already
  // holds every file's CompilationUnit.
  for (final component in extraction.components) {
    final file = model.fileDeclaring(component.name);
    if (file != null) {
      component.tokenBindings = extractTokenBindings(file.unit);
    }
  }

  final overlays = loadOverlays(overlayDir);
  final componentsById = {for (final c in extraction.components) c.id: c};
  final driftErrors = checkOverlayDrift(overlays: overlays, componentsById: componentsById, repoRoot: utopiaUiRoot);
  if (driftErrors.isNotEmpty) {
    return GenerationResult.failed(driftErrors);
  }

  // Which components the HTML twin actually renders (SPEC 4.4): derived from
  // the bundle's own `data-utopia-id` roots, never a hand-kept list, so a
  // component gains or loses its `twin` field exactly when the twin does.
  final twinSectionIds = readTwinSectionIdsFor(utopiaUiRoot);

  final manifest = <String, dynamic>{
    'schemaVersion': manifestSchemaVersion,
    'package': 'utopia_ui',
    'packageVersion': packageVersion,
    if (withTimestamp) 'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'components': extraction.components
        .map((c) => componentJson(c, overlays[c.id], twinSectionIds: twinSectionIds))
        .toList(),
    'models': extraction.models.map((m) => m.toJson()).toList(),
    'helpers': extraction.helpers.map((h) => h.toJson()).toList(),
  };

  return GenerationResult.ok(manifest);
}

/// Renders a single extracted component plus its (optional) overlay to the
/// manifest JSON `component` shape: merges `tokenBindingsAdd` into
/// `tokenBindings` (stamping each entry's `origin`), binds the component to
/// its twin section when [twinSectionIds] contains its id, and layers on the
/// overlay's `states`/`examples`/`notes`. Shared by both the library generator
/// (`generateManifest`) and project extraction (`generate_manifest --project`,
/// SPEC 3.8).
Map<String, dynamic> componentJson(
  ExtractedComponent component,
  ComponentOverlay? overlay, {
  Set<String> twinSectionIds = const {},
}) => {
  'id': component.id,
  'name': component.name,
  'description': component.description,
  'file': component.file,
  if (component.generic) 'generic': true,
  'constructors': component.constructors.map((c) => c.toJson()).toList(),
  'tokenBindings': tokenBindingsJson(
    sourceBindings: component.tokenBindings,
    overlayBindings: overlay?.tokenBindingsAdd ?? const [],
  ),
  if (overlay != null && overlay.states.isNotEmpty) 'states': (overlay.states.toList()..sort()),
  if (component.composes.isNotEmpty) 'composes': component.composes,
  if (twinSectionIds.contains(component.id)) 'twin': twinBindingJson(component.id),
  if (overlay != null && overlay.examples.isNotEmpty) 'examples': overlay.examples,
  if (overlay != null && overlay.notes != null) 'notes': overlay.notes,
};

/// The `tokenBindings` array for one component (protocol 0.3.0): the union of
/// the extractor's [sourceBindings] and the overlay's [overlayBindings], one
/// object per path, each stamped with the `origin` it came from and sorted by
/// path (the sort keeps two generation runs byte-identical).
///
/// A path present on both sides is stamped `source`: generation already fails
/// on a `tokenBindingsAdd` entry the extractor found (the stale-escape-hatch
/// drift gate in `overlay.dart`), so this only decides the labelling of a
/// state that cannot reach a written manifest.
List<Map<String, String>> tokenBindingsJson({
  required Iterable<String> sourceBindings,
  required Iterable<String> overlayBindings,
}) {
  final origins = <String, String>{
    for (final path in overlayBindings) path: tokenBindingOriginOverlay,
    for (final path in sourceBindings) path: tokenBindingOriginSource,
  };
  final paths = origins.keys.toList()..sort();
  return [
    for (final path in paths) {'path': path, 'origin': origins[path]!},
  ];
}

/// Renders [manifest] to the canonical on-disk form: 2-space indent, trailing
/// newline.
String renderManifestJson(Map<String, dynamic> manifest) {
  final encoded = const JsonEncoder.withIndent('  ').convert(manifest);
  return '$encoded\n';
}
