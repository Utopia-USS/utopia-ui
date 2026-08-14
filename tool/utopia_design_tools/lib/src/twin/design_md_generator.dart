/// Renders the GENERATED YAML front matter of `twin/DESIGN.md` (protocol SPEC
/// section 4.6) from a parsed [TokenDocument], and splices it into an existing
/// `DESIGN.md` file without touching the hand-authored body.
///
/// `DESIGN.md` follows the design.md spec shape: a YAML front matter block
/// between `---` markers (name, colors, typography, rounded, spacing), all
/// GENERATED from the token document, followed by the 8 canonical prose
/// sections. Regeneration replaces ONLY the front matter block; the body -
/// including any hand edits made after the skeleton was first written - is
/// preserved byte-for-byte.
library;

import 'package:utopia_design_tools/src/dtcg/token_document.dart';
import 'package:utopia_design_tools/src/twin/css_generator.dart' show serializeColor;

/// Builds the GENERATED front matter block text (without the surrounding
/// `---` markers) for [document].
String buildFrontMatterBody(TokenDocument document) {
  final buffer = StringBuffer();
  buffer.writeln('name: Utopia');

  buffer.writeln('colors:');
  final colorGroup = document.root.children['color'];
  if (colorGroup != null) {
    for (final entry in colorGroup.children.entries) {
      final node = entry.value;
      final value = _resolvedValue(document, node);
      buffer.writeln('  ${entry.key}: ${_yamlString(serializeColor((value as Map).cast<String, dynamic>()))}');
    }
  }

  buffer.writeln('typography:');
  final textStyleGroup = document.root.children['textStyle'];
  if (textStyleGroup != null) {
    for (final entry in textStyleGroup.children.entries) {
      final role = entry.key;
      final node = entry.value;
      final value = _resolvedValue(document, node) as Map;
      final fontFamilyRaw = value['fontFamily'];
      final fontFamily = fontFamilyRaw is List ? fontFamilyRaw.join(', ') : fontFamilyRaw as String;
      final fontSize = (value['fontSize'] as Map)['value'] as num;
      final fontWeight = value['fontWeight'] as num;
      buffer.writeln('  $role:');
      buffer.writeln('    fontFamily: ${_yamlString(fontFamily)}');
      buffer.writeln('    fontSize: ${_yamlString('${_formatNum(fontSize)}px')}');
      buffer.writeln('    fontWeight: ${_formatNum(fontWeight)}');
    }
  }

  buffer.writeln('rounded:');
  final radiusGroup = document.root.children['radius'];
  if (radiusGroup != null) {
    for (final entry in radiusGroup.children.entries) {
      final node = entry.value;
      final value = _resolvedValue(document, node) as Map;
      final px = value['value'] as num;
      buffer.writeln('  ${entry.key}: ${_yamlString('${_formatNum(px)}px')}');
    }
  }

  buffer.writeln('spacing:');
  final spacingGroup = document.root.children['spacing'];
  if (spacingGroup != null) {
    for (final entry in spacingGroup.children.entries) {
      final node = entry.value;
      final value = _resolvedValue(document, node) as Map;
      final px = value['value'] as num;
      buffer.writeln('  ${entry.key}: ${_yamlString('${_formatNum(px)}px')}');
    }
  }

  return buffer.toString();
}

dynamic _resolvedValue(TokenDocument document, TokenNode node) {
  final aliasPath = aliasPathOf(node.value);
  if (aliasPath == null) {
    return node.value;
  }
  return resolveAlias(document, aliasPath).terminal!.value;
}

String _formatNum(num value) {
  final asDouble = value.toDouble();
  if (asDouble == asDouble.roundToDouble() && asDouble.isFinite) {
    return asDouble.toInt().toString();
  }
  return asDouble.toString();
}

/// Renders [value] as a YAML double-quoted scalar, escaping backslashes and
/// double quotes (values here are always simple hex/px/name strings, so this
/// is deliberately minimal rather than a general YAML string emitter).
String _yamlString(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

/// The hand-authored skeleton body written after the front matter the first
/// time `DESIGN.md` is generated (protocol SPEC 4.6: the 8 canonical sections,
/// in order). One tier-1 component per line in Components, each pointing at
/// its `data-utopia-id` anchor in `components.html` (created by A5).
const String designMdSkeletonBody = '''
## Overview

Utopia is a themeable, general-purpose design system for internal tools and admin surfaces:
tables, forms, dialogs and sidebar navigation built on one token scale. Every visual constant a
component reads - color, spacing, radius, shadow, type - comes from the token document above;
nothing is hardcoded in a widget. Rebranding a Utopia app is a matter of editing tokens and
regenerating, not hunting for scattered literals.

## Colors

The palette is small and semantic rather than a raw swatch ramp: `primary`/`accent` carry the
brand hue, `surface`/`canvas`/`field` are the three background layers (card, page, input), `text`
and `hint` are the two foreground tones, and `border`/`divider`/`rowAlt`/`hover` are the
low-contrast structural colors that separate content without competing with it. `error` and
`disabled` communicate state; the `onColored*` family exists purely for content painted on top of
a `primary`-colored surface (a filled button's label, for example) and is not meant for standalone
use. `chipBackground`/`chipForeground` are the one deliberately duotone pairing in the system,
reserved for `UtopiaChip`.

## Typography

Every text role (`header`, `title`, `text`, `label`, `caption`, `button`) is a complete, fixed
`fontFamily` + `fontSize` + `fontWeight` + `letterSpacing` bundle plus its own paired color - there
is no separate color override per usage site. Roles are chosen by what the text *is*, not by what
it looks like: `header` names a page or section (24px, 700), `title` names a card or list item
(16px, 600), `text` is body copy (12px, 500), `label` (12px, 600) and `caption` (10px, 500) are
secondary/microcopy, and `button` (12px, 600) is reserved for interactive labels. The whole scale
ships in one type family (Sora) so a rebrand only ever needs to swap the family name, not
re-balance six independent styles.

Tracking is a function of type size, not of role: it falls monotonically as the size grows, from 0
at `caption` (10px) to -0.5px at `header` (24px). Roles that share a `fontSize` share a
`letterSpacing` and separate on weight and color instead - hierarchy comes from weight, not from
spacing the letters out. The values are calibrated for Sora, which carries roughly 0.06 em more
built-in sidebearing than SF Pro or Inter, which is why no role tracks positive.

## Layout

All spacing and sizing derives from one base unit (`x`, 4 logical pixels by default) via the
`spacing` scale (`xxs` through `xxxl`); components never hardcode a gap or padding value that
does not trace back to a step on this scale. `theme.fieldContentPadding`, `theme.fieldMinHeight`,
`theme.pageTopPadding` and `theme.tileHeight` are semantic slots layered on top of the raw scale -
each is a design decision about *which* step controls a given surface, not a new unit of measure.
Breakpoints (`tablet`, `web`, `sidebar`) drive `UtopiaPageWrapper`/`UtopiaPageType`, the single
responsive system every page and dialog shares.

## Elevation & Depth

Three shadow steps (`sm`, `md`, `lg`) express elevation as a discrete, closed scale rather than
free-form blur/spread tuning per component: `sm` lifts a resting card off the canvas, `md` lifts a
hovering or dragged element, and `lg` is reserved for the highest layer (an open dialog or menu).
Depth also comes from flat surface layering (`canvas` -> `surface` -> `field`) and hairline borders
(`border.hairline`/`thin`/`thick`), which read as structure without needing a shadow at all - most
static content sits flush and uses only a border.

## Shapes

Corner radius is a five-step scale (`radius.xs` through `radius.xl`, plus `radius.full` for
fully-rounded pills and avatars) rather than a per-component constant. `theme.borderRadius` and
`theme.cardRadius` bind specific steps to the two most common shape decisions in the system
(controls vs. cards); a rebrand that wants sharper or rounder corners edits those two slots (or the
scale itself) instead of hunting through component source for a hardcoded radius.

## Components

One line per tier-1 component; anchors point at `data-utopia-id` on the component's root in
`components.html` (added by A5's HTML twin build-out).

- Button - `data-utopia-id="button"`
- Ghost button - `data-utopia-id="ghost-button"`
- Remove icon button - `data-utopia-id="remove-icon-button"`
- Card - `data-utopia-id="card"`
- Chip - `data-utopia-id="chip"`
- Chip list - `data-utopia-id="chip-list"`
- Check row - `data-utopia-id="check-row"`
- Switch - `data-utopia-id="switch"`
- Switch field - `data-utopia-id="switch-field"`
- Text field - `data-utopia-id="text-field"`
- Search field - `data-utopia-id="search-field"`
- Field wrapper - `data-utopia-id="field-wrapper"`
- Labeled field - `data-utopia-id="labeled-field"`
- Dropdown field - `data-utopia-id="dropdown-field"`
- Date picker - `data-utopia-id="date-picker"`
- Loader - `data-utopia-id="loader"`
- Three bounce - `data-utopia-id="three-bounce"`
- Mock loading box - `data-utopia-id="mock-loading-box"`
- Divider - `data-utopia-id="divider"`
- Card gradient background - `data-utopia-id="gradient-background"`
- Header - `data-utopia-id="header"`
- Title - `data-utopia-id="title"`
- Copyable text - `data-utopia-id="copyable-text"`
- Dialog - `data-utopia-id="dialog"`
- Confirm dialog - `data-utopia-id="confirm-dialog"`
- Table - `data-utopia-id="table"`
- Table empty state - `data-utopia-id="table-empty"`
- Table search panel - `data-utopia-id="table-search-panel"`
- Sidebar - `data-utopia-id="sidebar"`

The manifest ids missing from that list are deliberate, not an oversight: each is a
pure-behavior widget with no visual contract of its own, carried in `components.html` as a
"no visual twin" note entry (SPEC 4.4) and recorded here with its reason.

<!-- utopia-twin-omit: collapsible -- pure animation behavior; renders whatever child it is given -->
<!-- utopia-twin-omit: form-layout -- scroll-plus-pinned-bottom layout shell; its rendered shape is the dialog's -->
<!-- utopia-twin-omit: multi-widget -- pure composition helper, nothing rendered -->
<!-- utopia-twin-omit: overlay-anchor -- anchoring/positioning behavior; the popup chrome it anchors is the card recipe -->
<!-- utopia-twin-omit: page-wrapper -- pure layout-resolution behavior, nothing rendered -->

## Do's and Don'ts

- Do read every visual value from a `--utopia-*` token or a component's own token-driven class;
  don't hardcode a hex color, a raw `px` value that matches an existing token, or a bespoke font
  weight in `components.css` (the literals linter in `validate_twin` enforces this).
- Do treat a semantic slot (`theme.borderRadius`, `theme.cardRadius`, ...) as the thing to edit for
  a design decision; don't invent a parallel one-off radius or padding next to it.
- Do keep the twin markup free of a framework or a build step; don't add JS beyond small,
  optional interaction affordances (the gallery must open as static files in a browser).
- Do treat `color.divider` as optional and derive a contrast-safe fallback at paint time when it is
  absent; don't invent a concrete literal for it in generated output.
- Don't reintroduce a client project's name, brand assets or copy anywhere in this file or the
  twin bundle - this is a public, general-purpose design system.
''';

/// Result of [spliceDesignMd]: the new file text (`content`), plus a
/// `warning` when a fallback path rebuilt or recovered the body instead of a
/// clean splice (callers surface it on stderr so silent-data-loss scenarios
/// stay visible).
typedef DesignMdSplice = ({String content, String? warning});

/// Splices GENERATED front matter into [existingContent] (the current
/// `DESIGN.md` text, or `null` when the file does not exist yet), replacing
/// only the block between the first pair of `---` markers and leaving
/// everything else - including the body - byte-for-byte untouched. When
/// [existingContent] is `null`, returns front matter + [designMdSkeletonBody].
/// Every malformed-marker case fails SAFE: the existing text is preserved as
/// body, never discarded.
DesignMdSplice spliceDesignMd(String? existingContent, String frontMatterBody) {
  final frontMatterBlock = '---\n$frontMatterBody---\n';
  if (existingContent == null) {
    return (content: '$frontMatterBlock\n$designMdSkeletonBody', warning: null);
  }

  final markerPattern = RegExp(r'^---\r?\n');
  final firstMatch = markerPattern.firstMatch(existingContent);
  if (firstMatch == null || firstMatch.start != 0) {
    // No existing front matter block: prepend one, keep the whole existing
    // file as the body (best-effort recovery from a hand-edited file that
    // dropped its markers).
    return (
      content: '$frontMatterBlock\n$existingContent',
      warning: 'DESIGN.md had no parseable front matter block; new front matter was prepended and the '
          'existing content kept as body - review the result',
    );
  }

  final closingPattern = RegExp(r'\r?\n---\r?\n');
  final closingMatch = closingPattern.firstMatch(existingContent.substring(firstMatch.end));
  if (closingMatch == null) {
    // Malformed: an opening marker with no closing marker. The text after the
    // opening marker may be a real hand-authored body whose closing marker
    // got lost - preserve it as body rather than discarding it.
    final remainder = existingContent.substring(firstMatch.end);
    return (
      content: '$frontMatterBlock\n$remainder',
      warning: 'DESIGN.md front matter had no closing "---" marker; the text after the opening marker was '
          'preserved as body - review the result (stale front-matter lines may now sit at the top of the body)',
    );
  }

  final bodyStart = firstMatch.end + closingMatch.end;
  final body = existingContent.substring(bodyStart);
  return (content: '$frontMatterBlock$body', warning: null);
}
