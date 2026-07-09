import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/switch/utopia_switch.dart';
import 'package:utopia_ui/src/widget/wrapper/utopia_field_wrapper.dart';

/// A titled row pairing a label with a [UtopiaSwitch], wrapped in the shared
/// [UtopiaFieldWrapper] chrome so it lines up with the other utopia_ui fields.
class UtopiaSwitchField extends StatelessWidget {
  /// Whether the switch renders in its "on" position.
  final bool value;

  /// The label shown beside the switch.
  final String title;

  /// Called with the new value when toggled; `null` disables interaction.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool)? onChanged;

  /// When `true`, blocks interaction while keeping the full-color styling.
  final bool readOnly;

  /// Creates a titled switch row.
  const UtopiaSwitchField({super.key, required this.value, required this.title, this.onChanged, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return UtopiaFieldWrapper(
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.textStyles.text)),
          UtopiaSwitch(value: value, onChanged: onChanged, readOnly: readOnly),
        ],
      ),
    );
  }
}
