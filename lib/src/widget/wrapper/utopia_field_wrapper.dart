import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// Shared borderless chrome and interactive-height floor for every utopia_ui field.
///
/// Wraps [child] with the field decoration/padding from the ambient
/// `UtopiaThemeData` so text, dropdown and switch fields share one look and one
/// minimum height whether or not they carry a floating label.
class UtopiaFieldWrapper extends StatelessWidget {
  /// The content laid over the field chrome.
  final Widget child;

  /// Creates the shared field chrome around [child].
  const UtopiaFieldWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final fieldTheme = context.fieldDecoration;
    final themeValues = context.theme;

    return Container(
      decoration: fieldTheme,
      padding: themeValues.fieldContentPadding,
      // Floor every field at the interactive height (the switch field's tap
      // target) so text, dropdown and switch fields share one height whether or
      // not they carry a floating label; the child Row centres content within it.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: child,
      ),
    );
  }
}

/// The shared [InputDecoration] for every utopia_ui field - the single source of the
/// borderless chrome and the floating-label styling.
///
/// Used by `UtopiaTextField` (and, through it, every text-backed field: text, num,
/// date, country) and by the read-only `UtopiaLabeledField` that backs the
/// dropdowns - so a label looks and floats the same everywhere.
InputDecoration utopiaFieldDecoration(
  BuildContext context, {
  Widget? label,
  Widget? hint,
  FloatingLabelBehavior? floatingLabelBehavior,
}) {
  final textStyles = context.textStyles;
  return InputDecoration(
    // Dense + zero content padding: the surrounding UtopiaFieldWrapper already
    // supplies the field padding, so the decorator only needs room for the
    // (floating) label and value - this keeps fields compact and a uniform
    // height alongside the search field and buttons in a toolbar row.
    isDense: true,
    contentPadding: EdgeInsets.zero,
    border: InputBorder.none,
    focusedBorder: InputBorder.none,
    enabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    label: label,
    hint: hint,
    floatingLabelBehavior: floatingLabelBehavior,
    floatingLabelStyle: textStyles.label.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    labelStyle: textStyles.label,
  );
}
