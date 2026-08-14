import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// Behaviour and geometry probes for the Material-free [UtopiaSwitch].
///
/// The switch draws its own track and thumb, so nothing else pins its
/// interaction rules (tap, readOnly, disabled) or its token-derived extent -
/// these tests do.
void main() {
  Widget host(Widget child, {double base = 4}) => MaterialApp(
    home: UtopiaTheme(
      data: UtopiaThemeData.fromTokens(
        colors: UtopiaThemeColors.defaultTheme,
        textStyles: UtopiaThemeTextStyles.defaultTheme,
        tokens: UtopiaTokens.fromBase(base),
      ),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  double opacityOf(WidgetTester tester) =>
      tester.widget<Opacity>(find.descendant(of: find.byType(UtopiaSwitch), matching: find.byType(Opacity))).opacity;

  testWidgets('switch: tapping reports the flipped value', (tester) async {
    final changes = <bool>[];

    await tester.pumpWidget(host(UtopiaSwitch(value: false, onChanged: changes.add)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UtopiaSwitch));
    await tester.pumpAndSettle();
    expect(changes, [true]);

    await tester.pumpWidget(host(UtopiaSwitch(value: true, onChanged: changes.add)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UtopiaSwitch));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
  });

  testWidgets('switch: readOnly is inert but keeps the full-colour styling', (tester) async {
    final changes = <bool>[];

    await tester.pumpWidget(host(UtopiaSwitch(value: true, readOnly: true, onChanged: changes.add)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UtopiaSwitch));
    await tester.pumpAndSettle();

    expect(changes, isEmpty, reason: 'readOnly must not report changes');
    expect(
      opacityOf(tester),
      1.0,
      reason: 'readOnly is a display-of-state mode, not a disabled control - it must not fade',
    );
  });

  testWidgets('switch: a null onChanged is inert and faded', (tester) async {
    await tester.pumpWidget(host(const UtopiaSwitch(value: true)));
    await tester.pumpAndSettle();

    final gesture = tester.widget<GestureDetector>(
      find.descendant(of: find.byType(UtopiaSwitch), matching: find.byType(GestureDetector)),
    );

    expect(gesture.onTap, isNull, reason: 'a disabled switch must not accept taps');
    expect(opacityOf(tester), 0.5, reason: 'a disabled switch must carry a visual disabled affordance');

    // Tapping a disabled switch stays a no-op rather than throwing.
    await tester.tap(find.byType(UtopiaSwitch));
    await tester.pumpAndSettle();
  });

  testWidgets('switch: semantics report the toggled and enabled state', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(host(UtopiaSwitch(value: true, onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(UtopiaSwitch)),
      isSemantics(hasToggledState: true, isToggled: true, hasEnabledState: true, isEnabled: true),
    );

    await tester.pumpWidget(host(const UtopiaSwitch(value: false)));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(UtopiaSwitch)),
      isSemantics(hasToggledState: true, isToggled: false, hasEnabledState: true, isEnabled: false),
    );

    handle.dispose();
  });

  testWidgets('switch: track extent follows the token base', (tester) async {
    await tester.pumpWidget(host(UtopiaSwitch(value: false, onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(UtopiaSwitch)),
      const Size(40, 24),
      reason: 'default base 4 must give a 10x by 6x track',
    );

    await tester.pumpWidget(host(UtopiaSwitch(value: false, onChanged: (_) {}), base: 5));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(UtopiaSwitch)),
      const Size(50, 30),
      reason: 'a rebranded base of 5 must rescale the track with every other control',
    );
  });
}
