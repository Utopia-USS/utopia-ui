/// Project-side extraction for `generate_manifest --project` (protocol SPEC
/// section 3.8): opt-in component classification (an overlay YAML must exist
/// for a widget class to be included) and namespaced id derivation (SPEC
/// 3.3), built on top of the shared [extractAll] pipeline in `extract.dart`.
library;

import 'package:analyzer/dart/ast/ast.dart';

import 'extract.dart';
import 'overlay.dart';
import 'source_model.dart';

/// The [ComponentIdStrategy] for `generate_manifest --project`: a widget
/// class is included exactly when a project overlay matches it (opt-in, SPEC
/// 3.8), and its id is `<projectPackageName>:<local-part>` (SPEC 3.3).
///
/// Matching rule: the class's derived local part (`kebabCase(className)`, no
/// prefix stripping) must equal some overlay file's basename, OR an overlay
/// file's `class:` key must name the class explicitly (then that overlay
/// file's basename becomes the local part, overriding the derivation). Every
/// overlay actually matched to a class is recorded in [matchedOverlayIds] so
/// the caller can report unmatched overlays (SPEC 3.8 drift: an overlay
/// referencing a component that does not exist in the analyzed source) after
/// extraction completes.
class ProjectComponentIdStrategy implements ComponentIdStrategy {
  /// Creates a project id strategy over [overlaysByLocalPart] (keyed by the
  /// overlay file's basename) for a project package named [projectPackageName].
  ProjectComponentIdStrategy({required this.projectPackageName, required this.overlaysByLocalPart});

  /// The consumer project's package name (from its pubspec), used as the id
  /// namespace prefix.
  final String projectPackageName;

  /// Every loaded project overlay, keyed by its file's basename (the
  /// filename-derived local part before any `class:` override is applied).
  final Map<String, ComponentOverlay> overlaysByLocalPart;

  /// Overlay filenames (keys of [overlaysByLocalPart]) successfully matched
  /// to a class during classification. Populated as a side effect of
  /// [idFor]; read after [extractAll] returns to find dangling overlays.
  final Set<String> matchedOverlayIds = {};

  /// Class-name-keyed local part actually used for each matched class
  /// (equals the overlay's filename either way - by derivation or by
  /// `class:` override). Populated alongside [matchedOverlayIds].
  final Map<String, String> localPartByClassName = {};

  @override
  String? idFor(ClassDeclaration cls, ParsedFile file, List<String> errors) {
    final className = cls.name.lexeme;
    final derivedLocalPart = kebabCase(className);

    // An overlay whose filename equals the derived local part matches
    // directly (the common case).
    if (overlaysByLocalPart.containsKey(derivedLocalPart)) {
      final overlay = overlaysByLocalPart[derivedLocalPart]!;
      // A `class:` key on this overlay must still agree (or be absent) -
      // an overlay bound to a DIFFERENT class via `class:` does not also
      // implicitly match the class whose derivation happens to equal its
      // filename.
      if (overlay.className == null || overlay.className == className) {
        matchedOverlayIds.add(derivedLocalPart);
        localPartByClassName[className] = derivedLocalPart;
        return '$projectPackageName:$derivedLocalPart';
      }
    }

    // Otherwise, look for an overlay carrying an explicit `class:` key
    // naming this class (the local part is then the overlay's filename,
    // not the derivation).
    for (final overlay in overlaysByLocalPart.values) {
      if (overlay.className == className) {
        matchedOverlayIds.add(overlay.id);
        localPartByClassName[className] = overlay.id;
        return '$projectPackageName:${overlay.id}';
      }
    }

    // No overlay opts this class in - excluded, not an error.
    return null;
  }
}

/// Post-extraction drift check: every project overlay file that matched no
/// class (SPEC 3.8's opt-in registration failing to find its target),
/// mirroring the library's "overlay references a component that no longer
/// exists" gate in `checkOverlayDrift`.
List<String> checkDanglingProjectOverlays({
  required Map<String, ComponentOverlay> overlaysByLocalPart,
  required Set<String> matchedOverlayIds,
}) {
  final errors = <String>[];
  for (final localPart in overlaysByLocalPart.keys) {
    if (matchedOverlayIds.contains(localPart)) continue;
    final overlay = overlaysByLocalPart[localPart]!;
    if (overlay.className != null) {
      errors.add(
        'design/overlay/$localPart.yaml carries class: "${overlay.className}", which does not match any '
        'concrete StatelessWidget/StatefulWidget/HookWidget subclass in the project sources',
      );
    } else {
      errors.add(
        'design/overlay/$localPart.yaml matches no class (no class derives the local part "$localPart"; '
        'add a "class: <ClassName>" key to bind it explicitly, or remove the overlay)',
      );
    }
  }
  return errors;
}
