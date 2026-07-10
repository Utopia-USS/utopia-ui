import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

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
          _CheckBox(selected: selected),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Text(label, style: context.textStyles.text, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool selected;

  const _CheckBox({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    return AnimatedContainer(
      duration: tokens.durations.xs,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? colors.accent : Colors.transparent,
        borderRadius: tokens.radius.smAll,
        border: Border.all(color: selected ? colors.accent : colors.disabled, width: tokens.borders.thin),
      ),
      child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }
}
