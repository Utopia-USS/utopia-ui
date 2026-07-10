import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import 'pages/components_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/editor/editor_page.dart';
import 'pages/settings_page.dart';
import 'state/theme_mode_state.dart';
import 'theme.dart';

void main() => runApp(const DesignSystemApp());

const _providers = <Type, Object? Function()>{ThemeModeState: useThemeModeState};

/// The utopia_ui showcase: a small app driven entirely by the design
/// system, with a [UtopiaSidebar] rail navigating between working pages.
class DesignSystemApp extends HookWidget {
  const DesignSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'utopia_ui - Showcase',
      debugShowCheckedModeBanner: false,
      home: const ShowcaseShell(),
      builder: (context, child) =>
          HookProviderContainerWidget(_providers, alwaysNotifyDependents: false, child: child!),
    );
  }
}

/// The showcase's pages, one per sidebar destination; the enum's `name` doubles
/// as the [UtopiaSidebarDestination.id].
enum ShowcasePage {
  dashboard('Dashboard', Icons.space_dashboard_outlined),
  editor('Editor', Icons.edit_note_outlined),
  settings('Settings', Icons.settings_outlined),
  components('Components', Icons.widgets_outlined);

  final String label;
  final IconData icon;

  const ShowcasePage(this.label, this.icon);

  Widget build() => switch (this) {
    ShowcasePage.dashboard => const DashboardPage(),
    ShowcasePage.editor => const EditorPage(),
    ShowcasePage.settings => const SettingsPage(),
    ShowcasePage.components => const ComponentsPage(),
  };
}

/// Resolves the active theme and picks the rail or drawer shell by window width.
class ShowcaseShell extends HookWidget {
  const ShowcaseShell({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = useProvided<ThemeModeState>();
    final theme = themeFor(themeMode.mode.value);
    final selected = useState(ShowcasePage.dashboard);

    final isRail = MediaQuery.sizeOf(context).width >= theme.tokens.breakpoints.sidebarMin;
    return UtopiaTheme(
      data: theme,
      child: isRail ? _RailShell(selected: selected) : _MobileShell(selected: selected),
    );
  }
}

class _RailShell extends StatelessWidget {
  final MutableValue<ShowcasePage> selected;

  const _RailShell({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.canvas,
      body: Row(
        children: [
          _ShowcaseSidebar(selected: selected),
          Expanded(child: selected.value.build()),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final MutableValue<ShowcasePage> selected;

  const _MobileShell({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.canvas,
      drawer: _ShowcaseSidebar(selected: selected, isDrawer: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: context.colors.text),
                      tooltip: 'Open menu',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.auto_awesome, size: 18, color: context.colors.primary),
                  const SizedBox(width: 8),
                  Text('utopia_ui', style: context.textStyles.label),
                ],
              ),
            ),
          ),
          const UtopiaDivider(),
          Expanded(child: selected.value.build()),
        ],
      ),
    );
  }
}

class _ShowcaseSidebar extends StatelessWidget {
  final MutableValue<ShowcasePage> selected;
  final bool isDrawer;

  const _ShowcaseSidebar({required this.selected, this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    return UtopiaSidebar(
      presentation: isDrawer ? UtopiaSidebarPresentation.drawer : UtopiaSidebarPresentation.rail,
      selectedId: selected.value.name,
      onDestinationPressed: (destination) {
        selected.value = ShowcasePage.values.byName(destination.id);
        if (isDrawer) Navigator.of(context).pop();
      },
      style: UtopiaSidebarStyle(
        backgroundColors: [context.colors.primary, context.colors.accent],
        headerBuilder: _buildBrandHeader,
      ),
      items: [
        for (final page in ShowcasePage.values)
          UtopiaSidebarDestination(id: page.name, label: Text(page.label), icon: Icon(page.icon)),
        UtopiaSidebarAction(
          label: const Text('Sign out'),
          icon: const Icon(Icons.logout),
          onPressed: () => UtopiaConfirmDialog.show(
            context,
            title: 'Sign out?',
            subtitle: 'This is a showcase - there is no session to end.',
            confirmLabel: 'Sign out',
          ),
        ),
      ],
    );
  }
}

/// A fixed-height brand mark for the sidebar header: an icon plus a wordmark
/// when expanded, icon only when collapsed. Colored with the button text
/// colour - the theme's "content on primary" - so it follows the theme on the
/// gradient background (dark on bright-gradient themes, white on dark ones),
/// matching the sidebar tiles.
Widget _buildBrandHeader(BuildContext context, bool isCollapsed) {
  final onColoredContent = context.textStyles.button.color ?? context.colors.onColoredContent;
  final spacing = context.spacing;
  return SizedBox(
    height: 56,
    child: Padding(
      // md + lg mirrors a tile's outer + inner padding, so the header icon
      // lines up with the tile icons below it.
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : spacing.md + spacing.lg),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: onColoredContent),
          if (!isCollapsed) ...[
            SizedBox(width: spacing.md),
            Text('utopia_ui', style: context.textStyles.label.copyWith(color: onColoredContent)),
          ],
        ],
      ),
    ),
  );
}
