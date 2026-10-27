# 0.1.0

Initial release - extracted from `utopia_cms_ui` 0.1.0 under the `Utopia` prefix, then grown
into a token-driven design system with a machine-readable contract for AI and HTML design
tools.

- **Theme system:** `UtopiaTheme` (InheritedWidget) over freezed `UtopiaThemeData`,
  `UtopiaThemeColors` and `UtopiaThemeTextStyles`, built from a token ladder
  (`UtopiaTokens`: spacing, radius, border, shadow, duration, font weight, breakpoints) via
  `UtopiaThemeData.fromTokens`. `context.theme` / `context.colors` / `context.textStyles`
  and the field-state decorations (`fieldDecoration` plus hover, focus, error, error-focus
  and read-only variants) resolve every visual from the theme, never from widget code.
- **Dark mode out of the box:** `UtopiaThemeColors.darkTheme` and `UtopiaThemeData.darkTheme`.
  A palette alone is enough to re-skin: `textBody`, `onPrimary` and `shadow` are palette
  tokens, `UtopiaThemeTextStyles.fromColors` re-tints the type family, and the shadow
  presets take their tint from `colors.shadow`.
- **Buttons and text:** `UtopiaButton`, `UtopiaGhostButton`, `UtopiaRemoveIconButton`,
  `UtopiaTitle`, `UtopiaHeader`, `UtopiaCopyableText`.
- **Fields:** `UtopiaTextField`, `UtopiaSearchField`, `UtopiaDropdownField`,
  `UtopiaDatePicker`, `UtopiaFieldWrapper`, `UtopiaLabeledField`. Fields carry hover, focus,
  error and read-only chrome that never shifts layout, and share one 48px resting height with
  `UtopiaButton`. The date picker's Material theme is derived entirely from utopia tokens, so
  it renders consistently under any host `MaterialApp`.
- **Selection controls:** `UtopiaCheckbox` (with `indeterminate`), `UtopiaRadio<T>`,
  `UtopiaCheckRow`, `UtopiaSwitch`, `UtopiaSwitchField`, `UtopiaSlider` - fully controlled,
  Material-free and drawn from the tokens.
- **Table:** `UtopiaTable<T>` with `UtopiaTableEntry<T>` columns (including `numeric` columns
  with tabular figures), sort options with a direction caret, search panel, empty state and
  the `useUtopiaTableState` hook.
- **Dialogs and navigation:** `UtopiaDialog` (raw and `.form`), `UtopiaConfirmDialog`,
  `UtopiaSidebar` (rail/drawer) with a destination/action/custom item model.
- **Layout, loading and misc:** `UtopiaCard`, `UtopiaDivider`, `UtopiaChip`,
  `UtopiaChipList`, `UtopiaGradientBackground`, `UtopiaPageWrapper`, `UtopiaBreakpoints`,
  `UtopiaOverlayAnchor`, `UtopiaLoader`, `UtopiaThreeBounce`, `UtopiaLoadingBox` (skeleton
  shimmer), plus vendored `UtopiaFormLayout`, `UtopiaCollapsible` and `UtopiaMultiWidget`
  (replacing the former `utopia_widgets` dependency).
- **Utopia Design Protocol 0.4.0**, shipped in the package so every artifact is
  version-matched through the pub cache:
  - `protocol/` - the spec, versioning rules and JSON schemas.
  - `tokens/utopia.tokens.json` - the default theme as a DTCG token document.
  - `manifest/utopia.manifest.json` - every component with its props, states and token
    bindings, so an agent or design tool knows what exists before it invents anything.
  - `twin/` - the HTML twin: `tokens.css`, a Tailwind `@theme` variant, `components.html`,
    a composed gallery and `DESIGN.md`, kept in parity with the Flutter widgets.
  - `skills/utopia-design` - a Claude Code skill for designing against the twin.
- Companion package [`utopia_ui_tools`](https://pub.dev/packages/utopia_ui_tools) validates
  token documents, generates a project's theme from them and keeps manifests and twins fresh.
