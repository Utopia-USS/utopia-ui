import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// Behaviour and geometry probes for the Material-free [UtopiaCheckbox].
///
/// The box draws its own chrome and glyphs, so nothing else pins its
/// interaction rules (tap, readOnly, disabled), its indeterminate rendering or
/// its token-derived extent - these tests do.
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
      tester.widget<Opacity>(find.descendant(of: find.byType(UtopiaCheckbox), matching: find.byType(Opacity))).opacity;

  testWidgets('checkbox: tapping reports the flipped value', (tester) async {
    final changes = <bool>[];

    await tester.pumpWidget(host(UtopiaCheckbox(value: false, onChanged: changes.add)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UtopiaCheckbox));
    await tester.pumpAndSettle();
    expect(changes, [true]);

    await tester.pumpWidget(host(UtopiaCheckbox(value: true, onChanged: changes.add)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UtopiaCheckbox));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
  });

  testWidgets('checkbox: a null onChanged is inert and faded', (tester) async {
    await tester.pumpWidget(host(const UtopiaCheckbox(value: true)));
    await tester.pumpAndSettle();

    final gesture = tester.widget<GestureDetector>(
      find.descendant(of: find.byType(UtopiaCheckbox), matching: find.byType(GestureDetector)),
    );

    expect(gesture.onTap, isNull, reason: 'a disabled check box must not accept taps');
    expect(opacityOf(tester), 0.5, reason: 'a disabled check box must carry a visual disabled affordance');

    // Tapping a disabled box stays a no-op rather than throwing.
    await tester.tap(find.byType(UtopiaCheckbox));
    await tester.pumpAndSettle();
  });

  testWidgets('checkbox: readOnly is inert but keeps the full-colour styling', (tester) async {
    final changes = <bool>[];

    await tester.pumpWidget(host(UtopiaCheckbox(value: true, readOnly: true, onChanged: changes.add)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UtopiaCheckbox));
    await tester.pumpAndSettle();

    expect(changes, isEmpty, reason: 'readOnly must not report changes');
    expect(
      opacityOf(tester),
      1.0,
      reason: 'readOnly is a display-of-state mode, not a disabled control - it must not fade',
    );
  });

  testWidgets('checkbox: indeterminate draws the mixed bar instead of the check glyph', (tester) async {
    await tester.pumpWidget(host(UtopiaCheckbox(value: false, indeterminate: true, onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNothing, reason: 'the mixed state replaces the check glyph with a bar');

    final glyph = find.descendant(of: find.byType(UtopiaCheckbox), matching: find.byType(Container)).last;
    expect(
      tester.getSize(glyph),
      const Size(10, 2),
      reason: 'the mixed bar is x*2.5 wide and borders.thick tall at the default base',
    );

    // The flag is presentational: a tap still reports the flipped value.
    final changes = <bool>[];
    await tester.pumpWidget(host(UtopiaCheckbox(value: false, indeterminate: true, onChanged: changes.add)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(UtopiaCheckbox));
    await tester.pumpAndSettle();
    expect(changes, [true]);
  });

  testWidgets('checkbox: a checked box draws the check glyph', (tester) async {
    await tester.pumpWidget(host(UtopiaCheckbox(value: true, onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('checkbox: semantics report the checked, mixed and enabled state', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(host(UtopiaCheckbox(value: true, onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(UtopiaCheckbox)),
      isSemantics(hasCheckedState: true, isChecked: true, hasEnabledState: true, isEnabled: true),
    );

    await tester.pumpWidget(host(const UtopiaCheckbox(value: false)));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(UtopiaCheckbox)),
      isSemantics(hasCheckedState: true, isChecked: false, hasEnabledState: true, isEnabled: false),
    );

    await tester.pumpWidget(host(UtopiaCheckbox(value: false, indeterminate: true, onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(UtopiaCheckbox)),
      isSemantics(isCheckStateMixed: true, isChecked: false, hasEnabledState: true, isEnabled: true),
    );

    handle.dispose();
  });

  testWidgets('checkbox: extent follows the token base', (tester) async {
    await tester.pumpWidget(host(UtopiaCheckbox(value: false, onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(UtopiaCheckbox)),
      const Size(20, 20),
      reason: 'default base 4 must give a 5x square',
    );

    await tester.pumpWidget(host(UtopiaCheckbox(value: false, onChanged: (_) {}), base: 5));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(UtopiaCheckbox)),
      const Size(25, 25),
      reason: 'a rebranded base of 5 must rescale the box with every other control',
    );
  });
}
