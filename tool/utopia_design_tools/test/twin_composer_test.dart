// Tests for the two maintainer-side twin surfaces of generate_twin: the
// gallery composer (twin/gallery.src.html + twin/components.html ->
// twin/gallery.html) and the components.html section scaffold. Neither
// generates component markup or CSS - the composer relocates markup a
// maintainer already wrote, the scaffold only prints the section frame - so
// the contract under test is "verbatim, deterministic, and loud when a marker
// names something that does not exist".
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/twin/gallery_composer.dart';
import 'package:utopia_design_tools/src/twin/section_scaffold.dart';

void main() {
  final repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));

  /// A miniature components catalog with the shapes the composer has to
  /// handle: a section root sharing its id with the specimens inside it, two
  /// specimens for one id, a void-element specimen and a nested one.
  const componentsHtml = '''
<main>
    <!-- data-utopia-id="button" - manifest index 0 -->
    <section class="twin-section" data-utopia-id="button">
      <h2>Button</h2>
      <div class="twin-specimens">
        <div class="twin-specimen">
          <button class="utopia-button" data-utopia-id="button" type="button">
            <span class="utopia-button__label">Save changes</span>
          </button>
        </div>
        <div class="twin-specimen">
          <button class="utopia-button utopia-button--dense" data-utopia-id="button" type="button">
            <span class="utopia-button__label">Apply</span>
          </button>
        </div>
      </div>
    </section>
    <section class="twin-section" data-utopia-id="divider">
      <hr class="utopia-divider" data-utopia-id="divider" style="width: 240px;" />
    </section>
</main>
''';

  group('findSpecimens', () {
    test('skips section roots and captures each specimen subtree', () {
      final specimens = findSpecimens(componentsHtml);

      expect(specimens.map((s) => s.id).toList(), ['button', 'button', 'divider']);
      expect(specimens.first.tagName, 'button');
      expect(specimens.first.text, startsWith('<button class="utopia-button" data-utopia-id="button"'));
      expect(specimens.first.text, endsWith('</button>'));
      expect(specimens.first.text, contains('Save changes'));
      expect(specimens.first.text, isNot(contains('Apply')), reason: 'the subtree stops at its own closing tag');
    });

    test('a void element specimen is its own subtree', () {
      final divider = findSpecimens(componentsHtml).last;

      expect(divider.text, '<hr class="utopia-divider" data-utopia-id="divider" style="width: 240px;" />');
    });
  });

  group('composeGallery', () {
    test('splices the specimen subtree in verbatim, at the marker indentation', () {
      const source = '''
<main>
      <div class="twin-specimen">
        <span class="twin-specimen__label">Default</span>
        <!-- utopia-specimen: button -->
      </div>
</main>
''';

      final composed = composeGallery(source: source, componentsHtml: componentsHtml);

      expect(
        composed,
        contains(
          '        <button class="utopia-button" data-utopia-id="button" type="button">\n'
          '            <span class="utopia-button__label">Save changes</span>\n'
          '          </button>\n',
        ),
        reason: 'the subtree goes in byte-for-byte; only the first line takes the marker indentation',
      );
      expect(composed, isNot(contains('utopia-specimen: button')), reason: 'the marker itself is consumed');
      expect(composed, contains('<span class="twin-specimen__label">Default</span>'));
    });

    test('an occurrence selector picks the n-th specimen of that id', () {
      const source = '<!-- utopia-specimen: button #2 -->\n';

      final composed = composeGallery(source: source, componentsHtml: componentsHtml);

      expect(composed, contains('Apply'));
      expect(composed, isNot(contains('Save changes')));
    });

    test('starts with the COMPOSED banner naming both inputs and the regeneration command', () {
      final composed = composeGallery(source: '<main></main>\n', componentsHtml: componentsHtml);

      expect(composed, startsWith('<!--\n  twin/gallery.html - COMPOSED by utopia_design_tools:generate_twin'));
      expect(composed, contains('twin/gallery.src.html + twin/components.html'));
      expect(composed, contains('generate_twin --compose-gallery'));
    });

    test('is deterministic: two runs over the same inputs are byte-identical', () {
      const source = '''
<main>
    <!-- utopia-specimen: button -->
    <!-- utopia-specimen: button #2 -->
    <!-- utopia-twin-omit: page-wrapper -- pure layout-resolution behavior, nothing rendered -->
</main>
''';

      final first = composeGallery(source: source, componentsHtml: componentsHtml);
      final second = composeGallery(source: source, componentsHtml: componentsHtml);

      expect(first, equals(second));
    });

    test('carries omit markers through untouched', () {
      const marker = '    <!-- utopia-twin-omit: page-wrapper -- pure layout-resolution behavior, nothing rendered -->';

      final composed = composeGallery(source: '$marker\n', componentsHtml: componentsHtml);

      expect(composed, contains(marker));
    });

    test('an unknown specimen id fails loudly, naming the source line and the fix', () {
      expect(
        () => composeGallery(source: '\n<!-- utopia-specimen: ghost-buttons -->\n', componentsHtml: componentsHtml),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('gallery.src.html:2'),
              contains('unknown specimen id "ghost-buttons"'),
              contains('--scaffold ghost-buttons'),
            ),
          ),
        ),
      );
    });

    test('an out-of-range occurrence selector fails loudly with the available count', () {
      expect(
        () => composeGallery(source: '<!-- utopia-specimen: button #3 -->\n', componentsHtml: componentsHtml),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('"button" #3 does not exist'), contains('2 specimen(s)')),
          ),
        ),
      );
    });

    test('a malformed marker is rejected instead of being emitted as a comment', () {
      expect(
        () => composeGallery(source: '<!-- utopia-specimen: -->\n', componentsHtml: componentsHtml),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('malformed specimen marker'))),
      );
    });

    test('prose mentioning the grammar inside a comment body is not a marker', () {
      const source = '''
<!--
  Each utopia-specimen: <id> marker is replaced by that specimen's subtree.
-->
''';

      expect(composeGallery(source: source, componentsHtml: componentsHtml), contains('is replaced by that specimen'));
    });
  });

  group('the repo twin', () {
    test('twin/gallery.html is exactly what its source composes to', () {
      // The same contract validate_twin's freshness gates enforce for the
      // generated stylesheets: a hand edit made straight in gallery.html (the
      // drift this composer exists to end) fails here.
      final twinDir = Directory(p.join(repoRoot.path, 'twin'));
      final composed = composeGallery(
        source: File(p.join(twinDir.path, 'gallery.src.html')).readAsStringSync(),
        componentsHtml: File(p.join(twinDir.path, 'components.html')).readAsStringSync(),
      );

      expect(
        composed,
        equals(File(p.join(twinDir.path, 'gallery.html')).readAsStringSync()),
        reason: 'run: dart run utopia_design_tools:generate_twin --compose-gallery',
      );
    });

    test('every gallery specimen marker names a real components.html specimen', () {
      final twinDir = Directory(p.join(repoRoot.path, 'twin'));
      final componentsFile = File(p.join(twinDir.path, 'components.html'));
      final ids = findSpecimens(componentsFile.readAsStringSync()).map((s) => s.id).toSet();

      final markerIds = RegExp(r'<!--\s*utopia-specimen:\s*([a-z0-9-]+)')
          .allMatches(File(p.join(twinDir.path, 'gallery.src.html')).readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();

      expect(markerIds, isNotEmpty);
      expect(markerIds.difference(ids), isEmpty);
    });
  });

  group('buildSectionScaffold', () {
    const component = ScaffoldComponent(
      id: 'switch-field',
      index: 27,
      description: 'A titled row pairing a label with a UtopiaSwitch.',
      states: ['disabled', 'readOnly'],
    );

    test('frames the section the way components.html spells it', () {
      final scaffold = buildSectionScaffold(component);

      expect(scaffold, contains('<!-- data-utopia-id="switch-field" - manifest index 27 -->'));
      expect(scaffold, contains('    <section class="twin-section" data-utopia-id="switch-field">'));
      expect(scaffold, contains('<h2 class="twin-section__name">Switch field</h2>'));
      expect(scaffold, contains('        A titled row pairing a label with a UtopiaSwitch.'));
    });

    test('emits one stub per manifest state, with the state class components.css uses', () {
      final scaffold = buildSectionScaffold(component);

      expect(scaffold, contains('<span class="twin-specimen__label">Default</span>'));
      expect(scaffold, contains('<span class="twin-specimen__label">disabled (.is-disabled)</span>'));
      // readOnly -> .is-readonly, matching the class components.css already
      // carries (not .is-read-only).
      expect(scaffold, contains('<span class="twin-specimen__label">readOnly (.is-readonly)</span>'));
    });

    test('reminds the maintainer of the literals rule and that markup stays hand-authored', () {
      final scaffold = buildSectionScaffold(component);

      expect(scaffold, contains('utopia-literal-ok'));
      expect(scaffold, contains('SPEC 4.5'));
      expect(scaffold, contains('TODO'));
    });

    test('escapes a description that would otherwise open an element', () {
      final scaffold = buildSectionScaffold(
        const ScaffoldComponent(id: 'x', index: 0, description: 'Wraps <b> & closes it'),
      );

      expect(scaffold, contains('Wraps &lt;b&gt; &amp; closes it'));
    });

    test('parseScaffoldComponents keeps manifest order and tolerates a stateless component', () {
      final components = parseScaffoldComponents(
        jsonDecode('''
{"components": [
  {"id": "button", "description": "d", "states": ["loading"]},
  {"id": "card", "description": "d"}
]}''') as Map<String, dynamic>,
      );

      expect(components.map((c) => c.id).toList(), ['button', 'card']);
      expect(components.map((c) => c.index).toList(), [0, 1]);
      expect(components.last.states, isEmpty);
    });
  });

  group('CLI level (real bin/generate_twin.dart)', () {
    Future<ProcessResult> runTool(List<String> args) => Process.run('dart', [
      'run',
      p.join(Directory.current.path, 'bin', 'generate_twin.dart'),
      ...args,
    ], workingDirectory: Directory.current.path);

    test('--scaffold prints the section to stdout and writes nothing', () async {
      final result = await runTool(['--scaffold', 'ghost-button']);

      expect(result.exitCode, 0, reason: 'stderr: ${result.stderr}');
      final out = result.stdout as String;
      expect(out, contains('<section class="twin-section" data-utopia-id="ghost-button">'));
      expect(out, contains('<h2 class="twin-section__name">Ghost button</h2>'));

      // The twin is untouched: the scaffold is a stdout-only surface, and
      // components.html/components.css are never generated (the rejected
      // "fully generated twin" hypothesis).
      final componentsFile = File(p.join(repoRoot.path, 'twin', 'components.html'));
      final before = componentsFile.lastModifiedSync();
      await runTool(['--scaffold', 'ghost-button']);
      expect(componentsFile.lastModifiedSync(), before);
    });

    test('--scaffold with an unknown id exits 2 and lists the known ids', () async {
      final result = await runTool(['--scaffold', 'ghost-buttons']);

      expect(result.exitCode, 2);
      expect(result.stderr, contains('unknown component id "ghost-buttons"'));
      expect(result.stderr, contains('ghost-button'));
    });

    test('--compose-gallery writes gallery.html into the twin dir it is pointed at', () async {
      final scratch = Directory.systemTemp.createTempSync('compose_gallery_');
      addTearDown(() => scratch.deleteSync(recursive: true));
      File(p.join(scratch.path, 'components.html')).writeAsStringSync(componentsHtml);
      File(p.join(scratch.path, 'gallery.src.html')).writeAsStringSync('<main>\n  <!-- utopia-specimen: button -->\n</main>\n');

      final result = await runTool(['--compose-gallery', '-o', scratch.path]);

      expect(result.exitCode, 0, reason: 'stderr: ${result.stderr}');
      final gallery = File(p.join(scratch.path, 'gallery.html')).readAsStringSync();
      expect(gallery, contains('COMPOSED by utopia_design_tools:generate_twin'));
      expect(gallery, contains('Save changes'));
    });

    test('--compose-gallery without a source skeleton exits 1 and says what it wanted', () async {
      final scratch = Directory.systemTemp.createTempSync('compose_gallery_missing_');
      addTearDown(() => scratch.deleteSync(recursive: true));

      final result = await runTool(['--compose-gallery', '-o', scratch.path]);

      expect(result.exitCode, 1);
      expect(result.stderr, contains('gallery.src.html'));
    });

    test('a bad marker leaves the existing gallery.html untouched and exits 1', () async {
      final scratch = Directory.systemTemp.createTempSync('compose_gallery_bad_');
      addTearDown(() => scratch.deleteSync(recursive: true));
      File(p.join(scratch.path, 'components.html')).writeAsStringSync(componentsHtml);
      File(p.join(scratch.path, 'gallery.src.html')).writeAsStringSync('<!-- utopia-specimen: nope -->\n');
      final galleryFile = File(p.join(scratch.path, 'gallery.html'))..writeAsStringSync('previous\n');

      final result = await runTool(['--compose-gallery', '-o', scratch.path]);

      expect(result.exitCode, 1);
      expect(result.stderr, contains('unknown specimen id "nope"'));
      expect(galleryFile.readAsStringSync(), 'previous\n');
    });

    test('--scaffold and --compose-gallery together are refused', () async {
      final result = await runTool(['--scaffold', 'button', '--compose-gallery']);

      expect(result.exitCode, 2);
      expect(result.stderr, contains('one at a time'));
    });
  });
}
