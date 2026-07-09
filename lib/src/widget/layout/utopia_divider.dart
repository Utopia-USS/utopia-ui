import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A hairline divider drawn in the theme's border colour.
///
/// Separates the header from the rows and the rows from each other in a
/// `UtopiaTable`. Thickness comes from `UtopiaThemeData.dividerThickness`.
class UtopiaDivider extends StatelessWidget {
  /// Creates a hairline divider.
  const UtopiaDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(height: context.theme.dividerThickness, color: context.colors.border);
}
