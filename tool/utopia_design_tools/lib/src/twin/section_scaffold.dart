/// Renders the `twin/components.html` section skeleton for one manifest
/// component (protocol SPEC 4.4), for `generate_twin --scaffold <id>`.
///
/// The twin's component markup and CSS stay hand-authored - a generated twin
/// would only ever restate the Flutter widget tree, and the whole point of the
/// HTML twin is a second, independent expression of the visual contract. What
/// IS mechanical is the section frame around each specimen: the manifest
/// comment, the heading, the description copied out of the manifest, one
/// variant stub per declared state, and the `data-utopia-id` wiring the
/// id-coverage gate requires. The scaffold prints exactly that frame to
/// stdout; a maintainer pastes it into `components.html` (in manifest order)
/// and fills in the markup. Nothing is written to disk.
library;

/// The manifest fields the scaffold reads.
class ScaffoldComponent {
  /// Creates a scaffold input.
  const ScaffoldComponent({required this.id, required this.index, this.description, this.states = const []});

  /// The manifest component id, i.e. the `data-utopia-id` value.
  final String id;

  /// The component's position in `manifest.components`, recorded in the
  /// section comment the way `components.html` already spells it.
  final int index;

  /// The manifest description, pasted verbatim as the section description.
  final String? description;

  /// The manifest's declared states, one variant stub each.
  final List<String> states;
}

/// Reads `components` out of a decoded `utopia.manifest.json`, preserving
/// manifest order (which is the order `components.html` sections follow).
List<ScaffoldComponent> parseScaffoldComponents(Map<String, dynamic> manifestJson) {
  final raw = manifestJson['components'];
  if (raw is! List) return const [];
  final components = <ScaffoldComponent>[];
  for (var i = 0; i < raw.length; i++) {
    final entry = raw[i];
    if (entry is! Map) continue;
    final id = entry['id'];
    if (id is! String) continue;
    final states = entry['states'];
    components.add(
      ScaffoldComponent(
        id: id,
        index: i,
        description: entry['description'] as String?,
        states: states is List ? states.whereType<String>().toList() : const [],
      ),
    );
  }
  return components;
}

/// Builds the stdout text of `generate_twin --scaffold <component.id>`: a
/// paste-in note (the literals rule reminder included) followed by the section
/// skeleton itself.
String buildSectionScaffold(ScaffoldComponent component) {
  final buffer = StringBuffer()
    ..writeln('<!-- SCAFFOLD (generate_twin --scaffold ${component.id}) - paste the section below into')
    ..writeln('     twin/components.html at manifest index ${component.index}, then delete this note.')
    ..writeln('     Fill each specimen stub with hand-authored markup and style it in')
    ..writeln('     twin/components.css. Literals rule (SPEC 4.5): every visual value comes from a')
    ..writeln('     var(--utopia-*) reference - raw colors and font literals hard-fail even inside a')
    ..writeln('     style attribute, and a raw pixel value matching a spacing/radius/border token')
    ..writeln('     hard-fails in stylesheets; annotate a deliberate exception inline with a')
    ..writeln('     utopia-literal-ok comment naming the reason. -->')
    ..writeln()
    ..writeln('    <!-- data-utopia-id="${component.id}" - manifest index ${component.index} -->')
    ..writeln('    <section class="twin-section" data-utopia-id="${component.id}">')
    ..writeln('      <h2 class="twin-section__name">${_escape(_titleOf(component.id))}</h2>')
    ..writeln('      <p class="twin-section__description">');
  buffer
    ..writeln('        ${_escape(component.description ?? 'TODO: describe ${component.id}.')}')
    ..writeln('      </p>')
    ..writeln('      <div class="twin-specimens">')
    ..write(_specimenStub(component.id, label: 'Default', state: null));
  for (final state in component.states) {
    buffer.write(_specimenStub(component.id, label: '$state (${_stateClass(state)})', state: state));
  }
  buffer
    ..writeln('      </div>')
    ..writeln('    </section>');
  return buffer.toString();
}

/// One specimen stub: the labelled wrapper plus a TODO naming what the markup
/// has to carry (the `data-utopia-id`, and the state class for a variant).
String _specimenStub(String id, {required String label, required String? state}) {
  final todo = state == null
      ? 'TODO: markup for "$id" - the root element MUST carry data-utopia-id="$id".'
      : 'TODO: the "$state" state - same markup as the default specimen plus the ${_stateClass(state)} class '
            'on its root (and data-utopia-id="$id").';
  return '        <div class="twin-specimen">\n'
      '          <span class="twin-specimen__label">${_escape(label)}</span>\n'
      '          <!-- ${_escape(todo)} -->\n'
      '        </div>\n';
}

/// The class name a state variant is expressed with: `.is-<state>`,
/// lower-cased, matching how `components.css` already spells its state
/// classes (`readOnly` -> `.is-readonly`, alongside `.is-disabled`,
/// `.is-loading`, `.is-selected`).
String _stateClass(String state) => '.is-${state.toLowerCase()}';

/// The section heading for [id]: the kebab-case manifest id as a sentence
/// (`switch-field` -> `Switch field`).
String _titleOf(String id) {
  final words = id.split('-').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return id;
  final first = words.first;
  return [first[0].toUpperCase() + first.substring(1), ...words.skip(1)].join(' ');
}

/// Escapes the three characters that would otherwise change the emitted
/// markup's structure. The text itself is copied verbatim - a manifest
/// description carrying an angle bracket must read as that character in the
/// rendered twin, not open an element.
String _escape(String text) => text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
