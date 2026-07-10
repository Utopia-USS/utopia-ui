import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  testWidgets('button: keeps its exact size when loading swaps the label for the loader', (tester) async {
    Widget app({required bool loading}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IntrinsicWidth(
                child: UtopiaButton(
                  dense: true,
                  loading: loading,
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Publish'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Plain pump()s throughout: the loader animates forever, so
    // pumpAndSettle() would never return while loading is true.
    await tester.pumpWidget(app(loading: false));
    await tester.pump();
    final restingSize = tester.getSize(find.byType(UtopiaButton));

    await tester.pumpWidget(app(loading: true));
    await tester.pump(const Duration(milliseconds: 100));
    final loadingSize = tester.getSize(find.byType(UtopiaButton));

    expect(
      loadingSize,
      restingSize,
      reason: 'the loading state must not change the button size',
    );
  });
}
