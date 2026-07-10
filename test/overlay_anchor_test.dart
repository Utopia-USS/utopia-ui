import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  testWidgets('overlay anchor works inside IntrinsicHeight', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300,
                    child: UtopiaDropdownField<String>(
                      label: 'Role',
                      value: 'Editor',
                      values: const ['Admin', 'Editor'],
                      valueLabelBuilder: (value) => value,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('open popup matches the trigger width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: UtopiaDropdownField<String>(
                label: 'Role',
                value: 'Editor',
                values: const ['Admin', 'Editor'],
                valueLabelBuilder: (value) => value,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();

    final popup = tester.getRect(find.text('Admin'));
    expect(popup.width, lessThanOrEqualTo(300));
    final anchor = tester.getRect(find.byType(UtopiaDropdownField<String>));
    final popupBox = tester.getRect(
      find.ancestor(of: find.text('Admin'), matching: find.byType(Container)).first,
    );
    expect(popupBox.width, moreOrLessEquals(anchor.width, epsilon: 1));
  });
}
