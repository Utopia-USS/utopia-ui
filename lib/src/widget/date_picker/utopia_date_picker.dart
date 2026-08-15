import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utopia_ui/src/theme/utopia_theme_data.dart';
import 'package:utopia_ui/src/util/date_time_extension.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/button/utopia_remove_icon_button.dart';
import 'package:utopia_ui/src/widget/overlay/utopia_overlay_anchor.dart';
import 'package:utopia_ui/src/widget/wrapper/utopia_labeled_field.dart';

/// A tap-to-open date field: displays the picked [date] through a
/// [UtopiaLabeledField] trigger, opens an anchored calendar popover, and
/// clears through a [UtopiaRemoveIconButton] shown only when there is a date
/// to clear.
///
/// The trigger is a real focus stop, exactly like `UtopiaDropdownField`'s:
/// tapping it (or reaching it with Tab, then pressing Space/Enter) focuses it
/// and opens the popover, so the shared field chrome rings for as long as the
/// calendar is up. A permanent calendar icon marks the field as something that
/// OPENS - a picker is a control, not a display.
///
/// The calendar is a bare [CalendarDatePicker] - just the month header and
/// day grid, pick-on-tap - inside the same [UtopiaOverlayAnchor] popover
/// chrome the dropdowns use. No Material dialog: no colored header, no
/// help text, no confirm/cancel row. The grid itself is Material-owned, so
/// it is restyled from the ambient `UtopiaThemeData` via
/// [utopiaDatePickerMaterialTheme].
class UtopiaDatePicker extends HookWidget {
  /// The currently picked date; `null` shows the field empty (label at rest,
  /// no clear affordance).
  final DateTime? date;

  /// The floating label shown above the field.
  final String label;

  /// Called with the newly picked date, or `null` when the field is cleared.
  /// Omitting it also drops the clear affordance - there is nobody to tell.
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

  /// Extent of the trigger's suffix icons. A literal rather than a token
  /// multiple on purpose: it is pinned to the two affordances standing right
  /// next to it - `UtopiaDropdownField`'s chevron and
  /// `UtopiaRemoveIconButton`'s cross - which use the same number. A derived
  /// size here would make the calendar icon and the clear icon drift apart
  /// inside one suffix row on a rescaled token set.
  static const double _affordanceIconSize = 18;

  @override
  Widget build(BuildContext context) {
    // The trigger's own focus node - the same construction the dropdown uses.
    // `UtopiaFieldWrapper` never takes focus itself and instead rings whenever
    // a DESCENDANT of it is focused, so the trigger only has to put a real
    // node under it for the declared focus/open states to have a rendering.
    final focusNode = useFocusNode(debugLabel: 'UtopiaDatePicker trigger');
    return UtopiaOverlayAnchor(
      // The calendar has a fixed design width; sizing it to a narrow trigger
      // would crush the grid.
      matchTriggerWidth: false,
      maxHeight: _popoverMaxHeight,
      triggerBuilder: (context, open) {
        void openFocused() {
          focusNode.requestFocus();
          open();
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openFocused,
            child: _buildTrigger(context, focusNode: focusNode, onActivate: openFocused),
          ),
        );
      },
      overlayBuilder: (context, close) => _buildCalendar(context, close, focusNode),
    );
  }

  /// The closed field: a labeled-field trigger carrying the value, a clear
  /// affordance when there is one, and the permanent calendar icon.
  ///
  /// [UtopiaLabeledField] rather than a read-only `UtopiaTextField`: the value
  /// is uneditable BY CONSTRUCTION here (it is a `Text`, not a `TextField`),
  /// so the field does not have to buy that guarantee with the wrapper's
  /// read-only chrome - which outranks focus and would leave the trigger
  /// visually dead while its calendar is up. It also drops the remount-on-key
  /// hack a read-only `UtopiaTextField` needed to follow external changes.
  Widget _buildTrigger(BuildContext context, {required FocusNode focusNode, required VoidCallback onActivate}) {
    final date = this.date;
    final onDateChanged = this.onDateChanged;
    return UtopiaLabeledField(
      label: label,
      value: date?.toDisplayStringWithoutHours(),
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clear is conditional, the calendar is not: an X on an empty field
          // offers to undo nothing, while the calendar icon is the affordance
          // that says this field opens. They sit side by side rather than
          // swapping on hover - an icon that changes identity under the
          // pointer is a mis-click waiting to happen, and a hover-only clear
          // does not exist at all on touch.
          if (date != null && onDateChanged != null) ...[
            UtopiaRemoveIconButton(onPressed: () => onDateChanged(null)),
            SizedBox(width: context.spacing.xs),
          ],
          // The node rides on the suffix for the same reason it does in the
          // dropdown: the wrapper only watches its own descendants, and the
          // suffix is the single slot this widget owns INSIDE that wrapper.
          Focus(
            focusNode: focusNode,
            onKeyEvent: (node, event) => _handleTriggerKey(event, onActivate),
            child: Icon(
              Icons.calendar_today_outlined,
              size: _affordanceIconSize,
              // The body tone the dropdown's chevron uses, so the two triggers
              // read as one family standing side by side in a form.
              color: context.textStyles.text.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Space / Enter on the focused trigger opens the popover, so the focus ring
  /// marks a control that can actually be operated from the keyboard.
  KeyEventResult _handleTriggerKey(KeyEvent event, VoidCallback onActivate) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter && key != LogicalKeyboardKey.space) return KeyEventResult.ignored;
    onActivate();
    return KeyEventResult.handled;
  }

  Widget _buildCalendar(BuildContext context, VoidCallback close, FocusNode focusNode) {
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
            // Picking hands focus back to the trigger, so the field stays the
            // active control after the calendar goes away (and a keyboard user
            // does not fall back to the top of the traversal order) - the same
            // hand-back the dropdown does when an option is picked.
            focusNode.requestFocus();
          },
        ),
      ),
    );
  }
}

/// Maps `UtopiaThemeData` tokens onto a Material [ThemeData] scoped to
/// Flutter's own date pickers, so the (Material-owned) [CalendarDatePicker],
/// `showDatePicker` dialog and `showDateRangePicker` dialog render in the
/// design system's colors, type and shape.
///
/// Built from scratch rather than by copying the ambient [ThemeData]: the
/// picker must look utopian under ANY host `MaterialApp` (charter: components
/// carry no Material theme coupling), so nothing of the host's palette or
/// typography can leak into it. Inject it at the point of use -
/// `Theme(data: utopiaDatePickerMaterialTheme(context.theme), child: ...)`,
/// or as `showDatePicker`'s `builder` - and the widget Flutter itself styles
/// through [ThemeData] comes out on system tokens.
///
/// Exposed for reuse by other Material-owned pickers (e.g. a future time
/// picker); regular components must keep reading tokens directly and never
/// depend on Material theming (charter rule) - this adapter exists only for
/// widgets Flutter itself styles through [ThemeData].
///
/// Every override below is deliberate; the slots left unset are equally
/// deliberate and named in the comments (elevation and shadow above all: the
/// system's elevation is a multi-layer `BoxShadow` list that Material's single
/// `elevation` double cannot express, so the dialog keeps Material's own lift
/// rather than a fabricated one, and the popover draws the system's real
/// `cardDecoration` around the grid instead).
ThemeData utopiaDatePickerMaterialTheme(UtopiaThemeData theme) {
  final colors = theme.colors;
  final textStyles = theme.textStyles;
  final tokens = theme.tokens;
  // Contrast color for content sitting on `primary` - same convention the
  // sidebar uses for content on colored backgrounds.
  final onPrimary = textStyles.button.color ?? Colors.white;
  final brightness = ThemeData.estimateBrightnessForColor(colors.surface);
  // The system's divider hairline, resolved the way `UtopiaDivider` resolves
  // it so a hand-built theme that leaves `divider` unset still separates the
  // dialog's header from its calendar.
  final divider = colors.divider ?? Color.alphaBlend(colors.text.withValues(alpha: 0.12), colors.surface);
  // Day and year cells are the smallest surface in the system's radius ladder
  // (badge 6 < control 12 < card 16), so they take the badge step. Material's
  // default circle/stadium is its own signature, not this system's: every
  // other selectable box here is a rounded rectangle.
  final cellShape = WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(borderRadius: tokens.radius.smAll),
  );

  /// Foreground of a day/year cell: contrast on the selection plate, the
  /// muted disabled tone out of range, the body tone otherwise.
  Color cellForeground(Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) return onPrimary;
    if (states.contains(WidgetState.disabled)) return colors.disabled;
    return colors.text;
  }

  /// Background of a day/year cell: the selection plate, or nothing - resting
  /// cells sit directly on the dialog surface (doctrine: edge leads, fill
  /// supports).
  Color? cellBackground(Set<WidgetState> states) =>
      states.contains(WidgetState.selected) ? colors.primary : null;

  // Action row (CANCEL / OK): text buttons in the system's button type, tinted
  // to `primary`. `textStyles.button` carries the contrast colour meant for a
  // FILLED button, so the foreground is overridden on both the style and the
  // text style - a text button paints its label in the brand hue.
  final actionButtonStyle = TextButton.styleFrom(
    foregroundColor: colors.primary,
    textStyle: textStyles.button.copyWith(color: colors.primary),
    shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
  );

  return ThemeData(
    useMaterial3: true,
    // Carries the design-system family into the calendar's own text defaults
    // (anything not routed through datePickerTheme below).
    fontFamily: textStyles.text.fontFamily,
    // The out-of-range month chevrons; Material derives their disabled tint
    // from here rather than from the date-picker theme.
    disabledColor: colors.disabled,
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
      // --- the dialog surface (showDatePicker; the popover route draws its
      // own card chrome around the grid instead) ---
      backgroundColor: colors.surface,
      // A calendar is an overlay card, so it takes the card radius tier - the
      // same shape a dialog gets - instead of Material's 28.
      shape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
      // M3 tints an elevated surface toward `primary`; the system's surfaces
      // are flat colours, so the tint is switched off and `surface` above is
      // exactly what ships.
      surfaceTintColor: Colors.transparent,
      // `elevation` / `shadowColor` deliberately unset - see the doc comment.
      dividerColor: divider,

      // --- dialog header (the big date + "SELECT DATE" microcopy) ---
      // Transparent, so the header sits on the dialog surface and the whole
      // thing reads as one card rather than Material's coloured banner.
      headerBackgroundColor: Colors.transparent,
      headerForegroundColor: colors.text,
      // Material renders the headline at `headlineLarge`; `header` is this
      // system's largest style and holds the same role at this system's scale.
      headerHeadlineStyle: textStyles.header,
      // The help line is microcopy above the headline: the label role, in the
      // muted tone so it never competes with the date it introduces.
      headerHelpStyle: textStyles.label.copyWith(color: colors.hint),

      // --- calendar sub-header (month/year toggle + prev/next chevrons) ---
      // The popover's only heading, so it takes the heading style one step
      // above the day cells rather than Material's `titleSmall`.
      toggleButtonTextStyle: textStyles.title,
      // Colours the toggle's caret and the month chevrons; the body tone, the
      // same one the trigger's calendar icon uses. (It does NOT recolour the
      // toggle label: `toggleButtonTextStyle` already carries its own colour,
      // which Material prefers.)
      subHeaderForegroundColor: textStyles.text.color,

      // --- day grid ---
      // Weekday initials are microcopy about the grid, not content in it:
      // caption size in the muted tone, a step below the days themselves.
      weekdayStyle: textStyles.caption.copyWith(color: colors.hint),
      dayStyle: textStyles.text,
      dayForegroundColor: WidgetStateProperty.resolveWith(cellForeground),
      dayBackgroundColor: WidgetStateProperty.resolveWith(cellBackground),
      // Pointer/keyboard feedback on a cell is the system's hover tint - the
      // same one table rows and dropdown options use.
      dayOverlayColor: WidgetStatePropertyAll(colors.hover),
      dayShape: cellShape,
      // Today unselected is an OUTLINE, not a fill: the system marks state on
      // the edge and reserves the filled plate for the actual selection.
      todayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? onPrimary
            : (states.contains(WidgetState.disabled) ? colors.disabled : colors.primary),
      ),
      todayBackgroundColor: WidgetStateProperty.resolveWith(cellBackground),
      todayBorder: BorderSide(color: colors.primary, width: tokens.borders.hairline),

      // --- year grid (behind the month/year toggle) ---
      yearStyle: textStyles.text,
      yearForegroundColor: WidgetStateProperty.resolveWith(cellForeground),
      yearBackgroundColor: WidgetStateProperty.resolveWith(cellBackground),
      yearOverlayColor: WidgetStatePropertyAll(colors.hover),
      yearShape: cellShape,

      // --- range picker (showDateRangePicker) ---
      // Same surface, same header treatment as the single-date dialog: the
      // range picker is the same component with a second endpoint, and
      // Material's default (a `primary`-filled header banner) would make it
      // look like a different design system.
      rangePickerBackgroundColor: colors.surface,
      rangePickerShape: RoundedRectangleBorder(borderRadius: theme.cardRadius),
      rangePickerSurfaceTintColor: Colors.transparent,
      rangePickerHeaderBackgroundColor: Colors.transparent,
      rangePickerHeaderForegroundColor: colors.text,
      rangePickerHeaderHeadlineStyle: textStyles.header,
      rangePickerHeaderHelpStyle: textStyles.label.copyWith(color: colors.hint),
      // The band between the two endpoints: the quiet selection tint, not a
      // second saturated plate - only the endpoints themselves carry `primary`.
      rangeSelectionBackgroundColor: colors.hover,
      rangeSelectionOverlayColor: WidgetStatePropertyAll(colors.hover),

      // --- manual-entry mode (the keyboard toggle inside showDatePicker) ---
      // Without this the typed-date field would fall back to Material's
      // underlined input - the one field in the system that does not share the
      // field chrome. Reproduced from tokens rather than reused from
      // `utopiaFieldDecoration`, which needs a BuildContext this pure
      // derivation does not have.
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.field,
        isDense: true,
        labelStyle: textStyles.text.copyWith(color: colors.hint),
        floatingLabelStyle: textStyles.caption.copyWith(color: colors.hint),
        hintStyle: textStyles.text.copyWith(color: colors.hint),
        errorStyle: textStyles.caption.copyWith(color: colors.error),
        border: OutlineInputBorder(
          borderRadius: theme.borderRadius,
          borderSide: BorderSide(color: colors.border, width: tokens.borders.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: theme.borderRadius,
          borderSide: BorderSide(color: colors.border, width: tokens.borders.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: theme.borderRadius,
          borderSide: BorderSide(color: colors.primary, width: tokens.borders.thick),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: theme.borderRadius,
          borderSide: BorderSide(color: colors.error, width: tokens.borders.hairline),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: theme.borderRadius,
          borderSide: BorderSide(color: colors.error, width: tokens.borders.thick),
        ),
      ),

      // --- action row ---
      cancelButtonStyle: actionButtonStyle,
      confirmButtonStyle: actionButtonStyle,
      // `locale` deliberately unset: the ambient `Localizations` locale is the
      // consumer's call, and overriding it here would silently re-language
      // every picker in the app.
    ),
  );
}
