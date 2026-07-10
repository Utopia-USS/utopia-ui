import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A themed on/off switch, styled from `UtopiaThemeColors` instead of the
/// ambient `MaterialApp` theme.
class UtopiaSwitch extends StatelessWidget {
  /// Whether the switch renders in its "on" position.
  final bool value;

  /// Called with the new value when toggled; `null` disables interaction.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool)? onChanged;

  /// When `true`, blocks interaction while keeping the full-color styling
  /// (instead of Flutter's faded disabled look).
  final bool readOnly;

  /// Creates a themed on/off switch.
  const UtopiaSwitch({super.key, required this.value, this.onChanged, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The thumb sits on a primary (active) or disabled (inactive) fill - the
    // same grounds a UtopiaButton's content sits on - so it follows the
    // button text colour instead of hard-coding white, and adapts to themes
    // whose on-primary content is dark.
    final thumbColor = context.textStyles.button.color ?? Colors.white;
    return IgnorePointer(
      ignoring: readOnly,
      child: MouseRegion(
        cursor: readOnly ? MouseCursor.defer : SystemMouseCursors.click,
        child: Switch(
          activeTrackColor: colors.primary,
          inactiveTrackColor: colors.disabled,
          inactiveThumbColor: thumbColor,
          activeThumbColor: thumbColor,
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          trackOutlineWidth: const WidgetStatePropertyAll(0),
          // No hover/press halo: the Material circle overlay clashes with the
          // flat utopia look - the click cursor and thumb animation carry the
          // affordance.
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          value: value,
          // When read-only we still want the full-colour look (not Flutter's
          // faded disabled styling), so pass a no-op handler and let the
          // surrounding IgnorePointer block interaction.
          onChanged: onChanged ?? (readOnly ? (_) {} : null),
        ),
      ),
    );
  }
}
