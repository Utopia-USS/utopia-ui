/// The two forward-looking `validate_twin` gates that report drift without
/// blocking a build: gallery/DESIGN.md coverage of the manifest's components
/// (gate 5) and parity between a component's manifest `states[]` and the
/// `.is-*` classes its twin actually carries (gate 6).
///
/// Both gates emit WARNINGs only. They describe surfaces the protocol calls
/// SHOULD rather than MUST (SPEC 4.4: "Every manifest component SHOULD have a
/// twin section"; SPEC 4.6: the tier-1 list lives in hand-curated prose), so a
/// twin that lags the manifest stays visible on every run without failing the
/// gate that guards generated output. `data-utopia-id` coverage of
/// `components.html` remains the hard, error-level contract and lives in
/// `TwinValidator` (gate 2).
///
/// An intentional gap is declared inline with an omit marker, whose grammar is
/// fixed:
///
/// ```html
/// <!-- utopia-twin-omit: <id> -- <reason> -->
/// ```
///
/// written as an HTML comment in `gallery.html` and as an HTML comment inside
/// the markdown of `DESIGN.md`. A marker silences the file it lives in (and
/// only that file); a marker naming an id the manifest does not have is itself
/// reported as a dead omit.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli/output.dart';
import 'section_scaffold.dart';

/// Runs the coverage (gate 5) and state-parity (gate 6) checks over a twin
/// bundle. Both are warning-only and each half is skipped when the file it
/// reads is absent, so a generated-only twin (RFC-B5 auto-partial mode, no
/// `components.html`/`gallery.html`/`DESIGN.md`) reports nothing rather than
/// reporting everything as missing.
class TwinCoverageGates {
  /// Creates the gates for [twinDir], bound to the resolved manifest's
  /// component ids and their declared states.
  const TwinCoverageGates({
    required this.twinDir,
    required this.manifestComponentIds,
    required this.manifestComponentStates,
  });

  /// The `twin/` directory being validated.
  final Directory twinDir;

  /// Every component id declared in the resolved manifest.
  final Set<String> manifestComponentIds;

  /// The manifest's `states[]` per component id (components declaring no
  /// states may be absent from the map or map to an empty list; both are
  /// treated the same and skip gate 6).
  final Map<String, List<String>> manifestComponentStates;

  /// Gate 5: every manifest component id should appear in `gallery.html` and
  /// on `DESIGN.md`'s tier-1 list, or carry an omit marker in that file.
  List<Finding> checkForwardCoverage() {
    final findings = <Finding>[];

    final galleryFile = File(p.join(twinDir.path, 'gallery.html'));
    if (galleryFile.existsSync()) {
      final text = galleryFile.readAsStringSync();
      findings.addAll(
        _coverageFindings(
          file: galleryFile,
          text: text,
          covered: _idsReferencedInHtml(text),
          missingMessage: (id) =>
              'twin coverage: manifest component "$id" has no specimen in gallery.html - add one, or declare '
              'the gap with an omit marker (<!-- utopia-twin-omit: $id -- <reason> -->)',
        ),
      );
    }

    final designMdFile = File(p.join(twinDir.path, 'DESIGN.md'));
    if (designMdFile.existsSync()) {
      final text = designMdFile.readAsStringSync();
      final tierOne = _tierOneSection(text);
      if (tierOne == null) {
        findings.add(
          Finding.warning(
            _relativePath(designMdFile),
            'twin coverage: no "## Components" section - the tier-1 list check was skipped (SPEC 4.6 lists it '
            'among the 8 canonical sections)',
          ),
        );
      } else {
        findings.addAll(
          _coverageFindings(
            file: designMdFile,
            text: text,
            covered: _idsListedInTierOne(tierOne),
            missingMessage: (id) =>
                'twin coverage: manifest component "$id" is missing from the tier-1 list in DESIGN.md - add a '
                '"## Components" entry, or declare the gap with an omit marker '
                '(<!-- utopia-twin-omit: $id -- <reason> -->)',
          ),
        );
      }
    }

    return findings;
  }

  /// Gate 6: for every component declaring `states[]`, the manifest's states
  /// and the `.is-*` classes its twin carries must describe the same set -
  /// reported in both directions (a manifest state with no class, and a class
  /// with no manifest state).
  ///
  /// The twin-side set is the union of the `.is-*` classes attributed to the
  /// component inside its own `<section data-utopia-id="...">` in
  /// `components.html` (see [_stateClassesInHtml]) and the ones defined for it
  /// in `components.css` (see [_stateClassesByComponent]). Both halves
  /// attribute a class through the `utopia-<id>` class sharing its element /
  /// compound selector, so a nested component's states never count as the
  /// enclosing one's.
  List<Finding> checkStateParity() {
    final componentsHtmlFile = File(p.join(twinDir.path, 'components.html'));
    final componentsCssFile = File(p.join(twinDir.path, 'components.css'));
    if (!componentsHtmlFile.existsSync() && !componentsCssFile.existsSync()) {
      return const [];
    }

    final sections = componentsHtmlFile.existsSync()
        ? _sectionsById(componentsHtmlFile.readAsStringSync())
        : const <String, String>{};
    final cssStates = componentsCssFile.existsSync()
        ? _stateClassesByComponent(componentsCssFile.readAsStringSync())
        : const <String, Set<String>>{};

    final findings = <Finding>[];
    for (final id in _sortedManifestIds) {
      final states = manifestComponentStates[id] ?? const <String>[];
      if (states.isEmpty) continue;

      final section = sections[id];
      final twinStates = <String>{
        if (section != null) ..._stateClassesInHtml(section, sectionId: id),
        ...?cssStates[id],
      };

      // Both sides are compared through [_normalizeStateName], which folds
      // away the spelling difference the two artifacts genuinely have today:
      // the manifest names states in camelCase (`readOnly`), the twin in a
      // CSS class (`.is-readonly`).
      final twinByKey = {for (final state in twinStates) _normalizeStateName(state): state};
      final manifestByKey = {for (final state in states) _normalizeStateName(state): state};

      for (final key in manifestByKey.keys.toList()..sort()) {
        if (twinByKey.containsKey(key)) continue;
        final state = manifestByKey[key]!;
        findings.add(
          Finding.warning(
            id,
            'state drift: manifest state "$state" has no .is-* class in the twin - add ${twinStateClass(state)} to '
            'the components.html section or components.css, or drop the state from the manifest',
          ),
        );
      }
      for (final key in twinByKey.keys.toList()..sort()) {
        if (manifestByKey.containsKey(key)) continue;
        findings.add(
          Finding.warning(
            id,
            "state drift: .is-${twinByKey[key]} in the twin has no matching entry in the manifest's states[] - "
            'rename the class or declare the state',
          ),
        );
      }
    }
    return findings;
  }

  // --- gate 5 helpers ---

  List<String> get _sortedManifestIds => manifestComponentIds.toList()..sort();

  String _relativePath(File file) => p.relative(file.path, from: twinDir.parent.path);

  /// Turns one file's covered-id set into findings: one per missing id, one per
  /// dead or unparseable omit marker, and a covered/omitted/missing summary.
  ///
  /// The summary is emitted only when something is actually MISSING - a
  /// declared omission is documented, not a finding, so a twin whose every gap
  /// carries an omit marker stays silent no matter how many markers it has
  /// (SPEC 4.1 scopes this gate's warnings to "missing ids WITHOUT one"). A
  /// twin that tracks the manifest exactly stays silent for the same reason,
  /// like every other gate here. Dead and unparseable markers still report on
  /// their own: those are broken markers, not declared gaps.
  List<Finding> _coverageFindings({
    required File file,
    required String text,
    required Set<String> covered,
    required String Function(String id) missingMessage,
  }) {
    final path = _relativePath(file);
    final markers = _parseOmitMarkers(text);
    final findings = <Finding>[];

    var coveredCount = 0;
    var omittedCount = 0;
    final missing = <String>[];
    for (final id in _sortedManifestIds) {
      if (covered.contains(id)) {
        coveredCount++;
      } else if (markers.ids.contains(id)) {
        omittedCount++;
      } else {
        missing.add(id);
      }
    }

    for (final id in missing) {
      findings.add(Finding.warning(path, missingMessage(id)));
    }
    final dead = markers.ids.where((id) => !manifestComponentIds.contains(id)).toList()..sort();
    for (final id in dead) {
      findings.add(
        Finding.warning(
          path,
          'twin coverage: omit marker names "$id", which is not a manifest component id (dead omit - fix the id '
          'or remove the marker)',
        ),
      );
    }
    for (final raw in markers.malformed) {
      findings.add(
        Finding.warning(
          path,
          'twin coverage: unparseable omit marker "utopia-twin-omit:$raw" - the grammar is '
          '`utopia-twin-omit: <id> -- <reason>`',
        ),
      );
    }

    if (missing.isNotEmpty) {
      findings.add(
        Finding.warning(
          path,
          'twin coverage: $coveredCount covered, $omittedCount omitted, ${missing.length} missing '
          '(of ${manifestComponentIds.length} manifest components)',
        ),
      );
    }
    return findings;
  }

  /// Matches `data-utopia-id` in either quoting style, mirroring gate 2's
  /// reader (including its raw-text scan: an id named in a comment counts, the
  /// same way it already does for the id-coverage gate).
  static final RegExp _dataUtopiaIdAttr = RegExp(r'''data-utopia-id=("|')([a-z0-9-]+)\1''');

  /// A `class="..."` / `class='...'` attribute, capturing its token list.
  static final RegExp _classAttr = RegExp(r'''class\s*=\s*("|')([^"']*)\1''');

  /// An element `id="..."` or a fragment link `href="#..."`, the two ways a
  /// gallery specimen names a component without repeating `data-utopia-id`.
  static final RegExp _anchorRef = RegExp(r'''\bid=("|')([a-z0-9-]+)\1|href=("|')#([a-z0-9-]+)\3''');

  /// The manifest ids a gallery-style HTML file references: through
  /// `data-utopia-id`, through a component's own `utopia-<id>` class on a
  /// specimen root, or through an element id / fragment anchor naming it.
  ///
  /// Deliberately structural rather than textual: a bare word in prose
  /// ("a header row", `<title>`) must not count as coverage, or generically
  /// named components (`header`, `title`, `card`, `table`) would report as
  /// covered by any page that merely mentions them.
  Set<String> _idsReferencedInHtml(String html) {
    final ids = <String>{};
    for (final match in _dataUtopiaIdAttr.allMatches(html)) {
      final id = match.group(2)!;
      if (manifestComponentIds.contains(id)) ids.add(id);
    }
    for (final match in _classAttr.allMatches(html)) {
      for (final token in match.group(2)!.split(RegExp(r'\s+'))) {
        final owner = _ownerOfUtopiaClass(token);
        if (owner != null) ids.add(owner);
      }
    }
    for (final match in _anchorRef.allMatches(html)) {
      final id = match.group(2) ?? match.group(4)!;
      if (manifestComponentIds.contains(id)) ids.add(id);
    }
    return ids;
  }

  /// The `## Components` section of a `DESIGN.md` (heading excluded, up to the
  /// next `##` heading or the end of file), or `null` when the document has no
  /// such section.
  static String? _tierOneSection(String markdown) {
    final heading = RegExp(r'^##[ \t]+Components[ \t]*$', multiLine: true).firstMatch(markdown);
    if (heading == null) return null;
    final rest = markdown.substring(heading.end);
    final next = RegExp(r'^##[ \t]', multiLine: true).firstMatch(rest);
    return next == null ? rest : rest.substring(0, next.start);
  }

  /// A backtick code span, the way a tier-1 list names a component
  /// (`` `data-utopia-id="button"` ``, or a bare `` `button` ``).
  static final RegExp _codeSpan = RegExp('`([^`]+)`');

  /// The manifest ids named on a tier-1 list [section]: through a
  /// `data-utopia-id="..."` reference or a bare backticked id. Prose outside a
  /// code span never counts, for the same reason [_idsReferencedInHtml] stays
  /// structural.
  Set<String> _idsListedInTierOne(String section) {
    final ids = <String>{};
    for (final match in _dataUtopiaIdAttr.allMatches(section)) {
      final id = match.group(2)!;
      if (manifestComponentIds.contains(id)) ids.add(id);
    }
    for (final match in _codeSpan.allMatches(section)) {
      final content = match.group(1)!.trim();
      if (manifestComponentIds.contains(content)) ids.add(content);
    }
    return ids;
  }

  /// An omit marker's payload: everything after `utopia-twin-omit:` up to the
  /// end of the line (the comment terminator is stripped in
  /// [_parseOmitMarkers]).
  static final RegExp _omitMarker = RegExp(r'utopia-twin-omit:([^\n]*)');

  /// The pinned marker grammar's body: `<id> -- <reason>`, with a non-empty
  /// reason. The whitespace before `--` is what keeps the (kebab-case) id from
  /// swallowing the separator.
  static final RegExp _omitMarkerBody = RegExp(r'^\s*([a-z0-9][a-z0-9-]*)\s+--\s*(\S.*)$');

  /// Parses every `utopia-twin-omit:` marker in [text], returning the ids they
  /// name and the raw payloads that do not parse (reported as malformed rather
  /// than silently ignored - a marker that does not parse silences nothing).
  static ({Set<String> ids, List<String> malformed}) _parseOmitMarkers(String text) {
    final ids = <String>{};
    final malformed = <String>[];
    for (final match in _omitMarker.allMatches(text)) {
      var payload = match.group(1)!;
      // `<!-- utopia-twin-omit: id -- reason -->`: the comment terminator is
      // punctuation of the host syntax, not part of the reason.
      final terminator = payload.indexOf('-->');
      if (terminator != -1) payload = payload.substring(0, terminator);
      final body = _omitMarkerBody.firstMatch(payload);
      if (body == null) {
        malformed.add(match.group(1)!.trimRight());
      } else {
        ids.add(body.group(1)!);
      }
    }
    return (ids: ids, malformed: malformed);
  }

  // --- gate 6 helpers ---

  /// A `<section ...>` opening tag or a `</section>` closing tag.
  static final RegExp _sectionTag = RegExp(r'<section\b[^>]*>|</section\s*>', caseSensitive: false);

  /// Splits `components.html` into one text span per top-level
  /// `<section data-utopia-id="...">`, tracking nesting so a specimen that
  /// contains its own `<section>` does not close the component's span early.
  /// A component appearing twice keeps the first span (the authoritative
  /// specimen section).
  static Map<String, String> _sectionsById(String html) {
    final sections = <String, String>{};
    var depth = 0;
    String? openId;
    var openStart = 0;
    for (final match in _sectionTag.allMatches(html)) {
      final tag = match.group(0)!;
      if (tag.startsWith('</')) {
        depth--;
        if (depth == 0 && openId != null) {
          sections.putIfAbsent(openId, () => html.substring(openStart, match.start));
          openId = null;
        }
        if (depth < 0) depth = 0;
        continue;
      }
      if (depth == 0) {
        openId = _dataUtopiaIdAttr.firstMatch(tag)?.group(2);
        openStart = match.end;
      }
      depth++;
    }
    return sections;
  }

  /// The `.is-*` state names (without the `is-` prefix) that one component's
  /// `components.html` section attributes to [sectionId] itself.
  ///
  /// Attribution is per `class` attribute, not per section: a `.is-*` class
  /// counts for [sectionId] only when the SAME attribute also carries a
  /// `utopia-<id>` class resolving to it (longest matching id wins, the same
  /// rule the CSS half applies in [_ownerOfUtopiaClass]). Without that, a
  /// composite component would inherit the states of the components nested
  /// inside its specimens - `switch-field`, whose specimens wrap a
  /// `<span class="utopia-switch is-on">`, would report `.is-on` as its own.
  ///
  /// An element carrying no `utopia-*` class at all falls back to [sectionId]:
  /// that is the scaffold's stub markup and any plain wrapper a maintainer
  /// hand-wrote around a specimen, both of which belong to the section they
  /// sit in. An element whose `utopia-*` classes name no manifest component is
  /// unattributable and contributes nothing, exactly as in the CSS half.
  Set<String> _stateClassesInHtml(String section, {required String sectionId}) {
    final states = <String>{};
    for (final match in _classAttr.allMatches(section)) {
      final tokens = match.group(2)!.split(RegExp(r'\s+'));
      String? owner;
      var carriesUtopiaClass = false;
      for (final token in tokens) {
        if (!token.startsWith('utopia-')) continue;
        carriesUtopiaClass = true;
        final candidate = _ownerOfUtopiaClass(token);
        if (candidate == null) continue;
        if (owner == null || candidate.length > owner.length) owner = candidate;
      }
      if (owner == null && carriesUtopiaClass) continue;
      if ((owner ?? sectionId) != sectionId) continue;
      for (final token in tokens) {
        if (token.startsWith('is-') && token.length > 3) states.add(token.substring(3));
      }
    }
    return states;
  }

  /// A CSS comment span, stripped before selectors are read (a `.is-*` named
  /// in a rule's explanatory comment is prose, not a definition).
  static final RegExp _cssComment = RegExp(r'/\*[\s\S]*?\*/');

  /// A rule's prelude: everything up to its opening brace. Also matches an
  /// at-rule's prelude (`@media ...`), which simply carries no `.is-*` class
  /// and contributes nothing.
  static final RegExp _rulePrelude = RegExp(r'([^{}]*)\{');

  /// A `.is-<state>` class in a selector.
  static final RegExp _stateClassSelector = RegExp(r'\.is-([a-z0-9-]+)');

  /// A `.utopia-*` class in a selector.
  static final RegExp _utopiaClassSelector = RegExp(r'\.(utopia-[a-z0-9_-]+)');

  /// The `.is-*` state names defined per component in `components.css`.
  ///
  /// A state class is attributed to the component whose `utopia-<id>` class
  /// shares its compound selector (`.utopia-switch.is-readonly` -> `switch`,
  /// `.utopia-sidebar--gradient .utopia-sidebar-tile.is-selected` ->
  /// `sidebar`); when the compound carries no component class of its own
  /// (`.utopia-button.is-loading .utopia-button__dots`), the nearest preceding
  /// compound in the same selector owns it. A state class in a selector with
  /// no `utopia-*` class at all cannot be attributed and is ignored.
  Map<String, Set<String>> _stateClassesByComponent(String css) {
    final result = <String, Set<String>>{};
    final withoutComments = css.replaceAll(_cssComment, '');
    for (final rule in _rulePrelude.allMatches(withoutComments)) {
      for (final selector in rule.group(1)!.split(',')) {
        final compounds = selector.trim().split(RegExp(r'[\s>+~]+'));
        for (var i = 0; i < compounds.length; i++) {
          final states = _stateClassSelector.allMatches(compounds[i]).map((m) => m.group(1)!).toList();
          if (states.isEmpty) continue;
          final owner = _ownerOfCompoundChain(compounds, i);
          if (owner == null) continue;
          result.putIfAbsent(owner, () => <String>{}).addAll(states);
        }
      }
    }
    return result;
  }

  /// The component owning the state class in `compounds[index]`: the component
  /// named by a `utopia-*` class in that compound, else the one named by the
  /// nearest preceding compound of the same selector.
  String? _ownerOfCompoundChain(List<String> compounds, int index) {
    for (var i = index; i >= 0; i--) {
      for (final match in _utopiaClassSelector.allMatches(compounds[i])) {
        final owner = _ownerOfUtopiaClass(match.group(1)!);
        if (owner != null) return owner;
      }
    }
    return null;
  }

  /// The manifest component a `utopia-*` class belongs to: the id whose
  /// `utopia-<id>` form the class either equals or extends as a BEM
  /// element/modifier (`utopia-button__label`, `utopia-chip--accent`,
  /// `utopia-sidebar-tile`). The longest matching id wins, so
  /// `utopia-switch-field` resolves to `switch-field` rather than `switch`.
  /// Returns `null` for a class no manifest id claims.
  String? _ownerOfUtopiaClass(String classToken) {
    String? best;
    for (final id in manifestComponentIds) {
      final base = 'utopia-$id';
      final matches = classToken == base || classToken.startsWith('$base-') || classToken.startsWith('${base}__');
      if (!matches) continue;
      if (best == null || id.length > best.length) best = id;
    }
    return best;
  }

  /// The comparison key for a state name, folding away the one spelling
  /// difference the manifest and the twin genuinely have: the manifest writes
  /// states in camelCase (`readOnly`), the twin as a CSS class
  /// (`.is-readonly`, and `.is-read-only` for a kebab-cased spelling). Both
  /// sides normalize to lower case with `-`/`_` removed, so all three forms
  /// compare equal.
  static String _normalizeStateName(String state) =>
      state.toLowerCase().replaceAll('-', '').replaceAll('_', '');
}
