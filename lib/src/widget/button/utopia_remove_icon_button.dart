import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A small "x" icon button used to remove/clear a value (e.g. a chip or a
/// filled field), styled with `UtopiaThemeColors.text`.
class UtopiaRemoveIconButton extends StatelessWidget {
  /// Called when the icon is tapped.
  final void Function() onPressed;

  /// Creates the remove/clear icon button.
  const UtopiaRemoveIconButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Icon(Icons.clear, color: colors.text, size: 18),
      ),
    );
  }
}
