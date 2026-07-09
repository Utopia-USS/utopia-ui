import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// Switches and check rows - the boolean controls.
class SelectionSection extends HookWidget {
  /// Creates the selection section.
  const SelectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final switchState = useState(true);
    final switchFieldState = useState(true);
    final checkedState = useState(true);

    return SheetSection(
      title: 'Selection',
      subtitle: 'Switches and check rows - the boolean controls.',
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        children: [
          SpecimenTile(
            label: 'UtopiaSwitch',
            child: UtopiaSwitch(value: switchState.value, onChanged: (value) => switchState.value = value),
          ),
          const SpecimenTile(label: 'UtopiaSwitch - read only', child: UtopiaSwitch(value: true, readOnly: true)),
          const SpecimenTile(label: 'UtopiaSwitch - disabled', child: UtopiaSwitch(value: false)),
          SpecimenTile(
            label: 'UtopiaSwitchField',
            width: 320,
            child: UtopiaSwitchField(
              value: switchFieldState.value,
              title: 'Email notifications',
              onChanged: (value) => switchFieldState.value = value,
            ),
          ),
          SpecimenTile(
            label: 'UtopiaCheckRow',
            width: 240,
            child: UtopiaCheckRow(
              label: 'Include archived',
              selected: checkedState.value,
              onTap: () => checkedState.value = !checkedState.value,
            ),
          ),
        ],
      ),
    );
  }
}
