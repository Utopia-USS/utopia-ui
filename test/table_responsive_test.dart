import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  final rows = ['a', 'b'].toIList();

  IList<UtopiaTableEntry<String>> entries({String longValue = 'value'}) => [
    UtopiaTableEntry<String>.fixed(
      title: 'Id',
      width: 110,
      hidePriority: 2,
      cellBuilder: (context, row) => Text('id-$row'),
    ),
    UtopiaTableEntry<String>(
      title: 'Name',
      cellBuilder: (context, row) => Text('$longValue-$row'),
    ),
    UtopiaTableEntry<String>.fixed(
      title: 'Issued',
      width: 130,
      hidePriority: 3,
      cellBuilder: (context, row) => Text('issued-$row'),
    ),
    UtopiaTableEntry<String>.fixed(
      title: 'Amount',
      width: 130,
      cellBuilder: (context, row) => Text('amount-$row'),
    ),
  ].toIList();

  Widget host(double width, {String longValue = 'value'}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: CustomScrollView(
              slivers: [
                UtopiaTable<String>(
                  rows: rows,
                  entries: entries(longValue: longValue),
                  rowKey: (row) => row,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('wide table shows every column', (tester) async {
    await tester.pumpWidget(host(800));
    await tester.pump();

    expect(find.text('Id'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Issued'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
  });

  testWidgets('narrow table hides columns by hidePriority, highest first', (tester) async {
    // Footprints: 110 + 120 (flex min) + 130 + 130 + 32 padding = 522.
    await tester.pumpWidget(host(450));
    await tester.pump();

    expect(find.text('Issued'), findsNothing);
    expect(find.text('issued-a'), findsNothing);
    expect(find.text('Id'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);

    await tester.pumpWidget(host(350));
    await tester.pump();

    expect(find.text('Issued'), findsNothing);
    expect(find.text('Id'), findsNothing);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
  });

  testWidgets('priority-0 columns never hide, even when they overflow', (tester) async {
    await tester.pumpWidget(host(200));
    await tester.pump();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
  });

  testWidgets('cell text ellipsizes on one line instead of wrapping', (tester) async {
    final long = List.filled(12, 'longword').join(' ');
    await tester.pumpWidget(host(500, longValue: long));
    await tester.pump();

    final rowText = find.text('$long-a');
    expect(rowText, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(rowText);
    expect(paragraph.size.height, lessThan(30), reason: 'cell text must stay on a single line');
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.softWrap, isFalse);
  });
}
