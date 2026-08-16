import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// Behaviour and geometry probes for the Material-free [UtopiaRadio].
///
/// The button draws its own ring and dot, so nothing else pins its selection
/// rule (`value == groupValue`), its interaction rules (tap, readOnly,
/// disabled) or its token-derived extent - these tests do.
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

  double opacityOf(WidgetTester tester) => tester
      .widget<Opacity>(find.descendant(of: find.byType(UtopiaRadio<String>), matching: find.byType(Opacity)))
      .opacity;

  Size dotSize(WidgetTester tester) =>
      tester.getSize(find.descendant(of: find.byType(UtopiaRadio<String>), matching: find.byType(Container)).last);

  testWidgets('radio: value == groupValue selects, and a tap reports the option', (tester) async {
    final changes = <String>[];

    await tester.pumpWidget(host(UtopiaRadio<String>(value: 'pro', groupValue: 'free', onChanged: changes.add)));
    await tester.pumpAndSettle();
    expect(dotSize(tester), Size.zero, reason: 'an unselected radio carries no dot');

    await tester.tap(find.byType(UtopiaRadio<String>));
    await tester.pumpAndSettle();
    expect(changes, ['pro'], reason: 'a radio reports its own option, never a flipped value');

    await tester.pumpWidget(host(UtopiaRadio<String>(value: 'pro', groupValue: 'pro', onChanged: changes.add)));
    await tester.pumpAndSettle();
    expect(dotSize(tester), const Size(6, 6), reason: 'a selected radio carries an x*1.5 dot at the default base');

    // Re-selecting still reports: the group's owner decides what that means.
    await tester.tap(find.byType(UtopiaRadio<String>));
    await tester.pumpAndSettle();
    expect(changes, ['pro', 'pro']);
  });

  testWidgets('radio: a null onChanged is inert and faded', (tester) async {
    await tester.pumpWidget(host(const UtopiaRadio<String>(value: 'pro', groupValue: 'pro')));
    await tester.pumpAndSettle();

    final gesture = tester.widget<GestureDetector>(
      find.descendant(of: find.byType(UtopiaRadio<String>), matching: find.byType(GestureDetector)),
    );

    expect(gesture.onTap, isNull, reason: 'a disabled radio must not accept taps');
    expect(opacityOf(tester), 0.5, reason: 'a disabled radio must carry a visual disabled affordance');

    // Tapping a disabled radio stays a no-op rather than throwing.
    await tester.tap(find.byType(UtopiaRadio<String>));
    await tester.pumpAndSettle();
  });

  testWidgets('radio: readOnly is inert but keeps the full-colour styling', (tester) async {
    final changes = <String>[];

    await tester.pumpWidget(
      host(UtopiaRadio<String>(value: 'pro', groupValue: 'pro', readOnly: true, onChanged: changes.add)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UtopiaRadio<String>));
    await tester.pumpAndSettle();

    expect(changes, isEmpty, reason: 'readOnly must not report changes');
    expect(
      opacityOf(tester),
      1.0,
      reason: 'readOnly is a display-of-state mode, not a disabled control - it must not fade',
    );
  });

  testWidgets('radio: semantics report a checked option in a mutually exclusive group', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(host(UtopiaRadio<String>(value: 'pro', groupValue: 'pro', onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(UtopiaRadio<String>)),
      isSemantics(
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    await tester.pumpWidget(host(const UtopiaRadio<String>(value: 'pro', groupValue: 'free')));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(UtopiaRadio<String>)),
      isSemantics(
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );

    handle.dispose();
  });

  testWidgets('radio: extent follows the token base', (tester) async {
    await tester.pumpWidget(host(UtopiaRadio<String>(value: 'pro', groupValue: 'pro', onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(UtopiaRadio<String>)),
      const Size(20, 20),
      reason: 'default base 4 must give a 5x circle - the same extent as UtopiaCheckbox',
    );

    await tester.pumpWidget(host(UtopiaRadio<String>(value: 'pro', groupValue: 'pro', onChanged: (_) {}), base: 5));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(UtopiaRadio<String>)),
      const Size(25, 25),
      reason: 'a rebranded base of 5 must rescale the button with every other control',
    );
  });
}
