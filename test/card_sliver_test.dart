import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/src/widget/layout/utopia_card.dart';

/// Paint smoke test for the sliver card chrome: content taller than the
/// viewport, with a pinned header and repaint-boundary children (forcing the
/// compositing path through pushClipRRect), painted at several scroll
/// offsets. Guards the "stale canvas after layer push" crash class.
void main() {
  testWidgets('sliver card chrome paints across scroll positions without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 460,
            child: Builder(
              builder: (context) => CustomScrollView(
                slivers: [
                  utopiaCardSliver(
                    context,
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        const PinnedHeaderSliver(
                          child: SizedBox(height: 140, child: ColoredBox(color: Colors.white)),
                        ),
                        SliverList.builder(
                          itemCount: 30,
                          itemBuilder: (context, index) => RepaintBoundary(
                            child: SizedBox(height: 58, child: Text('row $index')),
                          ),
                        ),
                      ],
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

    // Scroll partway and to the end - the chrome repaints against a moving
    // visible extent each time.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('row 29'), findsOneWidget);
  });
}
