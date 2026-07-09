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
