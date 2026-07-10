import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/misc/utopia_collapsible.dart';

/// A single row inside `UtopiaSidebar`: an icon, a label, and selected/hover
/// states.
///
/// Internal to the sidebar family: `UtopiaSidebarDestination` and
/// `UtopiaSidebarAction` items are rendered through this tile;
/// `UtopiaSidebarCustom` items bypass it entirely.
class UtopiaSidebarTile extends StatelessWidget {
  /// The leading glyph.
  final Widget icon;

  /// The label, revealed next to [icon] while [isExpanded] is true. Usually
  /// a `Text`; styled through the tile's `DefaultTextStyle`.
  final Widget label;

  /// Whether the sidebar is currently expanded (rail) or always-expanded
  /// (drawer) - drives the label's reveal animation.
  final bool isExpanded;

  /// Whether this tile represents the active destination.
  final bool isSelected;

  /// Whether the tile sits on a coloured (gradient) sidebar rather than the
  /// default light surface card - drives the content / selection colours.
  final bool onColored;

  /// Invoked when the tile is tapped.
  final VoidCallback onPressed;

  /// Creates a sidebar tile.
  const UtopiaSidebarTile({
    super.key,
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.isSelected,
    required this.onColored,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final contentColor = onColored
        ? (context.textStyles.button.color ?? Colors.white)
        : (isSelected ? colors.primary : colors.text);
    final selectedColor = onColored ? colors.onColoredSelected : colors.chipBackground;
    final hoverColor = onColored ? colors.onColoredHover : colors.hover;
    final baseStyle = onColored ? context.textStyles.button : context.textStyles.label;

    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xs),
      child: Material(
        color: isSelected ? selectedColor : Colors.transparent,
        borderRadius: context.theme.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          hoverColor: hoverColor,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
            child: IconTheme.merge(
              data: IconThemeData(color: contentColor, size: 22),
              child: DefaultTextStyle(
                style: baseStyle.copyWith(color: contentColor),
                overflow: TextOverflow.ellipsis,
                child: Row(
                  children: [
                    icon,
                    Flexible(child: _buildLabel(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final durations = context.tokens.durations;
    final duration = isExpanded ? durations.xl : durations.sm;
    return AnimatedOpacity(
      curve: Curves.easeOutExpo,
      duration: duration,
      opacity: isExpanded ? 1 : 0,
      child: UtopiaCollapsible.horizontal(
        isExpanded: isExpanded,
        curve: Curves.easeOutExpo,
        duration: duration,
        child: AnimatedScale(
          scale: isExpanded ? 1 : 0,
          curve: Curves.easeOutExpo,
          duration: duration,
          child: Padding(padding: EdgeInsets.only(left: context.spacing.md), child: label),
        ),
      ),
    );
  }
}
