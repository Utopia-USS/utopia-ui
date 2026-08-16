import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// Sheet section demoing [UtopiaSidebar]: a plain-surface rail, a gradient rail
/// with a branded header, and the flush drawer presentation.
class SidebarSection extends HookWidget {
  /// Creates the sidebar sheet section.
  const SidebarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final railSelection = useState('dashboard');
    final gradientSelection = useState('dashboard');
    final drawerSelection = useState('dashboard');

    return SheetSection(
      title: 'Sidebar',
      subtitle:
          'An adaptive rail: 80px collapsed, expands on hover, pins via the toggle. Plain surface or opt-in '
          'gradient; drawer presentation for small screens.',
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        children: [
          SpecimenTile(
            label: 'Rail - surface',
            // Not paneled: the rail is itself a surface, so it does not need
            // the tile's own surface panel.
            panel: false,
            // Fixed width: inside a Wrap an unconstrained Align would expand to
            // the full row; 340 leaves room for the rail's hover expansion
            // (300px rail + 16px shell gutter).
            child: SizedBox(
              width: 340,
              height: 420,
              child: Align(
                alignment: Alignment.topLeft,
                child: UtopiaSidebar(
                  items: _sidebarItems(),
                  selectedId: railSelection.value,
                  onDestinationPressed: (destination) => railSelection.value = destination.id,
                ),
              ),
            ),
          ),
          SpecimenTile(
            label: 'Rail - gradient + header',
            panel: false,
            child: SizedBox(
              width: 340,
              height: 420,
              child: Align(
                alignment: Alignment.topLeft,
                child: UtopiaSidebar(
                  items: _sidebarItems(),
                  selectedId: gradientSelection.value,
                  onDestinationPressed: (destination) => gradientSelection.value = destination.id,
                  style: UtopiaSidebarStyle(
                    backgroundColors: [context.colors.primary, context.colors.accent],
                    headerBuilder: _buildStudioHeader,
                  ),
                ),
              ),
            ),
          ),
          SpecimenTile(
            label: 'Drawer presentation',
            panel: false,
            child: SizedBox(
              width: 300,
              height: 420,
              child: UtopiaSidebar(
                items: _sidebarItems(),
                selectedId: drawerSelection.value,
                presentation: UtopiaSidebarPresentation.drawer,
                onDestinationPressed: (destination) => drawerSelection.value = destination.id,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A fixed-height brand mark for the gradient rail's header: an icon plus a
/// wordmark when expanded, icon only when collapsed. Colored with
/// `onColoredContent` so it reads on the gradient background.
Widget _buildStudioHeader(BuildContext context, bool isCollapsed) {
  final onColoredContent = context.colors.onColoredContent;
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
            Text('Studio', style: context.textStyles.label.copyWith(color: onColoredContent)),
          ],
        ],
      ),
    ),
  );
}

/// The shared destination/action list rendered by every specimen in this
/// section - a fresh list per call so no [UtopiaSidebarItem] instance is shared
/// across the three independently-selected [UtopiaSidebar] demos.
List<UtopiaSidebarItem> _sidebarItems() {
  return [
    const UtopiaSidebarDestination(
      id: 'dashboard',
      label: Text('Dashboard'),
      icon: Icon(Icons.space_dashboard_outlined),
    ),
    const UtopiaSidebarDestination(id: 'content', label: Text('Content'), icon: Icon(Icons.article_outlined)),
    const UtopiaSidebarDestination(id: 'media', label: Text('Media'), icon: Icon(Icons.image_outlined)),
    const UtopiaSidebarDestination(id: 'settings', label: Text('Settings'), icon: Icon(Icons.settings_outlined)),
    UtopiaSidebarAction(label: const Text('Sign out'), icon: const Icon(Icons.logout), onPressed: () {}),
  ];
}
