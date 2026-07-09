import 'package:flutter/material.dart';
import 'package:utopia_ui/src/theme/utopia_theme.dart';
import 'package:utopia_ui/src/theme/utopia_theme_data.dart';
import 'package:utopia_ui/src/util/date_time_extension.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/widget/button/utopia_remove_icon_button.dart';
import 'package:utopia_ui/src/widget/text_field/utopia_text_field.dart';

/// A tap-to-open date field: displays the picked [date] through a
/// [UtopiaTextField], opens a calendar dialog and offers a clear affordance via
/// [UtopiaRemoveIconButton].
///
/// The calendar is Flutter's [showDatePicker] restyled from the ambient
/// `UtopiaThemeData` tokens (colors, text styles, card radius), so it follows
/// the design system - including branded/dark themes - instead of the stock
/// Material look. See [utopiaDatePickerMaterialTheme] for the mapping.
class UtopiaDatePicker extends HookWidget {
  /// The currently picked date; `null` shows the field empty.
  final DateTime? date;

  /// The floating label shown above the field.
  final String label;

  /// Called with the newly picked date, or `null` when the field is cleared.
  final void Function(DateTime?)? onDateChanged;

  /// Earliest selectable date. Defaults to 50 years before today.
  final DateTime? firstDate;

  /// Latest selectable date. Defaults to 50 years after today.
  final DateTime? lastDate;

  /// Creates a tap-to-open date field.
  const UtopiaDatePicker({
    super.key,
    required this.date,
    required this.label,
    this.onDateChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _pick(context),
        child: UtopiaTextField(
          // UtopiaTextField seeds its text once and never resyncs (documented
          // uncontrolled contract); keying by the picked date remounts it so
          // the display follows external changes. Safe here: the field is
          // readOnly, so a remount can never discard user input.
          key: ValueKey(date),
          value: date?.toDisplayStringWithoutHours() ?? '',
          readOnly: true,
          suffix: UtopiaRemoveIconButton(onPressed: () => onDateChanged?.call(null)),
          label: Text(label),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    // Tokens are resolved from the OPENING context: the dialog route roots at
    // the app navigator, outside any subtree-scoped UtopiaTheme, so the derived
    // Material theme is our capture-and-reattach for this Material-owned route.
    final pickerTheme = utopiaDatePickerMaterialTheme(UtopiaTheme.of(context));
    final result = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: firstDate ?? now.copyWith(year: now.year - 50),
      lastDate: lastDate ?? now.copyWith(year: now.year + 50),
      builder: (context, child) => Theme(data: pickerTheme, child: child!),
    );
    if (result != null) onDateChanged?.call(result);
  }
}

/// Maps `UtopiaThemeData` tokens onto a Material [ThemeData] scoped to the date
/// picker dialog, so the (Material-owned) calendar renders in the design
/// system's colors, typography and corner radius.
///
/// Exposed for reuse by other Material-owned pickers (e.g. a future time
/// picker); regular components must keep reading tokens directly and never
/// depend on Material theming (charter rule) - this adapter exists only for
/// widgets Flutter itself styles through [ThemeData].
ThemeData utopiaDatePickerMaterialTheme(UtopiaThemeData theme) {
  final colors = theme.colors;
  final textStyles = theme.textStyles;
  // Contrast color for content sitting on `primary` - same convention the
  // sidebar uses for content on colored backgrounds.
  final onPrimary = textStyles.button.color ?? Colors.white;
  final brightness = ThemeData.estimateBrightnessForColor(colors.surface);
  final buttonStyle = TextButton.styleFrom(
    foregroundColor: colors.primary,
    textStyle: textStyles.label,
    shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: onPrimary,
      secondary: colors.accent,
      onSecondary: onPrimary,
      error: colors.error,
      onError: onPrimary,
      surface: colors.surface,
      onSurface: colors.text,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
      headerBackgroundColor: colors.primary,
      headerForegroundColor: onPrimary,
      headerHeadlineStyle: textStyles.header.copyWith(color: onPrimary),
      headerHelpStyle: textStyles.caption.copyWith(color: onPrimary),
      weekdayStyle: textStyles.caption.copyWith(color: colors.hint),
      dayStyle: textStyles.text,
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? onPrimary : colors.text,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colors.primary : null,
      ),
      dayOverlayColor: WidgetStatePropertyAll(colors.hover),
      todayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? onPrimary : colors.primary,
      ),
      todayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colors.primary : null,
      ),
      todayBorder: BorderSide(color: colors.primary),
      yearStyle: textStyles.text,
      yearForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? onPrimary : colors.text,
      ),
      yearBackgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colors.primary : null,
      ),
      yearOverlayColor: WidgetStatePropertyAll(colors.hover),
      dividerColor: colors.border,
      cancelButtonStyle: buttonStyle,
      confirmButtonStyle: buttonStyle,
    ),
    textButtonTheme: TextButtonThemeData(style: buttonStyle),
  );
}
