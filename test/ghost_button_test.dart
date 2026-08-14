import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  testWidgets('ghost button: renders its label, fires onTap and keeps the dense button height', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: UtopiaTheme(
          data: UtopiaThemeData.defaultTheme,
          child: Scaffold(
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // IntrinsicHeight: the ghost button only pins a *minimum*
                  // height, so a loose Row would let it stretch.
                  IntrinsicHeight(
                    child: UtopiaGhostButton(label: 'Cancel', onTap: () => taps++),
                  ),
                  UtopiaButton(dense: true, maxWidth: 100, onTap: () {}, child: const Text('Save')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.byType(UtopiaGhostButton));
    await tester.pumpAndSettle();
    expect(taps, 1);

    expect(
      tester.getSize(find.byType(UtopiaGhostButton)).height,
      moreOrLessEquals(tester.getSize(find.byType(UtopiaButton)).height, epsilon: 0.5),
      reason: 'the ghost button must match the dense button extent so action rows line up',
    );
  });
}
