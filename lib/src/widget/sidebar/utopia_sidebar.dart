import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/layout/utopia_gradient_background.dart';
import 'package:utopia_ui/src/widget/sidebar/utopia_sidebar_item.dart';
import 'package:utopia_ui/src/widget/sidebar/utopia_sidebar_tile.dart';

/// How [UtopiaSidebar] is laid out by the host shell.
///
/// * [rail] - an in-layout column on wide screens: collapsed by default,
///   peeks open on hover and pins open via the top toggle icon.
/// * [drawer] - the sidebar hosted inside a host-owned drawer (e.g.
///   `Scaffold.drawer`) on small screens: always full and flush, no collapse
///   / hover. Closing the drawer after a tap is the host's concern - this
///   widget renders content only and bakes in no scaffold coupling.
enum UtopiaSidebarPresentation { rail, drawer }

/// Builds the sidebar header (logo / branding), pinned above the items.
///
/// [isCollapsed] is `true` when the rail is narrow (icons only) - return a
/// compact, text-less mark; `false` when the rail is expanded or shown as a
/// drawer - return the full lockup. Keep the returned widget's *height*
/// equal across both states (e.g. a fixed-height box) so the items below do
/// not shift when the rail toggles. The host owns the header's colours and
/// alignment: on a coloured sidebar (see [UtopiaSidebarStyle.backgroundColors])
/// return a header that reads on the gradient.
// ignore: avoid_positional_boolean_parameters
typedef UtopiaSidebarHeaderBuilder = Widget Function(BuildContext context, bool isCollapsed);

/// Host-facing sidebar configuration, mirroring core's former
/// `UtopiaWidgetMenuParams` field-for-field.
///
/// Behaviour is *not* configured here: the sidebar collapses / expands at
/// runtime (the top toggle icon, hover-peek) and rail-vs-drawer is chosen by
/// the host via [UtopiaSidebar.presentation]. Hosts only provide branding (the
/// [headerBuilder]) and an optional colour [backgroundColors].
class UtopiaSidebarStyle {
  /// Opt-in gradient background colours. When `null` (the default) the
  /// sidebar renders as a plain surface card matching the content card (same
  /// surface colour, border, shadow, radius).
  final List<Color>? backgroundColors;

  /// Builds the header shown at the top of the sidebar. Receives whether the
  /// rail is currently collapsed so the host can swap a full lockup for a
  /// bare mark. `null` (the default) renders no header.
  final UtopiaSidebarHeaderBuilder? headerBuilder;

  /// Creates a sidebar style. Both fields are opt-in; the defaults render an
  /// unbranded plain surface card with no header.
  const UtopiaSidebarStyle({this.backgroundColors, this.headerBuilder});
}

/// An adaptive navigation sidebar: a collapsible hover/pin rail on wide
/// screens, a flush full-width drawer body on small screens.
///
/// Renders [items] (a mix of [UtopiaSidebarDestination], [UtopiaSidebarAction] and
/// [UtopiaSidebarCustom]) and reports destination taps via [onDestinationPressed].
/// This widget carries no data-layer or navigation opinions: it never pushes
/// routes, never closes its own drawer, and "selected" means nothing more
/// than [selectedId] matching a destination's id.
class UtopiaSidebar extends HookWidget {
  /// The entries to render, top to bottom.
  final List<UtopiaSidebarItem> items;

  /// The id of the currently active [UtopiaSidebarDestination], or `null` if
  /// none is selected. Compared with [UtopiaSidebarDestination.id].
  final String? selectedId;

  /// Invoked when a [UtopiaSidebarDestination] tile is tapped. [UtopiaSidebarAction]
  /// items invoke their own `onPressed` instead.
  final void Function(UtopiaSidebarDestination destination) onDestinationPressed;

  /// Whether to render as a collapsible rail or a flush drawer body.
  final UtopiaSidebarPresentation presentation;

  /// Branding / background configuration.
  final UtopiaSidebarStyle style;

  /// The uniform shell gutter (window -> sidebar, sidebar -> content,
  /// content -> edge). The single source of truth, so hosts can mirror it in
  /// their own content padding.
  static const double shellGutter = 16;

  static const double _expandedWidth = 300;
  static const _heightExtremum = 500;

  /// A collapsed tile's horizontal stack (paddings + 22px icon + 2px slack),
  /// token-derived so the rail survives a rescaled base unit.
  static double _collapsedWidthOf(BuildContext context) {
    final spacing = context.spacing;
    return spacing.md + spacing.lg + 22 + spacing.lg + spacing.md + 2;
  }

  /// The intrinsic height of a single `UtopiaSidebarTile`, so hosts building
  /// custom items that must line up with the sidebar's own rows (e.g. a
  /// menu item mimicking a tile) can size themselves to match without
  /// duplicating the tile's metrics by hand.
  ///
  /// `UtopiaSidebarTile` stacks an outer 4px vertical padding (`spacing.xs`),
  /// an inner 12px vertical padding (`spacing.md`) and a 22px icon:
  /// 4 + 12 + 22 + 12 + 4 = 54.
  static const double tileHeight = 54;

  /// Creates an adaptive sidebar.
  const UtopiaSidebar({
    super.key,
    required this.items,
    required this.onDestinationPressed,
    this.selectedId,
    this.presentation = UtopiaSidebarPresentation.rail,
    this.style = const UtopiaSidebarStyle(),
  });

  bool get _isDrawer => presentation == UtopiaSidebarPresentation.drawer;

  @override
  Widget build(BuildContext context) {
    // Rail-only runtime state. Hooks run unconditionally (the drawer branch
    // ignores them) so hook order stays stable for the element's lifetime.
    final isPinnedExpanded = useState<bool>(false);
    final isHovering = useState<bool>(false);

    if (_isDrawer) return _buildDrawer(context);

    final isExpanded = isPinnedExpanded.value || isHovering.value;
    return MouseRegion(
      onEnter: (_) => isHovering.value = true,
      onExit: (_) => isHovering.value = false,
      child: _buildRail(
        context,
        isExpanded: isExpanded,
        isPinned: isPinnedExpanded.value,
        onToggle: () => isPinnedExpanded.value = !isPinnedExpanded.value,
      ),
    );
  }

  // --- Rail (wide screens) ---

  Widget _buildRail(
    BuildContext context, {
    required bool isExpanded,
    required bool isPinned,
    required VoidCallback onToggle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final verticalPadding = _railVerticalPadding(constraints, context);
        final radius = _railBorderRadius(constraints, context);
        final theme = context.theme;
        // Default sidebar is a card matching the content card (same surface,
        // border, shadow, radius). A colour gradient is used only when the
        // host opts in via style.backgroundColors. No right margin here: the
        // single shell gutter to the content is owned by the host's content
        // padding, so the shell gutters stay uniform.
        final useCard = style.backgroundColors == null;
        return AnimatedPadding(
          duration: theme.tokens.durations.md,
          padding: EdgeInsets.fromLTRB(shellGutter, verticalPadding, 0, verticalPadding),
          child: AnimatedContainer(
            duration: theme.tokens.durations.lg,
            curve: Curves.easeOutExpo,
            width: isExpanded ? _expandedWidth : _collapsedWidthOf(context),
            clipBehavior: Clip.antiAlias,
            decoration: useCard
                ? BoxDecoration(color: theme.colors.surface, borderRadius: radius, boxShadow: theme.cardShadow)
                // Gradient geometry mirrors UtopiaGradientBackground (bottomLeft ->
                // topRight), which paints the same backgroundColors in the
                // drawer presentation - keep the two in sync.
                : BoxDecoration(
                    boxShadow: theme.menuShadow,
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: style.backgroundColors!,
                    ),
                  ),
            foregroundDecoration: useCard
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: theme.colors.border, width: theme.cardBorderWidth),
                  )
                : null,
            child: _buildBody(
              context,
              isExpanded: isExpanded,
              onColored: !useCard,
              toolbar: _buildToolbar(context, isPinned: isPinned, onToggle: onToggle, onColored: !useCard),
            ),
          ),
        );
      },
    );
  }

  // --- Drawer (small screens) ---

  Widget _buildDrawer(BuildContext context) {
    final theme = context.theme;
    final useCard = style.backgroundColors == null;
    final body = SafeArea(child: _buildBody(context, isExpanded: true, onColored: !useCard, toolbar: null));
    return SizedBox(
      width: _expandedWidth,
      child: Material(
        color: useCard ? theme.colors.surface : Colors.transparent,
        child: useCard
            ? body
            : UtopiaGradientBackground(borderRadius: BorderRadius.zero, colors: style.backgroundColors, child: body),
      ),
    );
  }

  // --- Shared body ---

  /// Renders [toolbar], the optional header, then every item.
  ///
  /// Structural note (mandatory fix over the old core menu): this
  /// deliberately avoids `IntrinsicHeight`, which throws when a
  /// [UtopiaSidebarCustom] child is `LayoutBuilder`-based (`LayoutBuilder`
  /// cannot report intrinsic dimensions - it needs real, incoming
  /// constraints to invoke its builder). `SliverFillRemaining` with
  /// `hasScrollBody: false` sizes the column to the larger of the viewport
  /// and its content without ever asking a child for its intrinsic size:
  /// the body scrolls when items overflow, fills the viewport when they
  /// don't, and - because the column's height is then bounded - `Expanded`/
  /// `Spacer` items work and absorb the free space, which is how trailing
  /// items get pinned to the bottom edge. Width is already bounded by the
  /// surrounding rail/drawer container.
  Widget _buildBody(
    BuildContext context, {
    required bool isExpanded,
    required bool onColored,
    required Widget? toolbar,
  }) {
    final spacing = context.spacing;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              ?toolbar,
              if (style.headerBuilder != null) _buildHeader(context, isCollapsed: !isExpanded),
              SizedBox(height: spacing.md),
              for (final item in items) _buildItem(context, item, isExpanded: isExpanded, onColored: onColored),
              SizedBox(height: spacing.md),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, UtopiaSidebarItem item, {required bool isExpanded, required bool onColored}) {
    return switch (item) {
      UtopiaSidebarDestination() => UtopiaSidebarTile(
        icon: item.icon,
        label: item.label,
        isExpanded: isExpanded,
        isSelected: item.id == selectedId,
        onColored: onColored,
        onPressed: () => onDestinationPressed(item),
      ),
      UtopiaSidebarAction() => UtopiaSidebarTile(
        icon: item.icon,
        label: item.label,
        isExpanded: isExpanded,
        isSelected: false,
        onColored: onColored,
        onPressed: item.onPressed,
      ),
      UtopiaSidebarCustom() => item.builder(context),
    };
  }

  /// The top control row: the panel toggle that pins / unpins the rail. The
  /// glyph reflects the pinned *intent* (not a transient hover-peek): a panel
  /// icon while flexible, a collapse icon while pinned open.
  ///
  /// The toggle is centred inside a left-anchored collapsed-width box in
  /// *both* states, so its position never depends on the rail's animating
  /// width - it stays put through expand/collapse, optically in the tile
  /// icon column, exactly like the tile icons themselves.
  Widget _buildToolbar(
    BuildContext context, {
    required bool isPinned,
    required VoidCallback onToggle,
    required bool onColored,
  }) {
    final toggle = _UtopiaSidebarIconButton(
      icon: isPinned ? Icons.menu_open : Icons.view_sidebar_outlined,
      tooltip: isPinned ? 'Collapse menu' : 'Expand menu',
      onColored: onColored,
      onPressed: onToggle,
    );
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(top: spacing.lg, bottom: spacing.xxs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(width: _collapsedWidthOf(context), child: Center(child: toggle)),
      ),
    );
  }

  /// The host-provided header, pinned above the items with a consistent top
  /// gutter. The host owns the header's height and alignment (via the
  /// builder): keep the height equal across collapsed / expanded so the
  /// items below do not shift when the rail toggles.
  ///
  /// The header is laid out at a *fixed* width - the collapsed width while
  /// collapsed, [_expandedWidth] while expanded - inside a left-anchored,
  /// clipping box. `isCollapsed` flips at the *start* of the width animation,
  /// so anything laid out against the rail's animating width would slide
  /// around mid-animation (and the expanded lockup would overflow it); a
  /// fixed-width left-anchored layout keeps the mark stationary and lets the
  /// clip do the reveal, matching how the tile labels animate.
  Widget _buildHeader(BuildContext context, {required bool isCollapsed}) {
    final width = isCollapsed ? _collapsedWidthOf(context) : _expandedWidth;
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.lg, bottom: context.spacing.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstraintsTransformBox(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.hardEdge,
          constraintsTransform: (constraints) => constraints.copyWith(minWidth: width, maxWidth: width),
          child: style.headerBuilder!(context, isCollapsed),
        ),
      ),
    );
  }

  BorderRadius _railBorderRadius(BoxConstraints constraints, BuildContext context) {
    if (constraints.maxHeight > _heightExtremum) return context.theme.cardRadius;
    return BorderRadius.zero;
  }

  double _railVerticalPadding(BoxConstraints constraints, BuildContext context) {
    if (constraints.maxHeight > _heightExtremum) return context.theme.pageTopPadding;
    return 0;
  }
}

/// A small, square icon button for the sidebar's top control row. Muted by
/// default, with a soft hover fill.
class _UtopiaSidebarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool onColored;
  final VoidCallback? onPressed;

  const _UtopiaSidebarIconButton({required this.icon, required this.tooltip, this.onColored = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    // Same on-gradient convention as UtopiaSidebarTile's content: the button
    // text colour is the theme's "content on primary" colour, so the toggle
    // follows it (e.g. goes dark on bright-gradient themes).
    final color = onColored ? (context.textStyles.button.color ?? context.colors.onColoredContent) : context.colors.hint;
    final hover = onColored ? context.colors.onColoredHover : context.colors.hover;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: context.radius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          hoverColor: hover,
          child: Padding(
            padding: EdgeInsets.all(context.spacing.sm),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
