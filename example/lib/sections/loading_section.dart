import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// Spinners, bouncing dots and shimmer skeletons.
class LoadingSection extends StatelessWidget {
  /// Creates the loading section.
  const LoadingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SheetSection(
      title: 'Loading',
      subtitle: 'Spinners, bouncing dots and shimmer skeletons.',
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        children: [
          const SpecimenTile(
            label: 'UtopiaLoader 12 / 20 / 32',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UtopiaLoader(),
                SizedBox(width: 24),
                UtopiaLoader(size: 20),
                SizedBox(width: 24),
                UtopiaLoader(size: 32),
              ],
            ),
          ),
          const SpecimenTile(label: 'UtopiaThreeBounce', child: UtopiaThreeBounce()),
          SpecimenTile(
            // The indicator's real habitat: UtopiaButton swaps its label for
            // these dots in the button's own content colour, so the second
            // specimen shows them on a filled ground rather than repeating the
            // (now default) primary tint on the page colour.
            label: 'UtopiaThreeBounce - on a filled ground',
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.primary, borderRadius: context.theme.borderRadius),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg, vertical: context.spacing.md),
                child: UtopiaThreeBounce(color: context.textStyles.button.color),
              ),
            ),
          ),
          const SpecimenTile(
            label: 'Skeleton (UtopiaLoadingBox)',
            child: SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  UtopiaLoadingBox(height: 12, width: 140),
                  SizedBox(height: 12),
                  UtopiaLoadingBox(height: 8, width: 220),
                  SizedBox(height: 8),
                  UtopiaLoadingBox(height: 8, width: 180),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
