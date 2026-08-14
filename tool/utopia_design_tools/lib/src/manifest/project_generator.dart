/// Assembles the project and merged manifest documents for
/// `generate_manifest --project` (protocol SPEC section 3.8): runs project
/// extraction (opt-in via overlay, namespaced ids), then produces both the
/// project-only document and the derived merged view (library + project
/// components in one file).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'bindings.dart';
import 'extract.dart';
import 'generator.dart';
import 'overlay.dart';
import 'project_extract.dart';
import 'source_model.dart';

/// The result of a `generate_manifest --project` run: either both assembled
/// documents (project + merged, as ordered `Map`s ready to encode), or a
/// non-empty list of fatal, actionable errors that must abort generation
/// before anything is written.
class ProjectGenerationResult {
  /// Creates a successful result carrying both assembled documents and any
  /// non-fatal [warnings].
  const ProjectGenerationResult.ok({
    required this.projectManifest,
    required this.mergedManifest,
    this.warnings = const [],
  }) : errors = const [];

  /// Creates a failed result carrying one or more fatal [errors]; both
  /// manifests are `null`.
  const ProjectGenerationResult.failed(this.errors) : projectManifest = null, mergedManifest = null, warnings = const [];

  /// The assembled project manifest (components/models/helpers scoped to the
  /// project only). `null` on failure.
  final Map<String, dynamic>? projectManifest;

  /// The assembled merged manifest (library + project). `null` on failure.
  final Map<String, dynamic>? mergedManifest;

  /// Fatal, actionable errors. Empty on success.
  final List<String> errors;

  /// Non-fatal, actionable warnings (e.g. a project class name shadowing a
  /// library component class, which makes parse-only `composes` resolution
  /// ambiguous). Empty unless generation succeeded with caveats.
  final List<String> warnings;

  /// Whether generation succeeded (no fatal errors).
  bool get isOk => errors.isEmpty;
}

/// Runs the full project-extraction + merge pipeline.
///
/// [projectRoot] is the consumer project's root (containing its own
/// `pubspec.yaml` and `lib/`); [overlayDir] is the project's overlay
/// directory (SPEC 3.8 default: `design/overlay/`); [utopiaUiRoot] is the
/// resolved `utopia_ui` package root, used to read its version and to load
/// its shipped manifest (`manifest/utopia.manifest.json`) for the merge -
/// the library half is embedded byte-faithfully, never re-extracted. When
/// [withTimestamp] is `true`, stamps `generatedAt` on both documents.
ProjectGenerationResult generateProjectManifest({
  required Directory projectRoot,
  required Directory overlayDir,
  required Directory utopiaUiRoot,
  bool withTimestamp = false,
}) {
  final projectPubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));
  final projectPackageName = readPackageName(projectPubspec);
  if (projectPackageName == null) {
    return ProjectGenerationResult.failed(['could not read a "name:" field from ${projectPubspec.path}']);
  }
  final projectPackageVersion = readPackageVersion(projectPubspec) ?? '0.0.0';

  final utopiaUiPubspec = File(p.join(utopiaUiRoot.path, 'pubspec.yaml'));
  final utopiaUiVersion = readPackageVersion(utopiaUiPubspec);
  if (utopiaUiVersion == null) {
    return ProjectGenerationResult.failed(['could not read a "version:" field from ${utopiaUiPubspec.path}']);
  }

  final libraryManifestFile = File(p.join(utopiaUiRoot.path, 'manifest', 'utopia.manifest.json'));
  if (!libraryManifestFile.existsSync()) {
    final message =
        'shipped library manifest not found at ${libraryManifestFile.path} '
        '(resolve a utopia_ui checkout/package that ships manifest/utopia.manifest.json)';
    return ProjectGenerationResult.failed([message]);
  }
  // Decode to dynamic first: valid JSON that is not an object (a top-level
  // array, a bare string/number) decodes fine and would otherwise throw a
  // CastError outside the FormatException catch.
  final dynamic decodedLibraryManifest;
  try {
    decodedLibraryManifest = jsonDecode(libraryManifestFile.readAsStringSync());
  } on FormatException catch (e) {
    return ProjectGenerationResult.failed(['${libraryManifestFile.path} is not valid JSON: ${e.message}']);
  }
  if (decodedLibraryManifest is! Map<String, dynamic>) {
    final message =
        '${libraryManifestFile.path} is not a manifest object - the shipped library manifest must be a '
        'JSON object (see protocol/schemas/manifest.schema.json)';
    return ProjectGenerationResult.failed([message]);
  }
  final libraryManifest = decodedLibraryManifest;

  final hasOverlays =
      overlayDir.existsSync() && overlayDir.listSync().whereType<File>().any((f) => f.path.endsWith('.yaml'));
  if (!hasOverlays) {
    final message =
        'no overlay files found under ${overlayDir.path}. generate_manifest --project registers custom '
        'components opt-in only (SPEC 3.8): a component is included exactly when the project has an '
        'overlay YAML for it. Create design/overlay/<local-part>.yaml (e.g. states: [hover], notes: "...") '
        'for at least one widget class before regenerating.';
    return ProjectGenerationResult.failed([message]);
  }

  final SourceModel model;
  try {
    model = SourceModel.parseProjectLib(projectRoot);
  } on StateError catch (e) {
    return ProjectGenerationResult.failed([e.message]);
  }

  final overlaysByLocalPart = loadOverlays(overlayDir);
  final idStrategy = ProjectComponentIdStrategy(
    projectPackageName: projectPackageName,
    overlaysByLocalPart: overlaysByLocalPart,
  );

  final extraction = extractAll(model, idStrategy: idStrategy);
  if (extraction.errors.isNotEmpty) {
    return ProjectGenerationResult.failed(extraction.errors);
  }

  final danglingErrors = checkDanglingProjectOverlays(
    overlaysByLocalPart: overlaysByLocalPart,
    matchedOverlayIds: idStrategy.matchedOverlayIds,
  );
  if (danglingErrors.isNotEmpty) {
    return ProjectGenerationResult.failed(danglingErrors);
  }

  // composes resolves against BOTH this project's own extracted components
  // (namespaced ids) and the shipped library manifest's components (bare
  // ids) - SPEC 3.8 referential integrity. The library half is the already-
  // generated, byte-faithful manifest, not a re-parse.
  final libraryComponentIdByClassName = <String, String>{
    for (final raw in (libraryManifest['components'] as List? ?? const []).whereType<Map<String, dynamic>>())
      if (raw['name'] is String && raw['id'] is String) raw['name'] as String: raw['id'] as String,
  };
  resolveComposes(model, extraction.components, extraIdByClassName: libraryComponentIdByClassName);

  // Parse-only composes resolution is class-name based: a project class that
  // shadows a library component class name wins the lookup, so constructor
  // calls of the LIBRARY widget would resolve to the project id. Legal but
  // ambiguous - surface it loudly as a warning.
  //
  // Scope: this check covers OPTED-IN classes only. extraction.components
  // holds exactly the overlay-registered classes (ProjectComponentIdStrategy
  // returns null for everything else - SPEC 3.8 opt-in), so a project class
  // that shadows a library class WITHOUT having an overlay never enters
  // extraction and produces no warning. That is a consequence of the opt-in
  // boundary, not a whole-project namespace scan - the shadow only becomes
  // observable (and warned about) once the class is registered.
  String shadowWarning(ExtractedComponent component) =>
      'project class "${component.name}" shadows the utopia_ui component class of the same name: composes '
      'references to "${component.name}" anywhere in this project resolve to "${component.id}", not '
      '"${libraryComponentIdByClassName[component.name]}" (parse-only resolution cannot tell them apart - '
      'consider renaming the project class)';
  final warnings = <String>[
    for (final component in extraction.components)
      if (libraryComponentIdByClassName.containsKey(component.name)) shadowWarning(component),
  ];

  for (final component in extraction.components) {
    final file = model.fileDeclaring(component.name);
    if (file != null) {
      component.tokenBindings = extractTokenBindings(file.unit);
    }
  }

  // Overlays are keyed by local part; components carry namespaced ids -
  // resolve each component's overlay via the strategy's recorded local part.
  final overlayForComponent = <String, ComponentOverlay>{
    for (final component in extraction.components)
      component.id: ?overlaysByLocalPart[idStrategy.localPartByClassName[component.name]],
  };

  final componentsByLocalPart = <String, ExtractedComponent>{
    for (final component in extraction.components)
      ?idStrategy.localPartByClassName[component.name]: component,
  };
  final driftErrors = checkOverlayDrift(
    overlays: overlaysByLocalPart,
    componentsById: componentsByLocalPart,
    repoRoot: projectRoot,
    overlayPathPrefix: 'design/overlay/',
    reportUnmatched: false,
  );
  if (driftErrors.isNotEmpty) {
    return ProjectGenerationResult.failed(driftErrors);
  }

  // Model flat-uniqueness across the merge (SPEC 3.8): a project model name
  // colliding with a library model name fails generation before anything is
  // written.
  final libraryModelNames = <String>{
    for (final raw in (libraryManifest['models'] as List? ?? const []).whereType<Map<String, dynamic>>())
      if (raw['name'] is String) raw['name'] as String,
  };
  final collisions = extraction.models.map((m) => m.name).where(libraryModelNames.contains).toSet();
  if (collisions.isNotEmpty) {
    final sortedCollisions = collisions.toList()..sort();
    String collisionMessage(String name) =>
        'model name "$name" collides between the project manifest and the shipped library manifest '
        '(flat model namespace, SPEC 3.8 - rename the project model)';
    return ProjectGenerationResult.failed([for (final name in sortedCollisions) collisionMessage(name)]);
  }

  final projectManifest = <String, dynamic>{
    'schemaVersion': manifestSchemaVersion,
    'package': projectPackageName,
    'packageVersion': projectPackageVersion,
    'utopiaUiVersion': utopiaUiVersion,
    if (withTimestamp) 'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'components': extraction.components.map((c) => componentJson(c, overlayForComponent[c.id])).toList(),
    'models': extraction.models.map((m) => m.toJson()).toList(),
    'helpers': extraction.helpers.map((h) => h.toJson()).toList(),
  };

  final libraryComponents = (libraryManifest['components'] as List? ?? const []).toList();
  final libraryModels = (libraryManifest['models'] as List? ?? const []).toList();
  final libraryHelpers = (libraryManifest['helpers'] as List? ?? const []).toList();

  final mergedManifest = <String, dynamic>{
    'schemaVersion': manifestSchemaVersion,
    'package': projectPackageName,
    'packageVersion': projectPackageVersion,
    'utopiaUiVersion': utopiaUiVersion,
    'merged': true,
    if (withTimestamp) 'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'components': [...libraryComponents, ...(projectManifest['components'] as List)],
    'models': [...libraryModels, ...(projectManifest['models'] as List)],
    'helpers': [...libraryHelpers, ...(projectManifest['helpers'] as List)],
  };

  return ProjectGenerationResult.ok(projectManifest: projectManifest, mergedManifest: mergedManifest, warnings: warnings);
}
