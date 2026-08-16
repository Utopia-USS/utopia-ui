import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/manifest/overlay.dart';
import 'package:utopia_design_tools/src/util/repo.dart';

/// The closed component-state vocabulary lives in two places that must be
/// edited together: `protocol/schemas/manifest.schema.json`
/// (`#/definitions/state`) and the Dart [validStates] constant the overlay
/// parser enforces before the schema ever sees a manifest. Nothing else
/// guards the pair - adding a state to the schema alone makes
/// `generate_manifest` reject a schema-valid overlay with "unknown state".
void main() {
  test('overlay validStates equals the schema #/definitions/state enum', () {
    final repoRoot = RepoLocator.findUtopiaUiRepoRoot();
    expect(repoRoot, isNotNull, reason: 'test must run inside the utopia-ui repo');

    final schemaFile = File(p.join(repoRoot!.path, 'protocol', 'schemas', 'manifest.schema.json'));
    final schema = jsonDecode(schemaFile.readAsStringSync()) as Map<String, dynamic>;
    final definitions = schema['definitions'] as Map<String, dynamic>;
    final stateDefinition = definitions['state'] as Map<String, dynamic>;
    final schemaStates = (stateDefinition['enum'] as List<dynamic>).cast<String>().toSet();

    expect(
      validStates,
      equals(schemaStates),
      reason: 'validStates (lib/src/manifest/overlay.dart) and '
          '#/definitions/state (protocol/schemas/manifest.schema.json) drifted - '
          'every state change must edit both',
    );
  });
}
