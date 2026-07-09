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
            label: 'UtopiaThreeBounce - primary',
            child: UtopiaThreeBounce(color: colors.primary),
          ),
          const SpecimenTile(
            label: 'Skeleton (UtopiaMockLoadingBox)',
            child: SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  UtopiaMockLoadingBox(height: 12, width: 140),
                  SizedBox(height: 12),
                  UtopiaMockLoadingBox(height: 8, width: 220),
                  SizedBox(height: 8),
                  UtopiaMockLoadingBox(height: 8, width: 180),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
