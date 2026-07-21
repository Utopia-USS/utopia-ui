import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A themed on/off switch, drawn entirely from `UtopiaThemeData` - no
/// Material `Switch` underneath, so the track and thumb corners follow
/// `radius.full` (a stadium in round themes, square when the theme flattens
/// radii to zero) instead of Material's hard-coded pill.
class UtopiaSwitch extends StatelessWidget {
  /// Whether the switch renders in its "on" position.
  final bool value;

  /// Called with the new value when toggled; `null` disables interaction.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool)? onChanged;

  /// When `true`, blocks interaction while keeping the full-color styling
  /// (instead of a faded disabled look).
  final bool readOnly;

  /// Creates a themed on/off switch.
  const UtopiaSwitch({super.key, required this.value, this.onChanged, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    final interactive = !readOnly && onChanged != null;
    // Track/thumb extents are derived from the base unit so the switch scales
    // with a rebrand like every other control (a dense UtopiaButton/field is
    // x*10 tall). At the default x=4 these are 40x24 with a 2px inset and a
    // 20px thumb; the twin mirrors the same multiples in `components.css`.
    final trackWidth = tokens.x * 10;
    final trackHeight = tokens.x * 6;
    final thumbInset = tokens.x * 0.5;
    final thumbSize = trackHeight - 2 * thumbInset;
    // The thumb sits on a primary (active) or disabled (inactive) fill - the
    // same grounds a UtopiaButton's content sits on - so it follows the
    // button text colour instead of hard-coding white, and adapts to themes
    // whose on-primary content is dark.
    final thumbColor = context.textStyles.button.color ?? const Color(0xFFFFFFFF);

    return Semantics(
      toggled: value,
      enabled: interactive,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: interactive ? () => onChanged!(!value) : null,
          child: AnimatedContainer(
            duration: tokens.durations.sm,
            curve: Curves.ease,
            width: trackWidth,
            height: trackHeight,
            padding: EdgeInsets.all(thumbInset),
            decoration: BoxDecoration(
              color: value ? colors.primary : colors.disabled,
              borderRadius: tokens.radius.fullAll,
            ),
            child: AnimatedAlign(
              duration: tokens.durations.sm,
              curve: Curves.ease,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(color: thumbColor, borderRadius: tokens.radius.fullAll),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
