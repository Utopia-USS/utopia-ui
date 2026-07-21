import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// The quiet secondary action: label-styled text with a soft hover fill and
/// the same resting height as a dense `UtopiaButton`, so it baseline-aligns
/// when placed next to one in an action row (e.g. Cancel beside Save).
class UtopiaGhostButton extends StatelessWidget {
  /// The button's text.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onTap;

  /// Creates a quiet, text-only action button.
  const UtopiaGhostButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      borderRadius: context.theme.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: context.colors.hover,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tokens.x * 10),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.xl),
            child: Center(widthFactor: 1, child: Text(label, style: context.textStyles.label)),
          ),
        ),
      ),
    );
  }
}
