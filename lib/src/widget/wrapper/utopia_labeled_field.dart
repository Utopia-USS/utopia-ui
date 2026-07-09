import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/wrapper/utopia_field_wrapper.dart';

/// A read-only field that shares `UtopiaTextField`'s chrome - the same borderless
/// [UtopiaFieldWrapper], floating label and height - but displays a picked value
/// instead of an editable input.
///
/// This is the common base for fields whose value is chosen rather than typed
/// (the dropdowns). Unlike a read-only `UtopiaTextField` it holds no
/// `useFieldState`, so the displayed [value] always reflects the latest prop -
/// picking a new option updates the trigger immediately.
class UtopiaLabeledField extends StatelessWidget {
  /// The floating label, styled exactly like a `UtopiaTextField` label.
  final String label;

  /// The current value text. Empty/null keeps the label in its resting position
  /// (matching an empty `UtopiaTextField`); a non-empty value floats it.
  final String? value;

  /// Trailing affordance (e.g. a dropdown chevron), laid out like a
  /// `UtopiaTextField` suffix.
  final Widget? suffix;

  /// Creates a read-only, label-and-value field.
  const UtopiaLabeledField({super.key, required this.label, required this.value, this.suffix});

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final value = this.value ?? '';

    return UtopiaFieldWrapper(
      child: Row(
        children: [
          Expanded(
            child: InputDecorator(
              isEmpty: value.isEmpty,
              baseStyle: textStyles.text,
              decoration: utopiaFieldDecoration(context, label: Text(label)),
              child: Text(value, style: textStyles.text, overflow: TextOverflow.ellipsis),
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }
}
