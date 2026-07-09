import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/overlay/utopia_overlay_anchor.dart';
import 'package:utopia_ui/src/widget/wrapper/utopia_labeled_field.dart';

/// A single-select dropdown presented as a [UtopiaLabeledField] trigger with a
/// [UtopiaOverlayAnchor] popup listing [values], each rendered through
/// [valueLabelBuilder].
class UtopiaDropdownField<T> extends StatelessWidget {
  /// The currently selected option; `null` is a valid selection when it is
  /// present in [values] (e.g. a filter's "All").
  final T? value;

  /// Called with the newly picked option when it is tapped in the popup.
  final void Function(T) onChanged;

  /// The selectable options, in display order.
  final List<T> values;

  /// The floating label shown above the trigger field.
  final String label;

  /// Renders an option (or [value]) as its display text.
  final String Function(T) valueLabelBuilder;

  /// Creates a single-select dropdown field.
  const UtopiaDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.values,
    required this.label,
    required this.valueLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return UtopiaOverlayAnchor(
      triggerBuilder: (context, open) =>
          GestureDetector(behavior: HitTestBehavior.opaque, onTap: open, child: _buildTrigger(context)),
      overlayBuilder: (context, close) => ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          for (final option in values)
            _buildOption(
              context,
              option,
              selected: option == value,
              onTap: () {
                onChanged(option);
                close();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrigger(BuildContext context) {
    final value = this.value;
    // `null` may be a real, selectable option (e.g. a filter's "All"): show its
    // label like any other value so the default reads as a selection, not an
    // empty field. The resting placeholder is reserved for fields where `null`
    // is genuinely "unset" (not present in [values]).
    final hasValue = value != null || values.contains(null);
    return UtopiaLabeledField(
      label: label,
      value: hasValue ? valueLabelBuilder(value as T) : null,
      suffix: Icon(Icons.keyboard_arrow_down, size: 18, color: context.textStyles.text.color),
    );
  }

  Widget _buildOption(BuildContext context, T option, {required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: context.colors.hover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(valueLabelBuilder(option), style: context.textStyles.text, overflow: TextOverflow.ellipsis),
            ),
            if (selected) Icon(Icons.check, size: 16, color: context.colors.accent),
          ],
        ),
      ),
    );
  }
}
