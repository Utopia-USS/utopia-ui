/// `validate_manifest` gates (protocol SPEC section 3.7): schema validity,
/// packageVersion drift, id uniqueness/derivation, referential integrity
/// (modelName / composes / twin), and bindings re-extraction against source.
library;

import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;

import '../cli/output.dart';
import 'bindings.dart';
import 'extract.dart';
import 'generator.dart';
import 'source_model.dart';

/// Runs every `validate_manifest` gate against the decoded manifest document,
/// reporting every finding (no fail-fast), mirroring `TokenValidator`'s style
/// in `dtcg/validator.dart`.
///
/// [schema] is the loaded `manifest.schema.json`. [utopiaUiRoot] is the
/// `utopia_ui` checkout the manifest is being validated against (used for
/// gate 2's packageVersion check, gate 4's twin lookup, and gate 5's bindings
/// re-extraction); when `null`, gates 2/4/5 are skipped (their preconditions
/// - a resolvable source/twin tree - are unavailable), matching the spec's
/// "skip silently when sources unavailable" rule.
class ManifestValidator {
  /// Creates a validator bound to the given [schema] and (optional)
  /// [utopiaUiRoot] for source/twin cross-checks.
  const ManifestValidator(this.schema, {this.utopiaUiRoot});

  /// The loaded manifest JSON Schema.
  final JsonSchema schema;

  /// The `utopia_ui` checkout to cross-check packageVersion/twin/bindings
  /// against, or `null` to skip those source-dependent gates.
  final Directory? utopiaUiRoot;

  /// Validates [rawJson], returning every [Finding] from gates 1-5.
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
      // Structurally unusable beyond this point - gates 2-5 all walk
      // `components`.
      return findings;
    }
    final componentsRaw = (rawJson['components'] as List).whereType<Map<String, dynamic>>().toList();
    final modelsRaw = (rawJson['models'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();

    // Gate 2: packageVersion drift.
    findings.addAll(_checkPackageVersion(rawJson));

    // Gate 3: id uniqueness + kebab derivation.
    findings.addAll(_checkIdsAndDerivation(componentsRaw));

    // Gate 4: referential integrity (modelName, composes, twin) + source file
    // existence for every entry that declares one.
    findings.addAll(_checkReferentialIntegrity(componentsRaw, modelsRaw));
    final helpersRaw = (rawJson['helpers'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
    findings.addAll(_checkFilesExist(componentsRaw, modelsRaw, helpersRaw));

    // Gate 5: bindings re-extraction against source (skipped silently when
    // sources are unavailable).
    findings.addAll(_checkBindings(componentsRaw));

    return findings;
  }

  /// Checks that every `file` field points at an existing source file under
  /// the utopia_ui root. Skipped silently when no root is available.
  List<Finding> _checkFilesExist(
    List<Map<String, dynamic>> components,
    List<Map<String, dynamic>> models,
    List<Map<String, dynamic>> helpers,
  ) {
    final root = utopiaUiRoot;
    if (root == null) return const [];
    final findings = <Finding>[];
    void check(String section, Map<String, dynamic> entry) {
      final file = entry['file'];
      if (file is! String) return;
      if (!File(p.join(root.path, file)).existsSync()) {
        final key = entry['id'] ?? entry['name'] ?? '?';
        findings.add(Finding.error('$section[$key].file', 'source file "$file" does not exist under ${root.path}'));
      }
    }

    for (final c in components) {
      check('components', c);
    }
    for (final m in models) {
      check('models', m);
    }
    for (final h in helpers) {
      check('helpers', h);
    }
    return findings;
  }

  String _dottedPath(String instancePath) {
    final segments = instancePath.split('/').where((s) => s.isNotEmpty).toList();
    return segments.map(Uri.decodeComponent).join('.');
  }

  // ---------------------------------------------------------------------
  // Gate 2: packageVersion drift.
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

      final expected = kebabId(name);
      if (id != expected) {
        findings.add(Finding.error(path, 'id "$id" does not match the kebab-case derivation of "$name" ("$expected")'));
      }
    }
    return findings;
  }

  // ---------------------------------------------------------------------
  // Gate 4: referential integrity (modelName, composes, twin).
  // ---------------------------------------------------------------------

  List<Finding> _checkReferentialIntegrity(List<Map<String, dynamic>> components, List<Map<String, dynamic>> models) {
    final findings = <Finding>[];
    final modelNames = models.map((m) => m['name'] as String?).whereType<String>().toSet();
    final componentIds = components.map((c) => c['id'] as String?).whereType<String>().toSet();
    var reportedMissingTwinDir = false;

    for (final component in components) {
      final id = component['id'] as String? ?? '?';
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
    final root = utopiaUiRoot;
    if (root == null) return const [];
    final SourceModel model;
    try {
      model = SourceModel.parse(root);
    } catch (_) {
      return const [];
    }

    final findings = <Finding>[];
    for (final component in components) {
      final id = component['id'] as String? ?? '?';
      final name = component['name'] as String?;
      if (name == null) continue;
      final file = model.fileDeclaring(name);
      if (file == null) {
        findings.add(
          Finding.error('components[$id]', 'class "$name" not found in the utopia_ui sources (stale manifest)'),
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

      for (final binding in manifestBindings.difference(sourceBindings)) {
        findings.add(
          Finding.error('components[$id].tokenBindings', 'stale binding "$binding": not found in source'),
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
}
