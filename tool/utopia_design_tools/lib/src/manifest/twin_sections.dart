/// Scans the HTML twin's `components.html` for the component ids it actually
/// renders, so `generate_manifest` can fill each component entry's `twin`
/// field (SPEC 3.4 / 4.4) mechanically instead of from a hand-kept list.
///
/// Read-only over the twin bundle: the twin itself is generated/curated
/// elsewhere (`generate_twin`, `validate_twin`); this file only asks which
/// `data-utopia-id` roots exist.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// The twin bundle directory name inside a package root (SPEC 4.1).
const String twinDirName = 'twin';

/// The twin file whose sections back the manifest's `twin` bindings, named
/// the way the manifest records it: twin-bundle-relative (SPEC 3.4's example
/// and 4.1's layout), NOT package-root-relative.
const String twinComponentsFile = 'components.html';

/// `data-utopia-id="<id>"` occurrences, tolerating single quotes and an
/// unquoted value; the trailing look-ahead keeps `chip` from matching
/// `chip-list`.
final RegExp _twinIdAttribute = RegExp(r'''data-utopia-id\s*=\s*["']?([a-z][a-z0-9]*(?:-[a-z0-9]+)*)["']?''');

/// HTML comments, stripped before the scan so a documentation placeholder
/// (`data-utopia-id="<manifest id>"` in the file header) can never be read as
/// a real section.
final RegExp _htmlComment = RegExp('<!--.*?-->', dotAll: true);

/// Every component id that carries a `data-utopia-id` root in [file], or an
/// empty set when the file does not exist (a checkout or package root without
/// a twin bundle generates a manifest with no `twin` fields rather than
/// failing).
Set<String> readTwinSectionIds(File file) {
  if (!file.existsSync()) return const {};
  final content = file.readAsStringSync().replaceAll(_htmlComment, '');
  return {for (final match in _twinIdAttribute.allMatches(content)) match.group(1)!};
}

/// [readTwinSectionIds] for the canonical bundle location under [packageRoot]
/// (`<packageRoot>/twin/components.html`).
Set<String> readTwinSectionIdsFor(Directory packageRoot) =>
    readTwinSectionIds(File(p.join(packageRoot.path, twinDirName, twinComponentsFile)));

/// The `twin` entry the manifest records for [id]: the twin-bundle-relative
/// file plus the attribute selector for that component's root.
///
/// Typed `Map<String, dynamic>` on purpose: an in-memory manifest is
/// self-validated before it is ever written, and the validator's twin gate
/// reads decoded-JSON shapes.
Map<String, dynamic> twinBindingJson(String id) => {
  'file': twinComponentsFile,
  'selector': '[data-utopia-id="$id"]',
};
