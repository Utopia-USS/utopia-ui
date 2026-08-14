# Unreleased

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
