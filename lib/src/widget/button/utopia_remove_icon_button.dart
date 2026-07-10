import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A small "x" icon button used to remove/clear a value (e.g. a chip or a
/// filled field), styled with `UtopiaThemeColors.text` and tinting to the
/// error colour on hover to signal the destructive action.
class UtopiaRemoveIconButton extends HookWidget {
  /// Called when the icon is tapped.
  final void Function() onPressed;

  /// Creates the remove/clear icon button.
  const UtopiaRemoveIconButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hovering = useState<bool>(false);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => hovering.value = true,
      onExit: (_) => hovering.value = false,
      child: GestureDetector(
        onTap: onPressed,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: hovering.value ? colors.error : colors.text),
          duration: context.tokens.durations.xs,
          builder: (context, color, _) => Icon(Icons.clear, color: color, size: 18),
        ),
      ),
    );
  }
}
