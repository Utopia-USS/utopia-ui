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

/// The protocol/schema version this generator targets (protocol
/// SPEC.md / VERSIONING.md).
const String manifestSchemaVersion = '0.2.0';

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

  final manifest = <String, dynamic>{
    'schemaVersion': manifestSchemaVersion,
    'package': 'utopia_ui',
    'packageVersion': packageVersion,
    if (withTimestamp) 'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'components': extraction.components.map((c) => componentJson(c, overlays[c.id])).toList(),
    'models': extraction.models.map((m) => m.toJson()).toList(),
    'helpers': extraction.helpers.map((h) => h.toJson()).toList(),
  };

  return GenerationResult.ok(manifest);
}

/// Renders a single extracted component plus its (optional) overlay to the
/// manifest JSON `component` shape: merges `tokenBindingsAdd` into
/// `tokenBindings` and layers on the overlay's `states`/`examples`/`notes`.
/// Shared by both the library generator (`generateManifest`) and project
/// extraction (`generate_manifest --project`, SPEC 3.8).
Map<String, dynamic> componentJson(ExtractedComponent component, ComponentOverlay? overlay) {
  final tokenBindings = {...component.tokenBindings, ...?overlay?.tokenBindingsAdd}.toList()..sort();
  return {
    'id': component.id,
    'name': component.name,
    'description': component.description,
    'file': component.file,
    if (component.generic) 'generic': true,
    'constructors': component.constructors.map((c) => c.toJson()).toList(),
    'tokenBindings': tokenBindings,
    if (overlay != null && overlay.states.isNotEmpty) 'states': (overlay.states.toList()..sort()),
    if (component.composes.isNotEmpty) 'composes': component.composes,
    if (overlay != null && overlay.examples.isNotEmpty) 'examples': overlay.examples,
    if (overlay != null && overlay.notes != null) 'notes': overlay.notes,
  };
}

/// Renders [manifest] to the canonical on-disk form: 2-space indent, trailing
/// newline.
String renderManifestJson(Map<String, dynamic> manifest) {
  final encoded = const JsonEncoder.withIndent('  ').convert(manifest);
  return '$encoded\n';
}
