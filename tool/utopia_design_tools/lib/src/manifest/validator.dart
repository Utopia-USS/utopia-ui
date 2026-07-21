/// `validate_manifest` gates (protocol SPEC sections 3.7 and 3.8): schema
/// validity, packageVersion drift, id uniqueness/derivation, referential
/// integrity (modelName / composes / twin), bindings re-extraction against
/// source, and the project/merged-manifest flavor gates (namespace
/// enforcement, utopiaUiVersion presence, merged freshness, file-path roots,
/// model flat-uniqueness).
library;

import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;

import '../cli/output.dart';
import 'bindings.dart';
import 'extract.dart';
import 'generator.dart';
import 'overlay.dart';
import 'source_model.dart';

/// Which of the three SPEC 3.8 document flavors a manifest is, detected from
/// the document itself (never from how it was invoked): `merged: true` marks
/// a merged view; otherwise `package != "utopia_ui"` marks a project
/// manifest; anything else is the library manifest.
enum ManifestFlavor {
  /// The shipped `utopia_ui` library manifest: bare ids, no `utopiaUiVersion`.
  library,

  /// A consumer project's manifest: namespaced ids, `utopiaUiVersion` required.
  project,

  /// The derived merged view: both id flavors coexist, `merged: true`.
  merged,
}

/// Runs every `validate_manifest` gate against the decoded manifest document,
/// reporting every finding (no fail-fast), mirroring `TokenValidator`'s style
/// in `dtcg/validator.dart`.
///
/// [schema] is the loaded `manifest.schema.json`. [utopiaUiRoot] is the
/// `utopia_ui` checkout/package the manifest is being validated against (used
/// for packageVersion/freshness checks, the twin lookup, and bindings
/// re-extraction for bare-id components); [projectRoot] is the consumer
/// project root (used for bindings re-extraction and file-root checks on
/// namespaced components, SPEC 3.8). Either or both may be `null`; the gates
/// that need an unavailable root are skipped silently, matching the spec's
/// "skip silently when sources unavailable" rule.
class ManifestValidator {
  /// Creates a validator bound to the given [schema] and (optional)
  /// [utopiaUiRoot] / [projectRoot] for source cross-checks.
  const ManifestValidator(this.schema, {this.utopiaUiRoot, this.projectRoot});

  /// The loaded manifest JSON Schema.
  final JsonSchema schema;

  /// The `utopia_ui` checkout/package to cross-check bare-id
  /// packageVersion/twin/bindings/file-root against, or `null` to skip those
  /// source-dependent gates.
  final Directory? utopiaUiRoot;

  /// The consumer project root to cross-check namespaced-id
  /// bindings/file-root against (SPEC 3.8), or `null` to skip those gates.
  final Directory? projectRoot;

  /// Validates [rawJson], returning every [Finding] from every gate.
  List<Finding> validate(Map<String, dynamic> rawJson) {
    final findings = <Finding>[];

    // Gate 1: schema validity.
    final schemaResult = schema.validate(rawJson);
    final seen = <String>{};
    for (final error in schemaResult.errors) {
      final path = _dottedPath(error.instancePath);
      final finding = Finding.error(path.isEmpty ? r'$' : path, error.message);
      final key = '${finding.severity}|${finding.path}|${finding.message}';
      if (seen.add(key)) findings.add(finding);
    }

    if (rawJson['components'] is! List) {
      // Structurally unusable beyond this point - every later gate walks
      // `components`.
      return findings;
    }
    final componentsRaw = (rawJson['components'] as List).whereType<Map<String, dynamic>>().toList();
    // `models`/`helpers` may be wrong-typed (e.g. `{}`); the schema gate above
    // already recorded that, so degrade to empty here rather than letting an
    // `as List?` cast throw and mask the clean finding.
    final modelsRaw = (rawJson['models'] is List ? rawJson['models'] as List : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final flavor = _detectFlavor(rawJson);
    final package = rawJson['package'] as String?;

    // Gate 2: packageVersion drift (library manifest only - a project/merged
    // document's packageVersion describes the PROJECT, not utopia_ui).
    if (flavor == ManifestFlavor.library) {
      findings.addAll(_checkPackageVersion(rawJson));
    }

    // Gate 3: id uniqueness + kebab derivation.
    findings.addAll(_checkIdsAndDerivation(componentsRaw));

    // SPEC 3.8 gate: namespace enforcement.
    findings.addAll(_checkNamespaces(componentsRaw, flavor: flavor, package: package));

    // SPEC 3.8 gate: on a merged view, a bare id absent from the shipped
    // library manifest is a stale/hand-edited merge (most often a stripped
    // namespace), not a genuine library component - report it before the
    // file/class-not-found noise the same id would otherwise also trigger
    // further down (gates 4/5).
    if (flavor == ManifestFlavor.merged) {
      findings.addAll(_checkBareIdsAgainstShippedLibrary(componentsRaw));
    }

    // SPEC 3.8 gate: utopiaUiVersion presence.
    findings.addAll(_checkUtopiaUiVersionPresence(rawJson, flavor: flavor));

    // SPEC 3.8 gate: a merged document always describes a consumer project -
    // package "utopia_ui" on a merged doc is library impersonation, even when
    // it carries no namespaced components at all.
    if (flavor == ManifestFlavor.merged && package == 'utopia_ui') {
      findings.add(
        const Finding.error(
          'package',
          'a merged manifest must carry the consumer project package name, not "utopia_ui" (SPEC 3.8)',
        ),
      );
    }

    // SPEC 3.8 gate: merged freshness (utopiaUiVersion == resolved version;
    // embedded library entries deep-equal the shipped manifest).
    if (flavor == ManifestFlavor.merged) {
      findings.addAll(_checkMergedFreshness(rawJson));
    }

    // SPEC 3.8 gate: model flat-uniqueness on merged docs.
    if (flavor == ManifestFlavor.merged) {
      findings.addAll(_checkModelFlatUniqueness(modelsRaw));
    }

    // Gate 4: referential integrity (modelName, composes, twin) + source file
    // existence for every entry that declares one.
    findings.addAll(_checkReferentialIntegrity(componentsRaw, modelsRaw, flavor: flavor));
    final helpersRaw = (rawJson['helpers'] is List ? rawJson['helpers'] as List : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    findings.addAll(_checkFilesExist(componentsRaw, modelsRaw, helpersRaw));

    // Gate 5: bindings re-extraction against source (skipped silently when
    // sources are unavailable).
    findings.addAll(_checkBindings(componentsRaw));

    return findings;
  }

  /// Detects the document's SPEC 3.8 flavor from its own content.
  ManifestFlavor _detectFlavor(Map<String, dynamic> rawJson) {
    if (rawJson['merged'] == true) return ManifestFlavor.merged;
    final package = rawJson['package'];
    if (package is String && package != 'utopia_ui') return ManifestFlavor.project;
    return ManifestFlavor.library;
  }

  /// Whether [id] is namespaced (carries a `<package>:` prefix per the
  /// `kebabId` schema pattern), vs bare.
  bool _isNamespaced(String id) => id.contains(':');

  /// Checks that every `file` field points at an existing source file: bare
  /// ids resolve under [utopiaUiRoot], namespaced ids under [projectRoot].
  /// Skipped per-entry when the relevant root is unavailable.
  List<Finding> _checkFilesExist(
    List<Map<String, dynamic>> components,
    List<Map<String, dynamic>> models,
    List<Map<String, dynamic>> helpers,
  ) {
    final findings = <Finding>[];

    void check(String section, Map<String, dynamic> entry, {required bool namespaced}) {
      final root = namespaced ? projectRoot : utopiaUiRoot;
      if (root == null) return;
      final file = entry['file'];
      if (file is! String) return;
      if (!File(p.join(root.path, file)).existsSync()) {
        final key = entry['id'] ?? entry['name'] ?? '?';
        findings.add(Finding.error('$section[$key].file', 'source file "$file" does not exist under ${root.path}'));
      }
    }

    for (final c in components) {
      final id = c['id'] as String?;
      check('components', c, namespaced: id != null && _isNamespaced(id));
    }
    // models/helpers do not carry an id namespace marker of their own; a
    // model/helper is namespaced (project-owned) exactly when it is not
    // found among the utopia_ui-root files, so try the library root first,
    // falling back to the project root when unresolved there - this mirrors
    // how the merge itself has no other way to tag provenance per entry.
    for (final m in models) {
      _checkEitherRoot('models', m, findings);
    }
    for (final h in helpers) {
      _checkEitherRoot('helpers', h, findings);
    }
    return findings;
  }

  void _checkEitherRoot(String section, Map<String, dynamic> entry, List<Finding> findings) {
    final file = entry['file'];
    if (file is! String) return;
    final libRoot = utopiaUiRoot;
    final projRoot = projectRoot;
    final existsInLib = libRoot != null && File(p.join(libRoot.path, file)).existsSync();
    if (existsInLib) return;
    final existsInProject = projRoot != null && File(p.join(projRoot.path, file)).existsSync();
    if (existsInProject) return;
    if (libRoot == null && projRoot == null) return;
    final key = entry['name'] ?? '?';
    final roots = [if (libRoot != null) libRoot.path, if (projRoot != null) projRoot.path].join(' or ');
    findings.add(Finding.error('$section[$key].file', 'source file "$file" does not exist under $roots'));
  }

  String _dottedPath(String instancePath) {
    final segments = instancePath.split('/').where((s) => s.isNotEmpty).toList();
    return segments.map(Uri.decodeComponent).join('.');
  }

  // ---------------------------------------------------------------------
  // Gate 2: packageVersion drift (library manifest only).
  // ---------------------------------------------------------------------

  List<Finding> _checkPackageVersion(Map<String, dynamic> rawJson) {
    final root = utopiaUiRoot;
    if (root == null) return const [];
    final resolvedVersion = readPackageVersion(File(p.join(root.path, 'pubspec.yaml')));
    if (resolvedVersion == null) return const [];
    final manifestVersion = rawJson['packageVersion'];
    if (manifestVersion is String && manifestVersion != resolvedVersion) {
      return [
        Finding.error(
          'packageVersion',
          'manifest packageVersion "$manifestVersion" does not match the resolved utopia_ui '
              'version "$resolvedVersion" (regenerate the manifest)',
        ),
      ];
    }
    return const [];
  }

  // ---------------------------------------------------------------------
  // Gate 3: id uniqueness + kebab derivation.
  // ---------------------------------------------------------------------

  List<Finding> _checkIdsAndDerivation(List<Map<String, dynamic>> components) {
    final findings = <Finding>[];
    final seenIds = <String, String>{};
    for (final component in components) {
      final id = component['id'] as String?;
      final name = component['name'] as String?;
      if (id == null || name == null) continue;
      final path = 'components[$id]';
      final existing = seenIds[id];
      if (existing != null) {
        final origin = existing == name ? 'duplicated entry for "$name"' : 'also used by "$existing"';
        findings.add(Finding.error(path, 'duplicate component id "$id" ($origin)'));
      }
      seenIds[id] = name;

      // Namespaced (project) ids are exempt from strict kebab-derivation
      // equality: SPEC 3.3 lets a project overlay's `class:` key override the
      // local part, so a namespaced id legitimately need not equal
      // kebabCase(name). Namespace correctness itself is checked separately
      // (SPEC 3.8 gate, _checkNamespaces).
      if (_isNamespaced(id)) continue;

      final expected = kebabId(name);
      if (id != expected) {
        findings.add(Finding.error(path, 'id "$id" does not match the kebab-case derivation of "$name" ("$expected")'));
      }
    }
    return findings;
  }

  // ---------------------------------------------------------------------
  // SPEC 3.8 gate: namespace enforcement.
  // ---------------------------------------------------------------------

  List<Finding> _checkNamespaces(
    List<Map<String, dynamic>> components, {
    required ManifestFlavor flavor,
    required String? package,
  }) {
    final findings = <Finding>[];
    for (final component in components) {
      final id = component['id'] as String?;
      if (id == null) continue;
      final colonIndex = id.indexOf(':');
      final namespace = colonIndex == -1 ? null : id.substring(0, colonIndex);

      switch (flavor) {
        case ManifestFlavor.library:
          if (namespace != null) {
            findings.add(
              Finding.error('components[$id]', 'bare-id document (library manifest) contains namespaced id "$id"'),
            );
          }
        case ManifestFlavor.project:
          if (namespace == null) {
            findings.add(
              Finding.error(
                'components[$id]',
                'project manifest contains bare id "$id" (project component ids must be namespaced '
                    '"<package>:<local-part>", SPEC 3.3)',
              ),
            );
          } else if (package != null && namespace != package) {
            findings.add(
              Finding.error(
                'components[$id]',
                'component id "$id" carries namespace "$namespace", which does not match this document\'s '
                    'package "$package"',
              ),
            );
          }
        case ManifestFlavor.merged:
          if (namespace != null && package != null && namespace != package) {
            findings.add(
              Finding.error(
                'components[$id]',
                'component id "$id" carries namespace "$namespace", which does not match this document\'s '
                    'package "$package" (merged view: every namespaced id must carry the document package)',
              ),
            );
          }
      }
    }
    return findings;
  }

  // ---------------------------------------------------------------------
  // SPEC 3.8 gate: utopiaUiVersion presence.
  // ---------------------------------------------------------------------

  List<Finding> _checkUtopiaUiVersionPresence(Map<String, dynamic> rawJson, {required ManifestFlavor flavor}) {
    final hasVersion = rawJson['utopiaUiVersion'] is String;
    switch (flavor) {
      case ManifestFlavor.library:
        if (hasVersion) {
          return [const Finding.error('utopiaUiVersion', 'utopiaUiVersion must be absent on the library manifest')];
        }
      case ManifestFlavor.project:
      case ManifestFlavor.merged:
        if (!hasVersion) {
          return [
            const Finding.error(
              'utopiaUiVersion',
              'utopiaUiVersion is required on project and merged manifests (SPEC 3.8 freshness gate)',
            ),
          ];
        }
    }
    return const [];
  }

  // ---------------------------------------------------------------------
  // SPEC 3.8 gate: merged freshness.
  // ---------------------------------------------------------------------

  List<Finding> _checkMergedFreshness(Map<String, dynamic> rawJson) {
    final findings = <Finding>[];
    final root = utopiaUiRoot;

    if (root != null) {
      final resolvedVersion = readPackageVersion(File(p.join(root.path, 'pubspec.yaml')));
      final recordedVersion = rawJson['utopiaUiVersion'];
      if (resolvedVersion != null && recordedVersion is String && recordedVersion != resolvedVersion) {
        findings.add(
          Finding.error(
            'utopiaUiVersion',
            'merged manifest utopiaUiVersion "$recordedVersion" does not match the resolved utopia_ui '
                'version "$resolvedVersion" (stale merged view - regenerate)',
          ),
        );
      }

      final shippedLibrary = _loadShippedLibraryManifest(root);
      if (shippedLibrary != null) {
        findings.addAll(_checkEmbeddedLibraryMatchesShipped(rawJson, shippedLibrary));
      }
    }

    return findings;
  }

  /// Loads and decodes `manifest/utopia.manifest.json` from [root], or
  /// returns `null` when the file is missing or not valid JSON (both cases
  /// mean the shipped-library-dependent checks are skipped silently).
  Map<String, dynamic>? _loadShippedLibraryManifest(Directory root) {
    final libraryManifestFile = File(p.join(root.path, 'manifest', 'utopia.manifest.json'));
    if (!libraryManifestFile.existsSync()) return null;
    try {
      return jsonDecode(libraryManifestFile.readAsStringSync()) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  /// SPEC 3.8: on a merged view, every bare (unnamespaced) component id must
  /// exist in the shipped library manifest - a bare id absent there is a
  /// stale or hand-edited merge (most commonly a project entry whose
  /// namespace was stripped), reported here instead of leaking into the
  /// file/class-not-found gates further down.
  List<Finding> _checkBareIdsAgainstShippedLibrary(List<Map<String, dynamic>> components) {
    final root = utopiaUiRoot;
    if (root == null) return const [];
    final shippedLibrary = _loadShippedLibraryManifest(root);
    if (shippedLibrary == null) return const [];
    final shippedIds = (shippedLibrary['components'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((c) => c['id'] as String?)
        .whereType<String>()
        .toSet();

    final findings = <Finding>[];
    for (final component in components) {
      final id = component['id'] as String?;
      if (id == null || _isNamespaced(id) || shippedIds.contains(id)) continue;
      findings.add(
        Finding.error(
          'components[$id]',
          'bare id not present in the shipped library manifest - project components must be namespaced '
              '"<package>:<local-part>" (stale or hand-edited merged view - regenerate)',
        ),
      );
    }
    return findings;
  }

  /// Deep-equality check: every bare-id component/model/helper in the merged
  /// document must equal its counterpart in the shipped library manifest
  /// (entry-for-entry; extra/missing bare entries also flag a stale view).
  List<Finding> _checkEmbeddedLibraryMatchesShipped(Map<String, dynamic> merged, Map<String, dynamic> shipped) {
    bool deepEquals(dynamic a, dynamic b) => const DeepCollectionEquality().equals(a, b);

    final mergedComponents = (merged['components'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((c) => !(c['id'] as String? ?? '').contains(':'))
        .toList();
    final shippedComponents = (shipped['components'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();

    if (!deepEquals(mergedComponents, shippedComponents)) {
      return [
        const Finding.error(
          'components',
          'stale merged view - regenerate (embedded library components do not match the shipped '
              'manifest/utopia.manifest.json)',
        ),
      ];
    }

    final mergedModels = (merged['models'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
    final shippedModels = (shipped['models'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
    final shippedModelNames = shippedModels.map((m) => m['name'] as String?).whereType<String>().toSet();
    final mergedLibraryModels = mergedModels.where((m) => shippedModelNames.contains(m['name'])).toList();
    if (!deepEquals(mergedLibraryModels, shippedModels)) {
      return [
        const Finding.error(
          'models',
          'stale merged view - regenerate (embedded library models do not match the shipped '
              'manifest/utopia.manifest.json)',
        ),
      ];
    }

    final mergedHelpers = (merged['helpers'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
    final shippedHelpers = (shipped['helpers'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
    final shippedHelperNames = shippedHelpers.map((h) => h['name'] as String?).whereType<String>().toSet();
    final mergedLibraryHelpers = mergedHelpers.where((h) => shippedHelperNames.contains(h['name'])).toList();
    if (!deepEquals(mergedLibraryHelpers, shippedHelpers)) {
      return [
        const Finding.error(
          'helpers',
          'stale merged view - regenerate (embedded library helpers do not match the shipped '
              'manifest/utopia.manifest.json)',
        ),
      ];
    }

    return const [];
  }

  // ---------------------------------------------------------------------
  // SPEC 3.8 gate: model flat-uniqueness on merged docs.
  // ---------------------------------------------------------------------

  List<Finding> _checkModelFlatUniqueness(List<Map<String, dynamic>> models) {
    final findings = <Finding>[];
    final seen = <String>{};
    for (final model in models) {
      final name = model['name'] as String?;
      if (name == null) continue;
      if (!seen.add(name)) {
        findings.add(
          Finding.error(
            'models[$name]',
            'duplicate model name "$name" across the merge (flat model namespace, SPEC 3.8)',
          ),
        );
      }
    }
    return findings;
  }

  // ---------------------------------------------------------------------
  // Gate 4: referential integrity (modelName, composes, twin).
  // ---------------------------------------------------------------------

  ///
  /// modelName/composes resolution is enforced for the library and merged
  /// flavors only (SPEC 3.8: "custom components' composes and prop modelName
  /// references MAY point at library ids/models; validate_manifest enforces
  /// resolution on the merged view") - a standalone project document
  /// legitimately contains references into the (unembedded) library half, so
  /// checking them against this document's own components/models alone would
  /// misreport every such reference as dangling.
  List<Finding> _checkReferentialIntegrity(
    List<Map<String, dynamic>> components,
    List<Map<String, dynamic>> models, {
    required ManifestFlavor flavor,
  }) {
    final findings = <Finding>[];
    final modelNames = models.map((m) => m['name'] as String?).whereType<String>().toSet();
    final componentIds = components.map((c) => c['id'] as String?).whereType<String>().toSet();
    final checkCrossReferences = flavor != ManifestFlavor.project;
    var reportedMissingTwinDir = false;

    for (final component in components) {
      final id = component['id'] as String? ?? '?';
      if (checkCrossReferences) {
        for (final ctor in (component['constructors'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
          for (final prop in (ctor['props'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
            final modelName = prop['modelName'];
            if (modelName is String && !modelNames.contains(modelName)) {
              findings.add(
                Finding.error(
                  'components[$id].modelName',
                  'prop "${prop['name']}" references modelName "$modelName", which has no entry in "models"',
                ),
              );
            }
          }
        }
        for (final composesId in (component['composes'] as List? ?? const []).whereType<String>()) {
          if (!componentIds.contains(composesId)) {
            findings.add(
              Finding.error('components[$id].composes', 'composes references unknown component id "$composesId"'),
            );
          }
        }
      }

      final twin = component['twin'];
      if (twin is Map<String, dynamic>) {
        final root = utopiaUiRoot;
        if (root == null) continue;
        final twinDir = Directory(p.join(root.path, 'twin'));
        if (!twinDir.existsSync()) {
          if (!reportedMissingTwinDir) {
            findings.add(
              const Finding.warning('twin', 'twin/ directory not found; skipping twin binding checks'),
            );
            reportedMissingTwinDir = true;
          }
          continue;
        }
        final twinFile = File(p.join(twinDir.path, twin['file'] as String? ?? ''));
        final selector = twin['selector'] as String?;
        if (!twinFile.existsSync()) {
          findings.add(
            Finding.error('components[$id].twin', 'twin file "${twin['file']}" does not exist under twin/'),
          );
        } else if (selector != null) {
          final expectedAttr = 'data-utopia-id=$id';
          final content = twinFile.readAsStringSync();
          if (!content.contains(expectedAttr) && !selector.contains(expectedAttr)) {
            findings.add(
              Finding.error(
                'components[$id].twin',
                'twin file "${twin['file']}" does not contain the selector\'s data-utopia-id ("$id")',
              ),
            );
          }
        }
      }
    }
    return findings;
  }

  // ---------------------------------------------------------------------
  // Gate 5: bindings re-extraction.
  // ---------------------------------------------------------------------

  List<Finding> _checkBindings(List<Map<String, dynamic>> components) {
    final findings = <Finding>[];

    SourceModel? libraryModel;
    if (utopiaUiRoot != null) {
      try {
        libraryModel = SourceModel.parse(utopiaUiRoot!);
      } catch (_) {
        libraryModel = null;
      }
    }

    SourceModel? projectModel;
    if (projectRoot != null) {
      try {
        projectModel = SourceModel.parseProjectLib(projectRoot!);
      } catch (_) {
        projectModel = null;
      }
    }

    // The overlay layer merges `tokenBindingsAdd` escape-hatch entries into a
    // component's `tokenBindings` at generation time (generator.componentJson);
    // load the same overlays here so those entries are never reported stale.
    final libraryOverlays = utopiaUiRoot != null
        ? _loadOverlaysSafe(Directory(p.join(utopiaUiRoot!.path, 'tool', 'utopia_design_tools', 'overlay')))
        : const <String, ComponentOverlay>{};
    final projectOverlays = projectRoot != null
        ? _loadOverlaysSafe(Directory(p.join(projectRoot!.path, 'design', 'overlay')))
        : const <String, ComponentOverlay>{};

    for (final component in components) {
      final id = component['id'] as String? ?? '?';
      final name = component['name'] as String?;
      if (name == null) continue;

      final namespaced = _isNamespaced(id);
      final model = namespaced ? projectModel : libraryModel;
      if (model == null) continue;

      final file = model.fileDeclaring(name);
      if (file == null) {
        final sourceKind = namespaced ? 'project' : 'utopia_ui';
        findings.add(
          Finding.error('components[$id]', 'class "$name" not found in the $sourceKind sources (stale manifest)'),
        );
        continue;
      }

      final declaredPath = component['file'] as String?;
      if (declaredPath != null && declaredPath != file.repoRelativePath) {
        findings.add(
          Finding.error(
            'components[$id].file',
            'file "$declaredPath" does not match the declaring source file "${file.repoRelativePath}"',
          ),
        );
      }

      final sourceBindings = extractTokenBindings(file.unit).toSet();
      final manifestBindings = (component['tokenBindings'] as List? ?? const []).whereType<String>().toSet();
      final overlayAdds = _overlayTokenBindingsAdd(
        id,
        name,
        namespaced: namespaced,
        libraryOverlays: libraryOverlays,
        projectOverlays: projectOverlays,
      );
      final knownBindings = sourceBindings.union(overlayAdds);

      for (final binding in manifestBindings.difference(knownBindings)) {
        findings.add(
          Finding.error(
            'components[$id].tokenBindings',
            'stale binding "$binding": not found in source or overlay tokenBindingsAdd',
          ),
        );
      }
      for (final binding in sourceBindings.difference(manifestBindings)) {
        findings.add(
          Finding.error('components[$id].tokenBindings', 'missing binding "$binding": found in source but not in the manifest'),
        );
      }
    }
    return findings;
  }

  /// Loads overlays from [dir], degrading to an empty map on any error
  /// (missing dir, malformed YAML) - the bindings gate must never crash the
  /// whole validation over an unreadable overlay.
  Map<String, ComponentOverlay> _loadOverlaysSafe(Directory dir) {
    try {
      return loadOverlays(dir);
    } catch (_) {
      return const {};
    }
  }

  /// The `tokenBindingsAdd` escape-hatch entries the overlay layer merges into
  /// a component's `tokenBindings` at generation time, resolved the same way
  /// `generator`/`project_generator` do: a bare-id (library) component matches
  /// its overlay by id; a namespaced (project) component matches by class name,
  /// mirroring `ProjectComponentIdStrategy.idFor` (derived local part first,
  /// then an explicit `class:` binding).
  Set<String> _overlayTokenBindingsAdd(
    String id,
    String name, {
    required bool namespaced,
    required Map<String, ComponentOverlay> libraryOverlays,
    required Map<String, ComponentOverlay> projectOverlays,
  }) {
    if (!namespaced) {
      return libraryOverlays[id]?.tokenBindingsAdd.toSet() ?? const {};
    }
    final derived = projectOverlays[kebabCase(name)];
    if (derived != null && (derived.className == null || derived.className == name)) {
      return derived.tokenBindingsAdd.toSet();
    }
    for (final overlay in projectOverlays.values) {
      if (overlay.className == name) {
        return overlay.tokenBindingsAdd.toSet();
      }
    }
    return const {};
  }
}

/// Minimal structural deep-equality for decoded JSON values (`Map`, `List`,
/// and primitives), used by the merged-freshness gate to compare embedded
/// library entries against the shipped manifest without depending on a
/// third-party collection-equality package.
class DeepCollectionEquality {
  /// Creates a deep-equality comparator.
  const DeepCollectionEquality();

  /// Whether [a] and [b] are structurally equal: recursively for `Map`s
  /// (same keys, equal values) and `List`s (same length, equal elements in
  /// order), `==` otherwise.
  bool equals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!equals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!equals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}
