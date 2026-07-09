import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// `UtopiaButton` - the gradient call-to-action, with dense, loading, disabled
/// and icon variants.
class ButtonsSection extends StatelessWidget {
  /// Creates the buttons section.
  const ButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetSection(
      title: 'Buttons',
      subtitle: 'UtopiaButton - the gradient call-to-action, with dense, loading, disabled and icon variants.',
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        children: [
          SpecimenTile(
            label: 'Default',
            child: UtopiaButton(maxWidth: 200, onTap: () {}, child: const Text('Save changes')),
          ),
          SpecimenTile(
            label: 'Dense',
            child: UtopiaButton(dense: true, maxWidth: 180, onTap: () {}, child: const Text('Apply')),
          ),
          SpecimenTile(
            label: 'Loading',
            child: UtopiaButton(dense: true, loading: true, maxWidth: 180, onTap: () {}, child: const Text('Apply')),
          ),
          SpecimenTile(
            label: 'Disabled',
            child: UtopiaButton(
              dense: true,
              isEnabled: false,
              maxWidth: 180,
              onTap: () {},
              child: const Text('Unavailable'),
            ),
          ),
          SpecimenTile(
            label: 'Icon + label',
            child: UtopiaButton(
              dense: true,
              maxWidth: 200,
              onTap: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.add, size: 18), SizedBox(width: 6), Text('New entry')],
              ),
            ),
          ),
          SpecimenTile(
            label: 'Square icon (height == maxWidth)',
            child: UtopiaButton(height: 44, maxWidth: 44, onTap: () {}, child: const Icon(Icons.add)),
          ),
          SpecimenTile(
            label: 'Custom gradient (colors:)',
            child: UtopiaButton(
              dense: true,
              maxWidth: 200,
              onTap: () {},
              colors: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
              child: const Text('Custom colors'),
            ),
          ),
          SpecimenTile(
            label: 'UtopiaRemoveIconButton',
            child: UtopiaRemoveIconButton(onPressed: () {}),
          ),
        ],
      ),
    );
  }
}
