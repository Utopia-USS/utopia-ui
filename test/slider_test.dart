import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// Behaviour and geometry probes for the Material-free [UtopiaSlider].
///
/// The slider draws its own track, fill and thumb and resolves every reported
/// value itself, so nothing else pins its pointer arithmetic (a tap jumps, a
/// drag follows), its snapping, its interaction rules (readOnly, disabled) or
/// its token-derived geometry - these tests do.
void main() {
  /// Hosts the slider at a fixed 200px width so pointer positions map to
  /// values by hand: the thumb's centre travels between the half-thumb
  /// insets, i.e. over `200 - 20 = 180` logical pixels at the default base.
  Widget host(Widget child, {double base = 4, double width = 200}) => MaterialApp(
    home: UtopiaTheme(
      data: UtopiaThemeData.fromTokens(
        colors: UtopiaThemeColors.defaultTheme,
        textStyles: UtopiaThemeTextStyles.defaultTheme,
        tokens: UtopiaTokens.fromBase(base),
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );

  double opacityOf(WidgetTester tester) =>
      tester.widget<Opacity>(find.descendant(of: find.byType(UtopiaSlider), matching: find.byType(Opacity))).opacity;

  GestureDetector gestureOf(WidgetTester tester) => tester.widget<GestureDetector>(
    find.descendant(of: find.byType(UtopiaSlider), matching: find.byType(GestureDetector)),
  );

  /// The thumb: the last of the slider's animated boxes (the fill is the
  /// first).
  Size thumbSize(WidgetTester tester) =>
      tester.getSize(find.descendant(of: find.byType(UtopiaSlider), matching: find.byType(AnimatedContainer)).last);

  /// Taps the slider [dx] logical pixels from its left edge.
  Future<void> tapAtOffset(WidgetTester tester, double dx) async {
    final topLeft = tester.getTopLeft(find.byType(UtopiaSlider));
    await tester.tapAt(topLeft + Offset(dx, 10));
    await tester.pumpAndSettle();
  }

  testWidgets('slider: a tap on the track jumps to the value under the pointer', (tester) async {
    final changes = <double>[];

    await tester.pumpWidget(host(UtopiaSlider(value: 0, onChanged: changes.add)));
    await tester.pumpAndSettle();

    // 100px from the left edge: (100 - 10) / 180 of the [0, 1] range.
    await tapAtOffset(tester, 100);
    expect(changes.single, closeTo(0.5, 0.0001), reason: 'a tap must report the value under the pointer');

    // Inside the trailing half-thumb inset the arithmetic overshoots the
    // range, so the reported value clamps to max.
    await tapAtOffset(tester, 195);
    expect(changes.last, 1, reason: 'a tap past the thumb travel must clamp to max');
  });

  testWidgets('slider: a drag reports the value continuously and honours min/max', (tester) async {
    final changes = <double>[];

    await tester.pumpWidget(host(UtopiaSlider(value: 50, max: 100, onChanged: changes.add)));
    await tester.pumpAndSettle();

    // Grabs at the centre and moves 45px right, ending at local dx 145 ->
    // (145 - 10) / 180 of the [0, 100] range. The first report lands wherever
    // the drag recognizer won the arena (a touch slop past the grab point),
    // so only the direction and the endpoint are pinned here.
    await tester.drag(find.byType(UtopiaSlider), const Offset(45, 0));
    await tester.pumpAndSettle();

    expect(changes, isNotEmpty, reason: 'a drag must report while the pointer moves');
    expect(changes.first, greaterThan(50), reason: 'dragging right must move the value up from where it started');
    expect(changes.last, closeTo(75, 0.0001), reason: 'the drag end reports the value under the released pointer');
  });

  testWidgets('slider: divisions snap every reported value to a step', (tester) async {
    final changes = <double>[];

    await tester.pumpWidget(host(UtopiaSlider(value: 0, divisions: 4, onChanged: changes.add)));
    await tester.pumpAndSettle();

    // 90px from the left edge is (90 - 10) / 180 = 0.444..., which snaps to
    // the nearest quarter.
    await tapAtOffset(tester, 90);
    expect(changes.single, closeTo(0.5, 0.0001), reason: 'a stepped slider must never report an unreachable value');

    await tapAtOffset(tester, 60);
    expect(changes.last, closeTo(0.25, 0.0001));
  });

  testWidgets('slider: a null onChanged is inert and faded', (tester) async {
    await tester.pumpWidget(host(const UtopiaSlider(value: 0.4)));
    await tester.pumpAndSettle();

    final gesture = gestureOf(tester);
    expect(gesture.onTapUp, isNull, reason: 'a disabled slider must not accept taps');
    expect(gesture.onHorizontalDragUpdate, isNull, reason: 'a disabled slider must not accept drags');
    expect(opacityOf(tester), 0.5, reason: 'a disabled slider must carry a visual disabled affordance');

    // Interacting with a disabled slider stays a no-op rather than throwing.
    await tapAtOffset(tester, 100);
    await tester.drag(find.byType(UtopiaSlider), const Offset(45, 0));
    await tester.pumpAndSettle();
  });

  testWidgets('slider: readOnly is inert but keeps the full-colour styling', (tester) async {
    final changes = <double>[];

    await tester.pumpWidget(host(UtopiaSlider(value: 0.4, readOnly: true, onChanged: changes.add)));
    await tester.pumpAndSettle();

    await tapAtOffset(tester, 100);
    await tester.drag(find.byType(UtopiaSlider), const Offset(45, 0));
    await tester.pumpAndSettle();

    expect(changes, isEmpty, reason: 'readOnly must not report changes');
    expect(
      opacityOf(tester),
      1.0,
      reason: 'readOnly is a display-of-state mode, not a disabled control - it must not fade',
    );
  });

  testWidgets('slider: geometry follows the token base', (tester) async {
    await tester.pumpWidget(host(UtopiaSlider(value: 0.4, onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(UtopiaSlider)),
      const Size(200, 20),
      reason: 'the slider takes the available width and the thumb extent (x*5) as its height',
    );
    expect(
      thumbSize(tester),
      const Size(20, 20),
      reason: 'default base 4 must give an x*5 thumb - the selection family extent',
    );

    await tester.pumpWidget(host(UtopiaSlider(value: 0.4, onChanged: (_) {}), base: 5));
    await tester.pumpAndSettle();

    expect(
      thumbSize(tester),
      const Size(25, 25),
      reason: 'a rebranded base of 5 must rescale the thumb with every other control',
    );
  });

  testWidgets('slider: semantics expose an adjustable value', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = <double>[];

    await tester.pumpWidget(host(UtopiaSlider(value: 0.4, onChanged: changes.add)));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(UtopiaSlider)),
      isSemantics(
        isSlider: true,
        value: '0.4',
        increasedValue: '0.5',
        decreasedValue: '0.3',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    await tester.pumpWidget(host(const UtopiaSlider(value: 0.4)));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(UtopiaSlider)),
      isSemantics(isSlider: true, hasIncreaseAction: false, hasEnabledState: true, isEnabled: false),
      reason: 'a disabled slider offers no adjustment actions',
    );

    handle.dispose();
  });
}
