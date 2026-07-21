import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: UtopiaTheme(
      data: UtopiaThemeData.defaultTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('ghost button: renders its label and fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(host(UtopiaGhostButton(label: 'Cancel', onTap: () => tapped = true)));
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.byType(UtopiaGhostButton));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('header: renders its title with the header text style', (tester) async {
    await tester.pumpWidget(host(const UtopiaHeader(title: 'Settings')));
    final text = tester.widget<Text>(find.text('Settings'));
    expect(text.style, UtopiaThemeData.defaultTheme.textStyles.header);
  });
}
