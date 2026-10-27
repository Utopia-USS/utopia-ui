import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// Switches, check boxes, radio buttons, sliders and check rows - the
/// selection controls.
class SelectionSection extends HookWidget {
  /// Creates the selection section.
  const SelectionSection({super.key});

  /// The options backing the radio-group specimen.
  static const _plans = ['Starter', 'Pro', 'Enterprise'];

  @override
  Widget build(BuildContext context) {
    final switchState = useState(true);
    final switchFieldState = useState(true);
    final checkedState = useState(true);
    final checkboxState = useState(true);
    final planState = useState(_plans[1]);
    final sliderState = useState(0.4);
    final steppedState = useState(60.0);

    return SheetSection(
      title: 'Selection',
      subtitle: 'Switches, check boxes, radio buttons, sliders and check rows - the selection controls.',
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
            label: 'UtopiaCheckbox',
            child: UtopiaCheckbox(value: checkboxState.value, onChanged: (value) => checkboxState.value = value),
          ),
          const SpecimenTile(
            label: 'UtopiaCheckbox - indeterminate',
            child: UtopiaCheckbox(value: false, indeterminate: true, onChanged: _ignore),
          ),
          const SpecimenTile(label: 'UtopiaCheckbox - read only', child: UtopiaCheckbox(value: true, readOnly: true)),
          const SpecimenTile(label: 'UtopiaCheckbox - disabled', child: UtopiaCheckbox(value: false)),
          SpecimenTile(
            label: 'UtopiaRadio - group',
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final plan in _plans)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
                    child: Row(
                      children: [
                        UtopiaRadio<String>(
                          value: plan,
                          groupValue: planState.value,
                          onChanged: (value) => planState.value = value,
                        ),
                        SizedBox(width: context.spacing.md),
                        Flexible(child: Text(plan, style: context.textStyles.text, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SpecimenTile(
            label: 'UtopiaRadio - read only',
            child: UtopiaRadio<String>(value: 'Pro', groupValue: 'Pro', readOnly: true),
          ),
          const SpecimenTile(
            label: 'UtopiaRadio - disabled',
            child: UtopiaRadio<String>(value: 'Pro', groupValue: 'Pro'),
          ),
          SpecimenTile(
            label: 'UtopiaSlider',
            width: 260,
            child: _SliderRow(
              label: '${(sliderState.value * 100).round()}%',
              child: UtopiaSlider(value: sliderState.value, onChanged: (value) => sliderState.value = value),
            ),
          ),
          SpecimenTile(
            label: 'UtopiaSlider - divisions: 5',
            width: 260,
            child: _SliderRow(
              label: steppedState.value.toStringAsFixed(0),
              child: UtopiaSlider(
                value: steppedState.value,
                max: 100,
                divisions: 5,
                onChanged: (value) => steppedState.value = value,
              ),
            ),
          ),
          const SpecimenTile(
            label: 'UtopiaSlider - read only',
            width: 260,
            child: _SliderRow(label: '70%', child: UtopiaSlider(value: 0.7, readOnly: true)),
          ),
          const SpecimenTile(
            label: 'UtopiaSlider - disabled',
            width: 260,
            child: _SliderRow(label: '25%', child: UtopiaSlider(value: 0.25)),
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

/// Keeps the indeterminate specimen interactive (full colour, hover, cursor)
/// without letting a tap change the flag it is demonstrating.
// ignore: avoid_positional_boolean_parameters
void _ignore(bool value) {}

/// A slider next to its current value: the slider takes the free width, the
/// reading sits in a fixed-width column on the right so the track does not
/// twitch as the digits change.
class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: child),
        SizedBox(width: context.spacing.md),
        SizedBox(
          width: 40,
          child: Text(label, style: context.textStyles.text, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
