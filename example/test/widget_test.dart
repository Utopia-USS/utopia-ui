import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utopia_ui_example/main.dart';

void main() {
  testWidgets('Shell lands on the dashboard with the sidebar rail', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DesignSystemApp());
    // Shimmer / loader animations never settle, so pump a handful of frames
    // instead of pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('New invoice'), findsOneWidget);
    expect(find.byIcon(Icons.space_dashboard_outlined), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('Sidebar navigates to the components reference page', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DesignSystemApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.widgets_outlined));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Colors'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
  });

  testWidgets('Sidebar navigates to the editor and settings pages', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DesignSystemApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.edit_note_outlined));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Show advanced options'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Danger zone'), findsOneWidget);
    expect(find.text('Weekly digest'), findsOneWidget);
  });

  testWidgets('Editor page scrolls, including from the gutter beside the form', (tester) async {
    tester.view.physicalSize = const Size(1600, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DesignSystemApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.edit_note_outlined));
    await tester.pump(const Duration(milliseconds: 400));

    final before = tester.getTopLeft(find.text('Show advanced options'));
    // Gutter drag - only moves if the scroll view spans the full page width.
    await tester.dragFrom(const Offset(150, 400), const Offset(0, -200));
    await tester.pump();
    final after = tester.getTopLeft(find.text('Show advanced options'));
    expect(after.dy, lessThan(before.dy));
  });

  testWidgets('Mobile shell hosts the sidebar in a drawer and closes it after a tap', (tester) async {
    tester.view.physicalSize = const Size(480, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DesignSystemApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.space_dashboard_outlined), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    // One pump to start the drawer animation, one to finish it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.space_dashboard_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Danger zone'), findsOneWidget);
    expect(find.byIcon(Icons.space_dashboard_outlined), findsNothing);
  });
}
