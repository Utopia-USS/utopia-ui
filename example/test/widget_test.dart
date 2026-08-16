import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utopia_ui_example/main.dart';

void main() {
  Future<void> pumpShowcase(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const DesignSystemApp());
    // Loader/pulse animations never settle; pump a few frames instead.
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('lands on the single-page showcase with the theme lab', (tester) async {
    await pumpShowcase(tester);

    expect(find.text('utopia_ui'), findsOneWidget);
    expect(find.text('Theme lab'), findsWidgets);
    expect(find.text('Tap to copy'), findsOneWidget);
    expect(find.textContaining('UtopiaThemeData.fromTokens'), findsOneWidget);
  });

  testWidgets('preset pill re-themes the whole page', (tester) async {
    await pumpShowcase(tester);

    await tester.tap(find.text('Dracula'));
    await tester.pump(const Duration(milliseconds: 100));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF1E1F29));
  });

  testWidgets('base unit knob rescales the system and updates the paste-back block', (tester) async {
    await pumpShowcase(tester);

    expect(find.textContaining('const UtopiaTokens()'), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('labSlider_Base unit x')), const Offset(300, 0));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('UtopiaTokens.fromBase'), findsOneWidget);
  });
}
