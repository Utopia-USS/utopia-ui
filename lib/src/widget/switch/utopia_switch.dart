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

  /// Track extent; the twin mirrors these as literals in `components.css`.
  static const double _trackWidth = 40;
  static const double _trackHeight = 24;

  /// Thumb inset within the track on every side.
  static const double _thumbInset = 2;

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
    const thumbSize = _trackHeight - 2 * _thumbInset;

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
            width: _trackWidth,
            height: _trackHeight,
            padding: const EdgeInsets.all(_thumbInset),
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
