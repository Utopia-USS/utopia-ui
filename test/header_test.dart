import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  testWidgets('header: renders its title in the header text style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UtopiaTheme(
          data: UtopiaThemeData.defaultTheme,
          child: const Scaffold(
            body: Center(child: UtopiaHeader(title: 'Invoices')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final expected = UtopiaThemeData.defaultTheme.textStyles.header;
    final style = tester.renderObject<RenderParagraph>(find.text('Invoices')).text.style!;

    expect(find.text('Invoices'), findsOneWidget);
    expect(style.fontSize, expected.fontSize);
    expect(style.fontWeight, expected.fontWeight);
    expect(style.color, expected.color);
  });
}
