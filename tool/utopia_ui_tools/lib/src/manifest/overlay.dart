/// Loads per-component overlay YAML (`overlay/<id>.yaml`): curated facts that
/// cannot be derived statically from source (interaction `states`, semantic
/// `notes`, curated `examples`, and a `tokenBindingsAdd` escape hatch),
/// merged into the generated manifest by `generator.dart`.
///
/// Also implements the generation-time drift gates from the spec:
/// - an overlay file whose name matches no extracted component id,
/// - an unknown `states` value,
/// - an `examples` path that does not exist in the repo,
/// - a `tokenBindingsAdd` entry the extractor already found (stale escape
///   hatch).
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'extract.dart';

/// The closed `states` vocabulary from `protocol/schemas/manifest.schema.json`
/// (`#/definitions/state`).
const Set<String> validStates = {
  'hover',
  'focus',
  'pressed',
  'loading',
  'disabled',
  'selected',
  'error',
  'empty',
  'readOnly',
  'expanded',
  'open',
  'on',
};

/// One parsed `overlay/<id>.yaml` file (library) or
/// `design/overlay/<local-part>.yaml` file (project, SPEC 3.8).
class ComponentOverlay {
  const ComponentOverlay({
    required this.id,
    required this.states,
    required this.notes,
    required this.examples,
    required this.tokenBindingsAdd,
    this.className,
  });

  /// The library component id this overlay curates (its file's basename
  /// minus `.yaml`), or the project's derived local part (SPEC 3.3) when
  /// loaded for project extraction - the filename in either case.
  final String id;

  /// Curated interaction states, from the closed [validStates] vocabulary.
  final List<String> states;

  /// Free-text usage guidance.
  final String? notes;

  /// Repo-relative example paths.
  final List<String> examples;

  /// Token bindings the AST extractor missed, added verbatim to the
  /// component's `tokenBindings` at generation time.
  final List<String> tokenBindingsAdd;

  /// Project overlays only: an explicit `class: <ClassName>` key binding
  /// this overlay to a class whose derived local part does not equal the
  /// filename (SPEC 3.3 "overlay may override the local part"). `null` when
  /// absent (the common case: the filename IS the derived local part).
  final String? className;
}

/// Loads every `<overlayDir>/*.yaml` file into a [ComponentOverlay], keyed by
/// id (the file's basename). Throws [FormatException] on malformed YAML (the
/// caller is expected to catch this as a fatal, actionable generation error).
Map<String, ComponentOverlay> loadOverlays(Directory overlayDir) {
  final overlays = <String, ComponentOverlay>{};
  if (!overlayDir.existsSync()) return overlays;
  final files = overlayDir.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final id = p.basenameWithoutExtension(file.path);
    final content = file.readAsStringSync();
    final dynamic doc = loadYaml(content);
    final map = doc is YamlMap ? doc : YamlMap();

    final states = <String>[];
    final statesNode = map['states'];
    if (statesNode is YamlList) {
      for (final s in statesNode) {
        states.add(s.toString());
      }
    }

    final notes = map['notes']?.toString();

    final examples = <String>[];
    final examplesNode = map['examples'];
    if (examplesNode is YamlList) {
      for (final e in examplesNode) {
        examples.add(e.toString());
      }
    }

    final tokenBindingsAdd = <String>[];
    final addNode = map['tokenBindingsAdd'];
    if (addNode is YamlList) {
      for (final b in addNode) {
        tokenBindingsAdd.add(b.toString());
      }
    }

    final className = map['class']?.toString();

    overlays[id] = ComponentOverlay(
      id: id,
      states: states,
      notes: notes,
      examples: examples,
      tokenBindingsAdd: tokenBindingsAdd,
      className: className,
    );
  }
  return overlays;
}

/// Applies every generation-time overlay drift gate, returning one
/// actionable message per violation. An empty result means generation may
/// proceed. [repoRoot] resolves `examples` paths; [componentsById] is the
/// already-extracted (bindings-populated) component set, keyed however the
/// caller matches overlays to components (the library: by component id; a
/// project: by derived local part, since a project overlay's filename is
/// the local part, not the final namespaced id). [overlayPathPrefix] renders
/// the overlay's directory in messages
/// (`overlay/` for the library, `design/overlay/` for a project).
/// [reportUnmatched] disables the "references a component that no longer
/// exists" finding for callers (project extraction) that already report a
/// more specific unmatched-overlay diagnostic themselves.
List<String> checkOverlayDrift({
  required Map<String, ComponentOverlay> overlays,
  required Map<String, ExtractedComponent> componentsById,
  required Directory repoRoot,
  String overlayPathPrefix = 'overlay/',
  bool reportUnmatched = true,
}) {
  final errors = <String>[];
  for (final overlay in overlays.values) {
    final component = componentsById[overlay.id];
    if (component == null) {
      if (reportUnmatched) {
        errors.add(
          '$overlayPathPrefix${overlay.id}.yaml references component id "${overlay.id}", which no longer exists '
          'in the extracted source (rename the overlay file or remove it)',
        );
      }
      continue;
    }

    for (final state in overlay.states) {
      if (!validStates.contains(state)) {
        errors.add(
          '$overlayPathPrefix${overlay.id}.yaml: unknown state "$state" (valid states: ${(validStates.toList()..sort()).join(', ')})',
        );
      }
    }

    for (final example in overlay.examples) {
      final exampleFile = File(p.join(repoRoot.path, example));
      if (!exampleFile.existsSync()) {
        errors.add('$overlayPathPrefix${overlay.id}.yaml: example path "$example" does not exist in the repo');
      }
    }

    for (final binding in overlay.tokenBindingsAdd) {
      if (component.tokenBindings.contains(binding)) {
        errors.add(
          '$overlayPathPrefix${overlay.id}.yaml: tokenBindingsAdd entry "$binding" was already found by the '
          'extractor (stale escape hatch - remove it from the overlay)',
        );
      }
    }
  }
  return errors;
}
