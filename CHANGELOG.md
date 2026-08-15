# Unreleased

- **Breaking (visual):** `UtopiaThemeData.fieldDecoration` now carries the field's hairline
  border. It used to be fill + radius only, with `UtopiaFieldWrapper` adding the border on
  top; consumers that painted their own chrome with `context.fieldDecoration` will see the
  border appear. Five sibling getters join it - `fieldHoverDecoration`, `fieldFocusDecoration`,
  `fieldErrorDecoration`, `fieldErrorFocusDecoration` and `fieldReadOnlyDecoration` - so every
  field state resolves from the theme rather than from widget code.
- **Breaking (metrics):** a resting field and a resting `UtopiaButton` are now 48 logical
  pixels tall, down from 62 and 60 respectively - they were never equal, and the resting
  variant had no test pinning them. `fieldContentPadding` moves to `(x*2, x*1)` = (8, 4),
  `fieldMinHeight` to `x*8.5` = 34 (the raw constructor's default follows), and
  `UtopiaButton`'s default extent to `x*12` = 48. The dense variants are unchanged at 40.
  Layouts that hard-coded 60 or 62 need adjusting.
- Fields gained hover, focus and read-only chrome. `UtopiaFieldWrapper` observes pointer
  hover and descendant focus itself (precedence: read-only, error + focus, error, focus,
  hover, rest) and takes a new `readOnly` flag, which `UtopiaTextField` forwards. Every state
  keeps the same stroke width and paints its ring as an outward shadow, so no state change
  shifts layout.
- The floated field label is now `textStyles.caption` in the hint colour, pre-divided by
  Flutter's 0.75 floated-label scale so it lands at the themed size - it used to render at 9px
  in Flutter against the twin's 12px.
- `UtopiaButton`: the sub-perceptual white hover overlay is gone. Hover slides the whole
  gradient sweep half a step down the primary -> accent axis, press scales to 98%, and focus
  draws a solid primary ring with a gap. The `focus` state joins the manifest.
- New selection controls: `UtopiaCheckbox` (with an `indeterminate` rendering) and the
  generic `UtopiaRadio<T>`, both fully controlled and drawn from the tokens - a 20px box
  (radius 4) whose edge leads while empty and fills primary once it carries a value.
  `UtopiaCheckRow` no longer draws its own box: it composes a read-only `UtopiaCheckbox`,
  so its box moves from accent fill / radius 6 to primary fill / radius 4.
- `UtopiaTableEntry.numeric` declares a column as holding numbers: its cells and its own
  label align to the trailing edge and render with tabular figures. The example app's
  Amount column uses it.
- Table sort affordance: the sorted column states its direction with an accent caret
  (up ascending, down descending - descending used to light the ascending arrow); merely
  sortable columns fade a muted caret in on hover. The search panel sits on the column
  inset, so the search field's edge lines up with the column labels.
- `UtopiaDialog.form` rules its action bar off from the scrolling body with a hairline,
  and its dartdoc now recommends the right-aligned ghost + dense-confirm idiom for
  `bottom` (the example app and the twin specimen follow it). `UtopiaConfirmDialog` takes
  the overlay elevation (`dialogDecoration`) instead of the resting card elevation.
- Loading reads as activity in the brand colour: `UtopiaLoader` spins in `colors.primary`
  (the `color` override is unchanged), `UtopiaThreeBounce` defaults its dots to
  `colors.primary` (a null colour used to paint nothing at all), and `UtopiaMockLoadingBox`
  shimmers on the cool family - base `colors.hover`, sweep up to `colors.surface`.
- `UtopiaDropdownField`'s trigger is a real focus stop: tapping (or Tab plus Space/Enter)
  focuses it, so the shared field chrome rings while the popup is open.
- Manifest overlays: `text-field` and `search-field` declare the `hover` state; `loader`
  and `date-picker` declare none (a loader has no not-loading rendering, and the date
  picker's read-only trigger does not change while its calendar is up).
- HTML twin drift fixes: table cells and column labels carry the real cell inset and body
  type, the confirm dialog the real card radius (16) and overlay shadow, and the gallery's
  table specimen is composed from `components.html` instead of a hand-maintained copy.
- Protocol 0.3.0: manifest `tokenBindings` entries carry their provenance
  (`{ "path": ..., "origin": "source" | "overlay" }`) and every component the HTML twin
  renders carries its `twin` binding. `validate_manifest` can now verify a shipped manifest's
  bindings without the overlay directory the pub tarball does not ship, checks that a twin
  binding really targets a rendered section, and reports a newer or incompatible declared
  `schemaVersion`. Manifests written for protocol 0.2 (bare-string bindings) stay valid.
- Twin: `gallery.html` is now composed from the hand-authored `twin/gallery.src.html` plus
  verbatim specimens from `components.html` (`generate_twin --compose-gallery`, run by the
  default pass when the source file exists); `generate_twin --scaffold <id>` prints a
  components.html section skeleton for a manifest component. The gallery and the DESIGN.md
  tier-1 list catch up on `ghost-button` and `header`; deliberate omissions are recorded with
  `utopia-twin-omit` markers.
- `validate_twin`: three new gates - DESIGN.md front matter freshness (error), forward
  coverage of the gallery and the DESIGN.md tier-1 list against manifest ids (warnings,
  omit markers), and manifest `states[]` vs `.is-*` class parity (warnings).
- `generate_theme --check`: freshness gate for a consumer's generated theme file - compares
  an in-memory regeneration against the file on disk and exits 1 on drift, writing nothing.
- CI (GitHub Actions): RELEASING.md steps b and c run on every push/PR - artifacts are
  regenerated and byte-compared, validators and both test suites gate the merge.

# 0.1.0

Initial release - extracted from `utopia_cms_ui` 0.1.0 with the `Utopia` prefix.

- Theme system: `UtopiaTheme` (InheritedWidget), freezed `UtopiaThemeData` /
  `UtopiaThemeColors` / `UtopiaThemeTextStyles` token classes, `context.theme` /
  `context.colors` / `context.textStyles` / `context.fieldDecoration` extensions.
- Primitives: `UtopiaButton`, `UtopiaRemoveIconButton`, `UtopiaChip`, `UtopiaChipList`,
  `UtopiaCheckRow`, `UtopiaSwitch`, `UtopiaSwitchField`, `UtopiaTextField`,
  `UtopiaSearchField`, `UtopiaFieldWrapper`, `UtopiaLabeledField`, `UtopiaDropdownField`,
  `UtopiaOverlayAnchor`, `UtopiaDatePicker`, `UtopiaLoader`, `UtopiaMockLoadingBox`,
  `UtopiaThreeBounce`, `UtopiaDivider`, `UtopiaCard`, `UtopiaGradientBackground`,
  `UtopiaTitle`, `UtopiaCopyableText`, `UtopiaBreakpoints`, `UtopiaPageWrapper`.
- Table: `UtopiaTable<T>`, `UtopiaTableEntry<T>`, sort options, search panel, empty state,
  `useUtopiaTableState` hook.
- Dialogs: `UtopiaDialog` (raw + `.form`), `UtopiaConfirmDialog`.
- Sidebar: `UtopiaSidebar` (rail/drawer) with destination/action/custom item model.
- Vendored primitives (replacing the former `utopia_widgets` dependency, which is expected
  to depend on this package in the future): `UtopiaFormLayout`, `UtopiaCollapsible`,
  `UtopiaMultiWidget`.
