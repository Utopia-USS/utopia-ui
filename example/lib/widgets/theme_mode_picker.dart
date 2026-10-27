import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../state/theme_lab_state.dart';
import '../theme.dart';

/// A row of theme-mode pills, one per [ExampleThemeMode], reading and writing
/// the app-wide [ThemeLabState]. Tapping a pill re-themes the whole sheet.
///
/// Widget-level hook pattern: the widget calls exactly one state hook
/// ([_useThemeModePickerState], which owns the `useProvided` lookup) and
/// renders from the returned state.
class ThemeModePicker extends HookWidget {
  /// Creates the theme-mode picker.
  const ThemeModePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final state = _useThemeModePickerState();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in ExampleThemeMode.values)
          _ThemePill(
            key: ValueKey('themePill_${mode.name}'),
            mode: mode,
            isSelected: mode == state.selected,
            onTap: () => state.select(mode),
          ),
      ],
    );
  }
}

/// The picker's widget-level state: the active mode and the select action.
class _ThemeModePickerState {
  final ExampleThemeMode selected;
  final void Function(ExampleThemeMode mode) select;

  const _ThemeModePickerState({required this.selected, required this.select});
}

/// Widget-level state hook - the only place the picker touches the global
/// [ThemeLabState].
_ThemeModePickerState _useThemeModePickerState() {
  final global = useProvided<ThemeLabState>();
  return _ThemeModePickerState(selected: global.preset.value, select: global.selectPreset);
}

/// A single pill in the [ThemeModePicker]: three swatch dots plus the mode's
/// label, filled and bordered to reflect whether it is the active selection.
class _ThemePill extends StatelessWidget {
  final ExampleThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePill({super.key, required this.mode, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = context.colors;
    final swatches = mode.swatches;
    return InkWell(
      onTap: onTap,
      borderRadius: theme.borderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: theme.borderRadius,
          color: isSelected ? colors.chipBackground : Colors.transparent,
          border: Border.all(color: isSelected ? colors.primary : colors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < swatches.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              _Swatch(color: swatches[i], border: colors.border),
            ],
            const SizedBox(width: 8),
            Text(
              mode.label,
              style: context.textStyles.caption.copyWith(color: isSelected ? colors.primary : colors.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single 12px swatch dot in a [_ThemePill].
class _Swatch extends StatelessWidget {
  final Color color;
  final Color border;

  const _Swatch({required this.color, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: border),
      ),
    );
  }
}
