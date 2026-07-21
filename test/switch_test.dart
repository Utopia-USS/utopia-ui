import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  Widget host(Widget child, {UtopiaThemeData? theme}) => MaterialApp(
    home: UtopiaTheme(
      data: theme ?? UtopiaThemeData.defaultTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('switch: tapping an interactive switch reports the toggled value', (tester) async {
    bool? received;
    await tester.pumpWidget(host(UtopiaSwitch(value: false, onChanged: (v) => received = v)));
    await tester.tap(find.byType(UtopiaSwitch));
    await tester.pump();
    expect(received, isTrue, reason: 'onChanged must fire with the negated value');
  });

  testWidgets('switch: a read-only switch ignores taps', (tester) async {
    var changed = false;
    await tester.pumpWidget(
      host(UtopiaSwitch(value: true, readOnly: true, onChanged: (_) => changed = true)),
    );
    await tester.tap(find.byType(UtopiaSwitch));
    await tester.pump();
    expect(changed, isFalse, reason: 'readOnly must block interaction');
  });

  testWidgets('switch: a null onChanged renders and swallows taps without error', (tester) async {
    await tester.pumpWidget(host(const UtopiaSwitch(value: false)));
    await tester.tap(find.byType(UtopiaSwitch));
    await tester.pump();
    expect(find.byType(UtopiaSwitch), findsOneWidget);
  });

  testWidgets('switch: track extent scales with the theme base unit', (tester) async {
    await tester.pumpWidget(host(const UtopiaSwitch(value: false)));
    await tester.pump();
    expect(
      tester.getSize(find.byType(UtopiaSwitch)),
      const Size(40, 24),
      reason: 'default base unit (x=4): x*10 by x*6',
    );

    await tester.pumpWidget(
      host(
        const UtopiaSwitch(value: false),
        theme: UtopiaThemeData.fromTokens(
          colors: UtopiaThemeColors.defaultTheme,
          textStyles: UtopiaThemeTextStyles.defaultTheme,
          tokens: UtopiaTokens.fromBase(5),
        ),
      ),
    );
    // AnimatedContainer animates the extent change; settle to its final size.
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(UtopiaSwitch)),
      const Size(50, 30),
      reason: 'rebrand base unit (x=5): the switch must scale like every other control',
    );
  });

  testWidgets('switch: exposes its on/off state to semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(UtopiaSwitch(value: true, onChanged: (_) {})));
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(UtopiaSwitch)),
      matchesSemantics(
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
