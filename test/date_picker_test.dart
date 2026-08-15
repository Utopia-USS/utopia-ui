import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// Pins the two halves of `UtopiaDatePicker`'s contract:
///
/// * the trigger is a live control - it takes focus, rings while its calendar
///   is up, carries a permanent calendar affordance and offers to clear only
///   when there is a date to clear;
/// * the calendar is Material's, but never the HOST's: the picker injects a
///   theme derived from `UtopiaThemeData` at the point of use, so a hostile
///   ambient `ThemeData` cannot reach the grid.
void main() {
  final theme = UtopiaThemeData.defaultTheme;
  final colors = theme.colors;

  /// The decoration `UtopiaFieldWrapper` currently paints - the wrapper's own
  /// `AnimatedContainer` is the first one under it.
  BoxDecoration wrapperDecoration(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.descendant(of: find.byType(UtopiaFieldWrapper), matching: find.byType(AnimatedContainer)).first,
    );
    return container.decoration! as BoxDecoration;
  }

  FocusNode triggerNode(WidgetTester tester) => tester
      .widgetList<Focus>(find.byType(Focus))
      .map((focus) => focus.focusNode)
      .firstWhere((node) => node?.debugLabel == 'UtopiaDatePicker trigger')!;

  Widget buildApp({
    DateTime? date,
    void Function(DateTime?)? onDateChanged,
    ThemeData? hostTheme,
    bool withCallback = true,
  }) => MaterialApp(
    theme: hostTheme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: UtopiaDatePicker(
            label: 'Published',
            date: date,
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            onDateChanged: withCallback ? (value) => onDateChanged?.call(value) : null,
          ),
        ),
      ),
    ),
  );

  group('trigger', () {
    testWidgets('opening the calendar rings the trigger, like the dropdown', (tester) async {
      await tester.pumpWidget(buildApp(date: DateTime(2026, 3, 14)));
      await tester.pumpAndSettle();

      expect(wrapperDecoration(tester), theme.fieldDecoration, reason: 'the resting trigger must not ring');
      expect(find.byType(CalendarDatePicker), findsNothing);

      await tester.tap(find.text('14 Mar 2026'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarDatePicker), findsOneWidget, reason: 'tapping the trigger opens the calendar');
      expect(
        wrapperDecoration(tester),
        theme.fieldFocusDecoration,
        reason: 'an open calendar means its trigger is the active control - the field must ring',
      );
    });

    testWidgets('a keyboard-focused trigger opens on Enter and on Space', (tester) async {
      await tester.pumpWidget(buildApp(date: DateTime(2026, 3, 14)));
      await tester.pumpAndSettle();

      triggerNode(tester).requestFocus();
      await tester.pumpAndSettle();
      expect(
        wrapperDecoration(tester),
        theme.fieldFocusDecoration,
        reason: 'reaching the trigger with the keyboard rings the field like a focused text field',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget, reason: 'Enter opens the calendar');

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsNothing, reason: 'tapping the barrier dismisses the calendar');

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget, reason: 'Space opens the calendar');
    });

    testWidgets('the calendar affordance is permanent, the clear affordance is not', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.calendar_today_outlined),
        findsOneWidget,
        reason: 'an empty picker still has to read as a control that opens',
      );
      expect(
        find.byType(UtopiaRemoveIconButton),
        findsNothing,
        reason: 'an empty field has nothing to clear - the X would offer to undo nothing',
      );

      await tester.pumpWidget(buildApp(date: DateTime(2026, 3, 14)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byType(UtopiaRemoveIconButton), findsOneWidget, reason: 'a filled field can be cleared');

      await tester.pumpWidget(buildApp(date: DateTime(2026, 3, 14), withCallback: false));
      await tester.pumpAndSettle();

      expect(
        find.byType(UtopiaRemoveIconButton),
        findsNothing,
        reason: 'without onDateChanged there is nobody to tell that the date was cleared',
      );
    });

    testWidgets('clearing reports null and does not open the calendar', (tester) async {
      DateTime? picked = DateTime(2026, 3, 14);
      var calls = 0;
      await tester.pumpWidget(
        buildApp(
          date: picked,
          onDateChanged: (value) {
            picked = value;
            calls++;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UtopiaRemoveIconButton));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(picked, isNull);
      expect(
        find.byType(CalendarDatePicker),
        findsNothing,
        reason: 'the clear icon consumes its own tap - clearing a field must not also open it',
      );
    });

    testWidgets('picking a day reports it and dismisses the calendar', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(buildApp(date: DateTime(2026, 3, 14), onDateChanged: (value) => picked = value));
      await tester.pumpAndSettle();

      await tester.tap(find.text('14 Mar 2026'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2026, 3, 20));
      expect(find.byType(CalendarDatePicker), findsNothing, reason: 'picking commits and dismisses in one gesture');
      expect(
        wrapperDecoration(tester),
        theme.fieldFocusDecoration,
        reason: 'the trigger stays the focused control after the calendar closes',
      );
    });
  });

  group('theme derivation', () {
    /// A deliberately hostile host: dark, orange, rounded to a pill and
    /// carrying its own date-picker theme - everything the picker must ignore.
    final hostileHost = ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(primary: Colors.orange, surface: Colors.black, onSurface: Colors.yellow),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.deepPurple,
        dayStyle: TextStyle(fontFamily: 'Comic Sans MS', fontSize: 30),
        shape: StadiumBorder(),
      ),
    );

    testWidgets('the calendar renders on utopia tokens under a hostile host theme', (tester) async {
      await tester.pumpWidget(buildApp(date: DateTime(2026, 3, 14), hostTheme: hostileHost));
      await tester.pumpAndSettle();
      await tester.tap(find.text('14 Mar 2026'));
      await tester.pumpAndSettle();

      final calendarContext = tester.element(find.byType(CalendarDatePicker));
      final datePickerTheme = DatePickerTheme.of(calendarContext);
      final materialTheme = Theme.of(calendarContext);

      expect(datePickerTheme.backgroundColor, colors.surface, reason: 'the host cannot repaint the dialog surface');
      expect(materialTheme.colorScheme.primary, colors.primary, reason: 'selection follows the utopia brand hue');
      expect(materialTheme.colorScheme.surface, colors.surface);
      expect(materialTheme.colorScheme.onSurface, colors.text);
      expect(datePickerTheme.dayStyle, theme.textStyles.text, reason: 'the host cannot restyle the day grid');
      expect(
        datePickerTheme.shape,
        RoundedRectangleBorder(borderRadius: theme.cardRadius),
        reason: 'a calendar is an overlay card and takes the card radius tier',
      );
      expect(
        datePickerTheme.surfaceTintColor,
        Colors.transparent,
        reason: "M3's tonal elevation tint would drag the surface off its token colour",
      );
      expect(
        datePickerTheme.dayForegroundColor?.resolve({WidgetState.selected}),
        theme.textStyles.button.color,
        reason: 'a selected day carries the contrast colour meant for content on primary',
      );
      expect(datePickerTheme.dayBackgroundColor?.resolve({WidgetState.selected}), colors.primary);
      expect(datePickerTheme.dayForegroundColor?.resolve({WidgetState.disabled}), colors.disabled);
      expect(datePickerTheme.dayBackgroundColor?.resolve(const {}), isNull, reason: 'resting cells carry no fill');
      expect(datePickerTheme.todayForegroundColor?.resolve(const {}), colors.primary);
      expect(datePickerTheme.todayBorder?.color, colors.primary, reason: 'today is an outline, not a fill');
      expect(datePickerTheme.dayOverlayColor?.resolve({WidgetState.hovered}), colors.hover);
      expect(datePickerTheme.cancelButtonStyle?.foregroundColor?.resolve(const {}), colors.primary);
      expect(datePickerTheme.confirmButtonStyle?.foregroundColor?.resolve(const {}), colors.primary);
      expect(datePickerTheme.headerHeadlineStyle, theme.textStyles.header);
      expect(datePickerTheme.dividerColor, colors.divider);
    });

    testWidgets('a subtree theme re-themes the calendar', (tester) async {
      final rebranded = UtopiaThemeData.defaultTheme.copyWith(
        colors: UtopiaThemeColors.defaultTheme.copyWith(primary: const Color(0xFF0F7B3C)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtopiaTheme(
              data: rebranded,
              child: Center(
                child: SizedBox(
                  width: 320,
                  child: UtopiaDatePicker(label: 'Published', date: DateTime(2026, 3, 14), onDateChanged: (_) {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('14 Mar 2026'));
      await tester.pumpAndSettle();

      final datePickerTheme = DatePickerTheme.of(tester.element(find.byType(CalendarDatePicker)));
      expect(
        datePickerTheme.dayBackgroundColor?.resolve({WidgetState.selected}),
        const Color(0xFF0F7B3C),
        reason: 'the calendar reads the ambient UtopiaThemeData, so a subtree rebrand reaches it',
      );
    });
  });
}
