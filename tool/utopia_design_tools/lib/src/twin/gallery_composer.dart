/// Composes `twin/gallery.html` (protocol SPEC 4.1/4.4) from the
/// hand-authored `twin/gallery.src.html` skeleton plus the specimen subtrees
/// of `twin/components.html`.
///
/// The gallery mirrors the example app's Components page section for section,
/// and per the frozen H4 contract its specimens are DUPLICATES of the
/// components catalog's markup - historically maintained by hand-copying each
/// specimen between the two files, which is where the two surfaces drift
/// apart. The composer keeps the duplication (no build step, no JS includes:
/// the emitted gallery is still a plain static file) but removes the manual
/// copy: the source skeleton names a specimen with a marker comment and the
/// composer pastes that specimen's subtree in VERBATIM.
///
/// Marker grammar (a marker occupies its own line):
///
/// - `utopia-specimen: <id>` - replaced by the subtree of the first element
///   carrying `data-utopia-id="<id>"` in `components.html`.
/// - `utopia-specimen: <id> #<n>` - the same, selecting the n-th such element
///   (1-based, document order) when a component has several specimens.
/// - `utopia-twin-omit: <id> -- <reason>` - carried through untouched; records
///   a manifest id the gallery deliberately does not show.
///
/// This module never generates component markup or CSS: it only relocates
/// markup that a maintainer already hand-authored in `components.html`.
library;

import 'dart:convert';

/// One `data-utopia-id`-carrying element found in a twin HTML file: the id it
/// declares plus the exact source span of its subtree.
class TwinSpecimen {
  /// Creates a specimen span.
  const TwinSpecimen({
    required this.id,
    required this.tagName,
    required this.start,
    required this.end,
    required this.text,
  });

  /// The `data-utopia-id` value (a manifest component id).
  final String id;

  /// The lower-cased tag name of the specimen's root element.
  final String tagName;

  /// Offset of the root element's `<` in the source document.
  final int start;

  /// Offset just past the subtree's last character in the source document.
  final int end;

  /// The subtree's source text, exactly as written in the source document.
  final String text;
}

/// Finds every specimen element in [html]: elements carrying a
/// `data-utopia-id` attribute, in document order.
///
/// `<section>` elements are skipped: in `components.html` every component's
/// section root carries the same `data-utopia-id` as the specimens inside it
/// (SPEC 4.4), and a gallery marker always means "the specimen", never "the
/// whole catalog section with its heading and prose".
List<TwinSpecimen> findSpecimens(String html) {
  final tags = _scanTags(html);
  final specimens = <TwinSpecimen>[];
  for (var i = 0; i < tags.length; i++) {
    final tag = tags[i];
    if (tag.isClosing) continue;
    if (tag.name == 'section') continue;
    final id = _dataUtopiaId.firstMatch(html.substring(tag.start, tag.end))?.group(2);
    if (id == null) continue;
    final end = tag.isSelfContained ? tag.end : _findClosingTagEnd(tags, i);
    if (end == null) continue;
    specimens.add(
      TwinSpecimen(id: id, tagName: tag.name, start: tag.start, end: end, text: html.substring(tag.start, end)),
    );
  }
  return specimens;
}

/// Composes the gallery document from [source] (the `gallery.src.html`
/// skeleton) and [componentsHtml] (the specimen catalog).
///
/// Every marker line in [source] is replaced by the referenced specimen's
/// subtree, copied verbatim (its own indentation included - the two documents
/// nest specimens at the same depth). Everything else in [source] - the
/// prose, the section order, the page chrome, the omit markers - is carried
/// through byte-for-byte, preceded by the generated banner naming the two
/// inputs and the regeneration command.
///
/// Deterministic: the same two inputs always produce identical bytes.
///
/// Throws a [StateError] whose message names the source line when a marker is
/// malformed, names an id `componentsHtml` has no specimen for, or asks for an
/// occurrence index that component does not have.
String composeGallery({
  required String source,
  required String componentsHtml,
  String sourceName = 'gallery.src.html',
  String componentsName = 'components.html',
}) {
  final byId = <String, List<TwinSpecimen>>{};
  for (final specimen in findSpecimens(componentsHtml)) {
    byId.putIfAbsent(specimen.id, () => <TwinSpecimen>[]).add(specimen);
  }

  final lines = const LineSplitter().convert(source);
  final buffer = StringBuffer(_banner);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final match = _specimenMarker.firstMatch(line);
    if (match == null) {
      if (line.trimLeft().startsWith('<!--') && _looseSpecimenMarker.hasMatch(line) && !_omitMarker.hasMatch(line)) {
        throw StateError(
          '$sourceName:${i + 1}: malformed specimen marker - expected a line holding only '
          'an HTML comment of the form "utopia-specimen: <id>" or "utopia-specimen: <id> #<n>".',
        );
      }
      buffer.writeln(line);
      continue;
    }

    final id = match.group(2)!;
    final occurrence = int.parse(match.group(3) ?? '1');
    final candidates = byId[id];
    if (candidates == null) {
      throw StateError(
        '$sourceName:${i + 1}: unknown specimen id "$id" - $componentsName has no element with '
        'data-utopia-id="$id". Add the specimen there first (scaffold one with '
        'generate_twin --scaffold $id), or drop the marker.',
      );
    }
    if (occurrence < 1 || occurrence > candidates.length) {
      throw StateError(
        '$sourceName:${i + 1}: specimen "$id" #$occurrence does not exist - $componentsName carries '
        '${candidates.length} specimen(s) for that id.',
      );
    }
    // The subtree goes in byte-for-byte; only its first line is (re)indented,
    // to the marker's own indentation. The two documents nest specimens at
    // the same depth, so the continuation lines land aligned - and keeping
    // them untouched is what makes the paste verbatim rather than reformatted.
    buffer.writeln('${match.group(1)!}${candidates[occurrence - 1].text}');
  }
  return buffer.toString();
}

/// The generated banner every composed gallery starts with.
///
/// The marker keywords are named here without their `:` payload separator on
/// purpose: spelling a marker out in full would both close this HTML comment
/// early and hand `validate_twin`'s omit-marker parser a banner sentence to
/// parse as a real marker.
const String _banner = '''
<!--
  twin/gallery.html - COMPOSED by utopia_design_tools:generate_twin from
  twin/gallery.src.html + twin/components.html. Do not edit this file: edit
  twin/gallery.src.html (prose, section order, page chrome) or the specimen
  it points at in twin/components.html, then regenerate with

    dart run utopia_design_tools:generate_twin --compose-gallery

  Each utopia-specimen comment marker in the source is replaced here by that
  specimen's subtree, copied verbatim from components.html; each
  utopia-twin-omit marker is carried through as-is and records a manifest id
  this gallery deliberately does not show.
-->
''';

/// A whole-line specimen marker: leading indentation, an HTML comment holding
/// `utopia-specimen: <id>` with an optional `#<n>` occurrence selector, and
/// nothing else on the line.
final RegExp _specimenMarker = RegExp(r'^(\s*)<!--\s*utopia-specimen:\s*([a-z0-9-]+)\s*(?:#(\d+)\s*)?-->\s*$');

/// Any mention of the specimen keyword on a line that opens an HTML comment,
/// used to reject a marker the strict grammar did not accept instead of
/// silently emitting it as a comment. Scoped to comment-opening lines so the
/// source's own prose may still describe the grammar.
final RegExp _looseSpecimenMarker = RegExp(r'utopia-specimen\s*:');

/// The omit marker, carried through untouched (grammar shared with
/// `validate_twin`'s deliberate-omission gate).
final RegExp _omitMarker = RegExp(r'<!--\s*utopia-twin-omit:\s*([a-z0-9-]+)\s*--');

/// `data-utopia-id` in either quoting style, matching `TwinValidator`'s own
/// attribute pattern so the composer and the id-coverage gate always agree on
/// what counts as an id.
final RegExp _dataUtopiaId = RegExp(r'''data-utopia-id=("|')([a-z0-9-]+)\1''');

/// HTML elements that never carry a closing tag, so their subtree is the
/// start tag itself. Only the ones a twin specimen can be rooted at are
/// listed; the full void set is not needed and a shorter list keeps the
/// contract obvious.
const Set<String> _voidElements = {'hr', 'input', 'img', 'br', 'source', 'col'};

/// One scanned tag: its span in the document, its name, and whether it is a
/// closing tag / needs no closing tag at all.
class _Tag {
  const _Tag({
    required this.start,
    required this.end,
    required this.name,
    required this.isClosing,
    required this.isSelfContained,
  });

  final int start;
  final int end;
  final String name;
  final bool isClosing;

  /// Self-closing (`<hr />`) or a void element: the tag is its own subtree.
  final bool isSelfContained;
}

/// Scans [html] into its tags, skipping comments, doctypes and processing
/// instructions, and honouring quoted attribute values so a `>` inside an
/// attribute never ends a tag early.
List<_Tag> _scanTags(String html) {
  final tags = <_Tag>[];
  var i = 0;
  while (i < html.length) {
    final open = html.indexOf('<', i);
    if (open == -1) break;
    if (html.startsWith('<!--', open)) {
      final close = html.indexOf('-->', open + 4);
      i = close == -1 ? html.length : close + 3;
      continue;
    }
    if (html.startsWith('<!', open) || html.startsWith('<?', open)) {
      final close = html.indexOf('>', open);
      i = close == -1 ? html.length : close + 1;
      continue;
    }
    final isClosing = html.startsWith('</', open);
    final nameStart = open + (isClosing ? 2 : 1);
    final nameMatch = _tagName.matchAsPrefix(html, nameStart);
    if (nameMatch == null) {
      i = open + 1;
      continue;
    }
    final name = nameMatch.group(0)!.toLowerCase();
    var cursor = nameMatch.end;
    String? quote;
    while (cursor < html.length) {
      final char = html[cursor];
      if (quote != null) {
        if (char == quote) quote = null;
      } else if (char == '"' || char == "'") {
        quote = char;
      } else if (char == '>') {
        break;
      }
      cursor++;
    }
    if (cursor >= html.length) break;
    final selfClosing = cursor > 0 && html[cursor - 1] == '/';
    tags.add(
      _Tag(
        start: open,
        end: cursor + 1,
        name: name,
        isClosing: isClosing,
        isSelfContained: selfClosing || _voidElements.contains(name),
      ),
    );
    i = cursor + 1;
  }
  return tags;
}

final RegExp _tagName = RegExp('[A-Za-z][A-Za-z0-9-]*');

/// The end offset of the closing tag matching the opening tag at [openIndex]
/// in [tags], or `null` when the document never closes it.
int? _findClosingTagEnd(List<_Tag> tags, int openIndex) {
  final name = tags[openIndex].name;
  var depth = 1;
  for (var i = openIndex + 1; i < tags.length; i++) {
    final tag = tags[i];
    if (tag.name != name || tag.isSelfContained) continue;
    if (tag.isClosing) {
      depth--;
      if (depth == 0) return tag.end;
    } else {
      depth++;
    }
  }
  return null;
}
