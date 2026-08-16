# utopia_ui - design charter

A themeable, general-purpose Flutter design system: tables, dialogs, sidebar navigation and
form primitives. This document is normative for every component added to this package.
Deviations require updating this charter first.

## Purpose & scope

`utopia_ui` is a standalone design system usable by any Flutter app. It carries no domain
logic: consumers (such as `utopia_cms`) contribute data binding, delegates and orchestration
on top of these presentational components.

Litmus test for every public API here: *a project that needs "an admin-panel-quality table /
button / dialog" but has its own models, its own data layer and its own brand must be able to
adopt this component without forking it.* Concretely that means: no assumptions about where data
comes from, what shape rows have, or what the app looks like.

## Naming

- Every public top-level type carries the `Utopia` prefix, without exception: widgets
  (`UtopiaButton`), data/config classes (`UtopiaTableEntry`), enums (`UtopiaButtonVariant`, not
  `ButtonType`), typedefs. 100% coverage is a review gate, not an aspiration.
- Hooks are `useUtopiaX` (`useUtopiaTableState`). Extensions are `UtopiaXExtensions`.
- Files are `snake_case` matching the primary type (`utopia_button.dart` -> `UtopiaButton`).
- Named constructors express structural variants (`UtopiaTableEntry.fixed`, `UtopiaDialog.form`);
  enum params express visual variants (`variant:`, `size:`). Escape hatches are `.raw`.

## Package layout & exports

```
lib/
  utopia_ui.dart              # THE barrel - the only supported import
  src/
    theme/                    # UtopiaTheme widget + token classes
    widget/<family>/          # one folder per component family (button, chip, table, ...)
    util/                     # internal helpers, context extensions
```

- Single barrel: consumers import `package:utopia_ui/utopia_ui.dart`, nothing else.
  Everything under `src/` is private unless exported by the barrel. No per-family barrels,
  no deep imports, no `export` statements embedded in component files.
- Doc comment required on every exported declaration (what it is + one usage hint).

## Theming

- Tokens: `UtopiaThemeData` (freezed) = `UtopiaThemeColors` + `UtopiaThemeTextStyles` + layout
  tokens (radii, paddings, shadows, tile/divider sizing) + computed decoration getters. Flat
  token root, v1 has NO per-component theme objects (revisit only with real demand; see
  forui/shadcn style-delta models for the shape it would take).
- Distribution: `UtopiaTheme` is a plain `InheritedWidget` (like `Theme`/`DefaultTextStyle`):
  - `UtopiaTheme.of(context)` -> `UtopiaThemeData`, silently falling back to
    `UtopiaThemeData.defaultTheme` when absent (zero-config components).
  - `UtopiaTheme.maybeOf(context)` -> nullable, for callers that must distinguish.
  - `updateShouldNotify` compares `data` (freezed equality).
- Ergonomic lookup is the context extension: `context.theme`, `context.colors`,
  `context.textStyles`, `context.fieldDecoration`.
- Components NEVER hardcode colors/text styles/radii - every visual constant comes from the
  token classes. New tokens are added to `UtopiaThemeData` rather than inlined. (Anti-pattern
  references: static-const color access sprinkled per widget kills rebrandability.)
- Overlay/dialog helpers that push new routes must re-attach the ambient `UtopiaThemeData`
  captured from the opening context, so subtree-scoped themes survive route boundaries.
- No `provider` dependency; no Material `ThemeExtension` coupling (components must work under
  any `MaterialApp` theme, or none).

## Component API conventions

- Slots: static content is a `Widget` param; dynamic content is a named `xxxBuilder` with
  `BuildContext` first. Prefer builders over inheritance for customization.
- State modeling: presentational widgets take values + callbacks (`currentSort` in,
  `onSortPressed` out). Stateful conveniences ship as optional companion hooks
  (`useUtopiaTableState`), never baked into the widget. A widget must be usable fully controlled.
- Data-shape agnosticism: generic over row/item type `T` with builder/selector functions.
  `JsonMap`, string key-paths, delegates, and any consumer-domain type (e.g. `utopia_cms` core
  types) are FORBIDDEN here - adapters live in the consuming package.
- Loading/disabled are modeled explicitly where consumers need them (`loading:` on
  `UtopiaButton`) even though external design systems avoid it - this is an app-oriented
  system, pragmatism wins.
- Slivers: scrollable composites are sliver-first (`UtopiaTable` is a sliver; pages compose it
  in a `CustomScrollView`). Use Flutter built-ins (`SliverMainAxisGroup`, `PinnedHeaderSliver`,
  `OverlayPortal`) - no sliver_tools, no flutter_portal.
- Responsiveness rides on one system: `UtopiaBreakpoints` + `UtopiaPageWrapper`/`UtopiaPageType`,
  consumed by pages AND dialogs alike.

## Dependency policy

Allowed: `flutter`, `utopia_hooks`, `utopia_collections`, `fast_immutable_collections`,
`shimmer`, `freezed_annotation`, `intl` (+ dev: freezed, build_runner, utopia_lints).
`intl` is used by the date-display formatting extension backing the date picker - pure Dart,
web-safe, no `dart:io`.
Forbidden (with reasons, learned the hard way):
- `utopia_widgets` - deliberately absent although this package began as a consumer of it:
  `utopia_widgets` is expected to depend on `utopia_ui` in the future, so the dependency cannot
  point the other way. The few primitives needed from it (`UtopiaFormLayout`,
  `UtopiaCollapsible`, `UtopiaMultiWidget`) are vendored under `src/widget/`.
- `utopia_arch` - transitively pulls a `dart:io` logger and breaks web.
- `provider` - replaced by `UtopiaTheme` InheritedWidget.
- `flutter_portal`, `sliver_tools` - superseded by Flutter built-ins.
- Anything with platform-heavy native code (media/video/pickers) - those components belong in
  consumer packages.
Adding any dependency requires a charter update with rationale.

## Coupling rules (hard boundaries)

- This package must never import a consumer package (e.g. `utopia_cms`); reviewers additionally
  check that no consumer-domain types get copied in to smuggle coupling.
- No navigation opinions: components may push nothing by themselves except self-contained
  overlays (`OverlayPortal`); `show...` helpers are thin wrappers over vanilla `showDialog`.
- No I/O, no persistence, no network, no `dart:io`.

## Quality gates (every phase close)

1. `flutter analyze` clean; utopia_lints; public-API dartdoc coverage.
2. Example app compiles and behaves identically (headless-Chrome screenshot comparison for
   visual-parity phases).
3. Prefix/naming/barrel conformance sweep.
4. No client-project references anywhere in code, comments, docs or commits (public repo).
5. Charter conformance review recorded in the plan ledger.

## Component list v1

- Theme: `UtopiaTheme`, `UtopiaThemeData`, `UtopiaThemeColors`, `UtopiaThemeTextStyles`.
- Primitives: `UtopiaButton`, `UtopiaRemoveIconButton`, `UtopiaChip`, `UtopiaChipList`,
  `UtopiaCheckbox`, `UtopiaRadio<T>`, `UtopiaCheckRow`, `UtopiaSwitch`, `UtopiaSwitchField`,
  `UtopiaSlider`, `UtopiaTextField`, `UtopiaSearchField`,
  `UtopiaFieldWrapper`, `UtopiaLabeledField`, `UtopiaDropdownField`, `UtopiaOverlayAnchor`,
  `UtopiaDatePicker`, `UtopiaLoader`, `UtopiaLoadingBox` (formerly `UtopiaMockLoadingBox`,
  deprecated alias retained), `UtopiaThreeBounce`,
  `UtopiaDivider`, `UtopiaCard`, `UtopiaGradientBackground`, `UtopiaTitle`,
  `UtopiaCopyableText`, `UtopiaBreakpoints`, `UtopiaPageWrapper`, `UtopiaPageType`.
- Vendored layout/misc primitives: `UtopiaFormLayout`, `UtopiaCollapsible`, `UtopiaMultiWidget`.
- Table: `UtopiaTable`, `UtopiaTableEntry<T>` (+ sort option type), header/item/cell
  subcomponents, empty/loader slots, `useUtopiaTableState`.
- Overlays & navigation: `UtopiaDialog` (raw + `.form`, confirm prefab), `UtopiaSidebar`
  (rail/drawer, generic item model).
- Explicitly NOT in this package: media/video components, country picker, management forms,
  table-page CRUD orchestration, shell/menu-scope machinery, delegates and filter models.
