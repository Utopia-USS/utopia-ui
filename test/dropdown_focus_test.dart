import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// Pins the dropdown trigger's focus contract.
///
/// `UtopiaDropdownField` declares `focus` and `open` states and the HTML twin
/// renders both as the shared field focus ring - but the trigger used to be a
/// bare `GestureDetector`, so nothing under `UtopiaFieldWrapper` ever took
/// focus and neither state had a rendering in Flutter. The trigger now owns a
/// real `FocusNode`, which is what makes the wrapper light the ring.
void main() {
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
      .firstWhere((node) => node?.debugLabel == 'UtopiaDropdownField trigger')!;

  Widget buildApp({void Function(String)? onChanged}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: UtopiaDropdownField<String>(
            label: 'Role',
            value: 'Editor',
            values: const ['Admin', 'Editor'],
            valueLabelBuilder: (value) => value,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );

  testWidgets('opening the popup rings the trigger, and focus survives picking an option', (tester) async {
    final theme = UtopiaThemeData.defaultTheme;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(wrapperDecoration(tester), theme.fieldDecoration, reason: 'the resting trigger must not ring');

    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsOneWidget, reason: 'tapping the trigger opens the popup');
    expect(
      wrapperDecoration(tester),
      theme.fieldFocusDecoration,
      reason: 'an open popup means its trigger is the active control - the field must ring',
    );

    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsNothing, reason: 'picking an option closes the popup');
    expect(
      wrapperDecoration(tester),
      theme.fieldFocusDecoration,
      reason: 'the trigger stays the focused control after the popup closes',
    );
  });

  testWidgets('a keyboard-focused trigger opens on Enter and on Space', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    triggerNode(tester).requestFocus();
    await tester.pumpAndSettle();
    expect(
      wrapperDecoration(tester),
      UtopiaThemeData.defaultTheme.fieldFocusDecoration,
      reason: 'reaching the trigger with the keyboard rings the field like a focused text field',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsOneWidget, reason: 'Enter opens the popup');

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsNothing, reason: 'tapping the barrier dismisses the popup');

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsOneWidget, reason: 'Space opens the popup');
  });
}
