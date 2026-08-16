import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import 'pages/components_page.dart';
import 'state/theme_lab_state.dart';

void main() => runApp(const DesignSystemApp());

const _providers = <Type, Object? Function()>{ThemeLabState: useThemeLabState};

class DesignSystemApp extends HookWidget {
  const DesignSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'utopia_ui - Design System',
      debugShowCheckedModeBanner: false,
      home: const ShowcaseRoot(),
      builder: (context, child) =>
          HookProviderContainerWidget(_providers, alwaysNotifyDependents: false, child: child!),
    );
  }
}

class ShowcaseRoot extends HookWidget {
  const ShowcaseRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final lab = useProvided<ThemeLabState>();
    final theme = lab.buildTheme();
    return UtopiaTheme(
      data: theme,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: context.colors.canvas,
          body: const ComponentsPage(),
        ),
      ),
    );
  }
}
