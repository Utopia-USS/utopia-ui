import 'package:flutter/material.dart';
import 'package:utopia_ui/src/theme/utopia_theme_data.dart';
import 'package:utopia_ui/src/util/date_time_extension.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/button/utopia_remove_icon_button.dart';
import 'package:utopia_ui/src/widget/overlay/utopia_overlay_anchor.dart';
import 'package:utopia_ui/src/widget/text_field/utopia_text_field.dart';

/// A tap-to-open date field: displays the picked [date] through a
/// [UtopiaTextField], opens an anchored calendar popover and offers a clear
/// affordance via [UtopiaRemoveIconButton].
///
/// The calendar is a bare [CalendarDatePicker] - just the month header and
/// day grid, pick-on-tap - inside the same [UtopiaOverlayAnchor] popover
/// chrome the dropdowns use. No Material dialog: no colored header, no
/// help text, no confirm/cancel row. The grid itself is Material-owned, so
/// it is restyled from the ambient `UtopiaThemeData` via
/// [utopiaDatePickerMaterialTheme].
class UtopiaDatePicker extends StatelessWidget {
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

  /// The calendar grid's design width (Material's own calendar metric) plus
  /// its height cap inside the popover.
  static const double _calendarWidth = 328;
  static const double _popoverMaxHeight = 420;

  @override
  Widget build(BuildContext context) {
    return UtopiaOverlayAnchor(
      // The calendar has a fixed design width; sizing it to a narrow trigger
      // would crush the grid.
      matchTriggerWidth: false,
      maxHeight: _popoverMaxHeight,
      triggerBuilder: (context, open) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: open,
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
      ),
      overlayBuilder: _buildCalendar,
    );
  }

  Widget _buildCalendar(BuildContext context, VoidCallback close) {
    final now = DateTime.now();
    return Theme(
      data: utopiaDatePickerMaterialTheme(context.theme),
      child: SizedBox(
        width: _calendarWidth,
        child: CalendarDatePicker(
          initialDate: date ?? now,
          firstDate: firstDate ?? now.copyWith(year: now.year - 50),
          lastDate: lastDate ?? now.copyWith(year: now.year + 50),
          // Fires on a day tap (year taps only flip the displayed month), so
          // picking a day commits and dismisses in one gesture - no confirm row.
          onDateChanged: (picked) {
            onDateChanged?.call(picked);
            close();
          },
        ),
      ),
    );
  }
}

/// Maps `UtopiaThemeData` tokens onto a Material [ThemeData] scoped to the
/// calendar grid, so the (Material-owned) [CalendarDatePicker] renders in the
/// design system's colors and typography.
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

  return ThemeData(
    useMaterial3: true,
    // Carries the design-system family into the calendar's own text defaults
    // (month header, year list) that don't route through datePickerTheme.
    fontFamily: textStyles.text.fontFamily,
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
    ),
  );
}
