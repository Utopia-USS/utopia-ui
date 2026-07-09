import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  testWidgets('barrel smoke test: themed button renders and taps', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: UtopiaTheme(
          data: UtopiaThemeData.defaultTheme,
          child: Scaffold(
            body: Center(
              child: UtopiaButton(onTap: () => tapped = true, child: const Text('Get started')),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.byType(UtopiaButton));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
