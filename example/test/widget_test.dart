import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utopia_ui_example/main.dart';

void main() {
  testWidgets('Design system sheet renders its header and sections', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DesignSystemApp());
    // Shimmer / loader animations never settle, so pump a handful of frames
    // instead of pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('utopia_ui'), findsOneWidget);
    expect(find.text('Colors'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
  });
}
