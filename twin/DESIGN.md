---
name: Utopia
colors:
  primary: "#536dfe"
  accent: "#536dfe"
  field: "#ededed"
  canvas: "#f5f5f5"
  error: "#ff5252"
  disabled: "#bdbdbd"
  text: "rgb(0 0 0 / 0.8667)"
  surface: "#ffffff"
  border: "#e8eaf0"
  rowAlt: "#f7f8fb"
  hover: "#eff1f8"
  chipBackground: "#e7eafd"
  chipForeground: "#536dfe"
  hint: "#9aa0b5"
  onColoredContent: "rgb(255 255 255 / 0.851)"
  onColoredSelected: "rgb(255 255 255 / 0.1804)"
  onColoredHover: "rgb(255 255 255 / 0.0784)"
typography:
  header:
    fontFamily: "Sora"
    fontSize: "24px"
    fontWeight: 600
  label:
    fontFamily: "Sora"
    fontSize: "12px"
    fontWeight: 600
  text:
    fontFamily: "Sora"
    fontSize: "12px"
    fontWeight: 600
  title:
    fontFamily: "Sora"
    fontSize: "16px"
    fontWeight: 600
  caption:
    fontFamily: "Sora"
    fontSize: "10px"
    fontWeight: 600
  button:
    fontFamily: "Sora"
    fontSize: "12px"
    fontWeight: 600
rounded:
  xs: "4px"
  sm: "6px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  full: "9999px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
  xxxl: "48px"
---

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
it looks like: `header` names a page or section, `title` names a card or list item, `text` is body
copy, `label` and `caption` are secondary/microcopy, and `button` is reserved for interactive
labels. The whole scale ships in one weight family (Sora) so a rebrand only ever needs to swap the
family name, not re-balance six independent styles.

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
