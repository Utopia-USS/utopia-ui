import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A hairline divider drawn in the theme's divider colour.
///
/// Separates the header from the rows and the rows from each other in a
/// `UtopiaTable`. Thickness comes from `UtopiaThemeData.dividerThickness`.
/// When `UtopiaThemeColors.divider` is unset, the colour is derived from the
/// theme's text colour over the surface, so the hairline keeps visible
/// contrast in light and dark themes alike.
class UtopiaDivider extends StatelessWidget {
  /// Creates a hairline divider.
  const UtopiaDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = colors.divider ?? Color.alphaBlend(colors.text.withValues(alpha: 0.12), colors.surface);
    return Container(height: context.theme.dividerThickness, color: color);
  }
}
