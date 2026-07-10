import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// Regression probe for the vertical rhythm of the shared field chrome.
///
/// The label/value stack is deliberately biased 0.5x (2px) downwards in the
/// box: the value's line box reserves descender space below the baseline that
/// digits/caps never fill, so box-symmetric centring reads as bottom-heavy.
/// The theme compensates with asymmetric vertical fieldContentPadding
/// (top 2.5x, bottom 1.5x) - this test pins that intent.
void main() {
  testWidgets('text field: error message sits flush with the field edge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: UtopiaTextField(
                value: '',
                onChanged: (_) {},
                hint: const Text('Email'),
                error: const Text('Required field'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fieldBox = tester.getRect(find.byType(UtopiaFieldWrapper));
    final errorBox = tester.getRect(find.text('Required field'));

    expect(
      errorBox.left,
      moreOrLessEquals(fieldBox.left, epsilon: 0.5),
      reason: 'error message must sit flush with the field chrome left edge',
    );
  });

  testWidgets('widget hint renders in the placeholder style, not the ambient default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: UtopiaTextField(value: '', hint: const Text('Type here...'), onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(UtopiaTextField));
    final expected = utopiaPlaceholderStyle(context);
    final style = tester.renderObject<RenderParagraph>(find.text('Type here...')).text.style!;

    expect(style.color, expected.color);
    expect(style.fontWeight, expected.fontWeight);
    expect(style.fontSize, expected.fontSize);
  });

  testWidgets('dense text field: matches the dense button height and drops the label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: UtopiaTextField(
                    value: '',
                    dense: true,
                    label: const Text('Name'),
                    hint: const Text('Search...'),
                    onChanged: (_) {},
                  ),
                ),
                UtopiaButton(dense: true, maxWidth: 100, onTap: () {}, child: const Text('Go')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fieldBox = tester.getRect(find.byType(UtopiaFieldWrapper));
    final buttonBox = tester.getRect(find.byType(UtopiaButton));

    expect(
      fieldBox.height,
      moreOrLessEquals(buttonBox.height, epsilon: 0.5),
      reason: 'dense field chrome must match the dense button extent exactly',
    );
    expect(find.text('Name'), findsNothing);
    expect(find.text('Search...'), findsOneWidget);
  });

  testWidgets('dense search field: matches the dense button height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: UtopiaSearchField(value: '', hint: 'Search...', dense: true, onChanged: (_) {}),
                ),
                UtopiaButton(dense: true, maxWidth: 100, onTap: () {}, child: const Text('Go')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fieldBox = tester.getRect(find.byType(UtopiaFieldWrapper));
    final buttonBox = tester.getRect(find.byType(UtopiaButton));

    expect(
      fieldBox.height,
      moreOrLessEquals(buttonBox.height, epsilon: 0.5),
      reason: 'dense search chrome must match the dense button extent exactly',
    );
  });

  testWidgets('multiline text field: resting label anchors to the top, not the centre', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: UtopiaTextField(value: '', onChanged: (_) {}, label: const Text('Body'), lines: 5),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fieldBox = tester.getRect(find.byType(UtopiaFieldWrapper));
    final labelBox = tester.getRect(find.text('Body').last);

    // A centred label would sit near fieldBox.height / 2 (~66); top-anchored
    // it stays within the first line's band.
    expect(
      labelBox.top - fieldBox.top,
      lessThan(40),
      reason: 'resting label must anchor to the top of a multiline field, not its vertical centre',
    );
  });

  testWidgets('multiline text field: floated label sits at the single-line top offset', (tester) async {
    Widget field({required int lines, required String label}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: UtopiaTextField(value: 'Hello', onChanged: (_) {}, label: Text(label), lines: lines),
          ),
        ),
      ),
    );

    await tester.pumpWidget(field(lines: 1, label: 'Title'));
    await tester.pumpAndSettle();
    final singleGap =
        tester.getRect(find.text('Title').last).top - tester.getRect(find.byType(UtopiaFieldWrapper)).top;

    await tester.pumpWidget(field(lines: 5, label: 'Body'));
    await tester.pumpAndSettle();
    final multiGap =
        tester.getRect(find.text('Body').last).top - tester.getRect(find.byType(UtopiaFieldWrapper)).top;

    expect(
      multiGap,
      moreOrLessEquals(singleGap, epsilon: 1.0),
      reason: 'multiline floated label must not carry extra headroom over the single-line offset',
    );
  });

  testWidgets('labeled field: content stack carries the intended optical bias', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: UtopiaLabeledField(
                label: 'Published',
                value: '14 Mar 2026',
                suffix: Icon(Icons.close),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fieldBox = tester.getRect(find.byType(UtopiaFieldWrapper));
    final labelBox = tester.getRect(find.text('Published'));
    final valueBox = tester.getRect(find.text('14 Mar 2026'));

    final gapAboveLabel = labelBox.top - fieldBox.top;
    final gapBelowValue = fieldBox.bottom - valueBox.bottom;

    // Top box gap should exceed the bottom one by exactly the 1x padding bias
    // (2.5x - 1.5x at the default base of 4 -> 4 logical pixels).
    expect(
      gapAboveLabel - gapBelowValue,
      moreOrLessEquals(4.0, epsilon: 1.0),
      reason: 'expected the 1x downward optical bias: above=$gapAboveLabel below=$gapBelowValue',
    );
  });
}
