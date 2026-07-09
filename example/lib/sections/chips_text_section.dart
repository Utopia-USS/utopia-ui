import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// Tag pills, overflow collapsing and utility text.
class ChipsTextSection extends StatelessWidget {
  /// Creates the chips and text section.
  const ChipsTextSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SheetSection(
      title: 'Chips & text',
      subtitle: 'Tag pills, overflow collapsing and utility text.',
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        children: [
          const SpecimenTile(
            label: 'UtopiaChip',
            child: UtopiaChip(child: Text('Published')),
          ),
          const SpecimenTile(
            label: 'UtopiaChip - leading',
            child: UtopiaChip(leading: Icon(Icons.tag), child: Text('release')),
          ),
          SpecimenTile(
            label: 'UtopiaChip - custom colors',
            child: UtopiaChip(
              color: colors.primary.withValues(alpha: 0.12),
              contentColor: colors.primary,
              child: const Text('Active'),
            ),
          ),
          SpecimenTile(
            label: 'UtopiaChipList - maxLength: 4',
            child: UtopiaChipList(
              labels: IList(const ['Design', 'Docs', 'Beta', 'Admin', 'QA', 'Infra']),
              maxLength: 4,
            ),
          ),
          SpecimenTile(
            label: 'UtopiaChipList - empty',
            child: UtopiaChipList(labels: IList(const <String>[])),
          ),
          const SpecimenTile(
            label: 'UtopiaCopyableText',
            width: 260,
            child: UtopiaCopyableText('550e8400-e29b-41d4-a716-446655440000'),
          ),
          const SpecimenTile(label: 'UtopiaCopyableText - null', width: 200, child: UtopiaCopyableText(null)),
          const SpecimenTile(
            label: 'UtopiaTitle',
            child: UtopiaTitle(title: 'Section title'),
          ),
        ],
      ),
    );
  }
}
