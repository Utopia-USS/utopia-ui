import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/chip/utopia_chip.dart';

/// A wrap of [UtopiaChip]s with a trailing "+N more" overflow chip.
///
/// Used to render multi-value table cells (to-many relations, tag lists) the
/// way the rest of the panel renders categorical data. When [maxLength] is set
/// and exceeded, the surplus collapses into a single overflow chip.
class UtopiaChipList extends StatelessWidget {
  /// The labels to render, in order.
  final IList<String> labels;

  /// Maximum number of value chips to show before collapsing into "+N more".
  /// `null` shows every label.
  final int? maxLength;

  /// Creates a wrap of chips with optional overflow collapsing.
  const UtopiaChipList({super.key, required this.labels, this.maxLength});

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return Text('-', style: context.textStyles.text.copyWith(color: context.colors.hint));
    }
    final limit = maxLength;
    final shown = (limit != null && labels.length > limit) ? labels.sublist(0, limit) : labels;
    final overflow = labels.length - shown.length;
    return Wrap(
      spacing: context.spacing.sm,
      runSpacing: context.spacing.xs,
      children: [
        for (final label in shown) UtopiaChip(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (overflow > 0) UtopiaChip(child: Text('+$overflow more')),
      ],
    );
  }
}
