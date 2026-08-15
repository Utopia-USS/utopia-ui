import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/select/utopia_checkbox.dart';

/// A non-Material selectable row: a label preceded by a check box, used inside
/// dropdown popups. Styled from the Utopia theme, no ink splash.
class UtopiaCheckRow extends StatelessWidget {
  /// The row's text.
  final String label;

  /// Whether the check box renders as checked.
  final bool selected;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Creates a selectable check row.
  const UtopiaCheckRow({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: colors.hover,
      child: Row(
        children: [
          // readOnly, not a null onChanged: the box is a display of the row's
          // state, and the row's own InkWell carries the interaction - a
          // disabled box would fade a perfectly tappable row.
          UtopiaCheckbox(value: selected, readOnly: true),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Text(label, style: context.textStyles.text, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
