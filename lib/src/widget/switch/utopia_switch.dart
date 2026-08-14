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

  /// Fade applied when [onChanged] is `null` without [readOnly] - the
  /// disabled affordance a Material `Switch` would otherwise provide.
  static const double _disabledOpacity = 0.5;

  /// Creates a themed on/off switch.
  const UtopiaSwitch({super.key, required this.value, this.onChanged, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    final interactive = !readOnly && onChanged != null;
    // The thumb sits on a primary (active) or disabled (inactive) fill - the
    // same grounds a UtopiaButton's content sits on - so it follows the
    // button text colour instead of hard-coding white, and adapts to themes
    // whose on-primary content is dark.
    final thumbColor = context.textStyles.button.color ?? const Color(0xFFFFFFFF);
    // Track geometry derives from the token base (10x wide, 6x tall, the thumb
    // inset 0.5x on every side) so the switch rescales with every other
    // control on a base-unit rebrand; the twin mirrors these multiples in
    // `components.css`.
    final trackWidth = tokens.x * 10;
    final trackHeight = tokens.x * 6;
    final thumbInset = tokens.x * 0.5;
    final thumbSize = trackHeight - 2 * thumbInset;
    // readOnly is a display-of-state mode, so it keeps the full-color styling;
    // a null onChanged is a disabled control and reads as one.
    final faded = !readOnly && onChanged == null;

    return Semantics(
      toggled: value,
      enabled: interactive,
      child: Opacity(
        opacity: faded ? _disabledOpacity : 1,
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
      ),
    );
  }
}
