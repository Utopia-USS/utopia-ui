import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A small rounded pill used to display a categorical / tag-like value in a
/// `UtopiaTable` cell (e.g. a dropdown value or one element of a to-many relation).
///
/// Colours and corner radius come from `UtopiaThemeData` / `UtopiaThemeColors` so the
/// whole app stays themable from one place.
class UtopiaChip extends StatelessWidget {
  /// The chip label.
  final Widget child;

  /// Optional leading widget (icon, dot, …) shown before [child].
  final Widget? leading;

  /// Overrides `UtopiaThemeColors.chipBackground`.
  final Color? color;

  /// Overrides `UtopiaThemeColors.chipForeground`.
  final Color? contentColor;

  /// Creates a chip pill.
  const UtopiaChip({super.key, required this.child, this.leading, this.color, this.contentColor});

  @override
  Widget build(BuildContext context) {
    final contentColor = this.contentColor ?? context.colors.chipForeground;
    final spacing = context.spacing;
    return Container(
      decoration: BoxDecoration(
        color: color ?? context.colors.chipBackground,
        borderRadius: BorderRadius.circular(context.theme.chipRadius),
      ),
      // Side inset is deliberately one step below the vertical rhythm's
      // neighbour: at a ~20px pill height inside a 120px status column, 12px
      // of side padding turns the chip into a balloon and eats the density the
      // table exists for.
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
      child: DefaultTextStyle.merge(
        style: context.textStyles.caption.copyWith(color: contentColor),
        child: IconTheme.merge(
          data: IconThemeData(color: contentColor, size: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, SizedBox(width: spacing.xs)],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
