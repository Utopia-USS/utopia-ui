import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// Column-level presentation contracts of `UtopiaTable`: what a column declared
/// `numeric` does to its cells and to its own label, and what the sorted column
/// says about its direction.
void main() {
  final rows = ['a', 'b'].toIList();

  IList<UtopiaTableEntry<String>> entries() => [
    UtopiaTableEntry<String>.fixed(id: 'id', title: 'Id', width: 120, cellBuilder: (context, row) => Text('id-$row')),
    UtopiaTableEntry<String>(
      id: 'name',
      title: 'Name',
      sortBy: (row) => row,
      cellBuilder: (context, row) => Text('name-$row'),
    ),
    UtopiaTableEntry<String>.fixed(
      id: 'amount',
      title: 'Amount',
      width: 160,
      numeric: true,
      sortBy: (row) => row,
      // A cell style of the caller's own, to prove the numeric figure style
      // survives the merge instead of being replaced by it.
      cellBuilder: (context, row) => Text('9-$row', style: const TextStyle(fontSize: 12)),
    ),
  ].toIList();

  Widget host({UtopiaTableSort? sort}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 800,
            child: CustomScrollView(
              slivers: [
                UtopiaTable<String>(
                  rows: rows,
                  entries: entries(),
                  rowKey: (row) => row,
                  currentSort: sort,
                  onSortPressed: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DefaultTextStyle cellStyleOf(WidgetTester tester, String text) => tester.widget<DefaultTextStyle>(
    find.ancestor(of: find.text(text), matching: find.byType(DefaultTextStyle)).first,
  );

  Align cellAlignOf(WidgetTester tester, String text) =>
      tester.widget<Align>(find.ancestor(of: find.text(text), matching: find.byType(Align)).first);

  testWidgets('a numeric column trails its cells and its own label on the same edge', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(cellAlignOf(tester, '9-a').alignment, Alignment.centerRight);
    expect(cellAlignOf(tester, 'id-a').alignment, Alignment.centerLeft);

    // The column label stands exactly over its digits - the point of declaring
    // a column numeric at all.
    expect(
      tester.getTopRight(find.text('9-a')).dx,
      moreOrLessEquals(tester.getTopRight(find.text('Amount')).dx, epsilon: 0.5),
    );
    expect(
      tester.getTopLeft(find.text('id-a')).dx,
      moreOrLessEquals(tester.getTopLeft(find.text('Id')).dx, epsilon: 0.5),
    );
  });

  testWidgets('a numeric column renders its cells with tabular figures', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    final numericStyle = cellStyleOf(tester, '9-a');
    expect(numericStyle.style.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(numericStyle.textAlign, TextAlign.right);

    final plainStyle = cellStyleOf(tester, 'id-a');
    expect(plainStyle.style.fontFeatures ?? const <FontFeature>[], isEmpty);
    expect(plainStyle.textAlign, isNull);

    // The caller's own cell style merges onto the figure style rather than
    // replacing it, so a styled numeric cell keeps its tabular digits.
    final paragraph = tester.renderObject<RenderParagraph>(find.text('9-a'));
    expect(paragraph.text.style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(paragraph.text.style?.fontSize, 12);
  });

  testWidgets('the sorted column states its direction, the rest stay silent', (tester) async {
    await tester.pumpWidget(host(sort: (columnId: 'name', descending: false)));
    await tester.pump();

    // One caret per sortable column (the slot is reserved in every state), but
    // only the sorted one points: ascending is up, descending is down.
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);

    await tester.pumpWidget(host(sort: (columnId: 'name', descending: true)));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });
}
