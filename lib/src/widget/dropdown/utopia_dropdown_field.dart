import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/overlay/utopia_overlay_anchor.dart';
import 'package:utopia_ui/src/widget/wrapper/utopia_labeled_field.dart';

/// A single-select dropdown presented as a [UtopiaLabeledField] trigger with a
/// [UtopiaOverlayAnchor] popup listing [values], each rendered through
/// [valueLabelBuilder].
///
/// The trigger is a real focus stop: tapping it (or reaching it with Tab, then
/// pressing Space/Enter) focuses it and opens the popup, so the shared field
/// chrome rings for as long as the popup is up and focus returns to the trigger
/// once an option is picked.
class UtopiaDropdownField<T> extends HookWidget {
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
    // The trigger's own focus node. `UtopiaFieldWrapper` - the shared chrome
    // inside `UtopiaLabeledField` - never takes focus itself and instead lights
    // the focus ring whenever a DESCENDANT of it is focused, so the dropdown
    // only has to put a real node under it for the declared focus/open states
    // to have a rendering at all (before this the trigger was a bare
    // `GestureDetector` and neither state existed in Flutter).
    final focusNode = useFocusNode(debugLabel: 'UtopiaDropdownField trigger');
    return UtopiaOverlayAnchor(
      triggerBuilder: (context, open) {
        void openFocused() {
          focusNode.requestFocus();
          open();
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openFocused,
            child: _buildTrigger(context, focusNode: focusNode, onActivate: openFocused),
          ),
        );
      },
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
                // Picking hands focus back to the trigger, so the field stays
                // the active control after the popup goes away (and a keyboard
                // user does not fall back to the top of the traversal order).
                focusNode.requestFocus();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrigger(BuildContext context, {required FocusNode focusNode, required VoidCallback onActivate}) {
    final value = this.value;
    // `null` may be a real, selectable option (e.g. a filter's "All"): show its
    // label like any other value so the default reads as a selection, not an
    // empty field. The resting placeholder is reserved for fields where `null`
    // is genuinely "unset" (not present in [values]).
    final hasValue = value != null || values.contains(null);
    return UtopiaLabeledField(
      label: label,
      value: hasValue ? valueLabelBuilder(value as T) : null,
      // The node rides on the suffix because the wrapper only watches its own
      // descendants and the suffix is the single slot this widget owns INSIDE
      // that wrapper: a `Focus` wrapped around the whole trigger would be the
      // wrapper's ancestor and would never light the ring. Visually it makes no
      // difference - the ring is drawn by the wrapper around the entire field.
      suffix: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) => _handleTriggerKey(event, onActivate),
        child: Icon(Icons.keyboard_arrow_down, size: 18, color: context.textStyles.text.color),
      ),
    );
  }

  /// Space / Enter on the focused trigger opens the popup, so the focus ring
  /// marks a control that can actually be operated from the keyboard.
  KeyEventResult _handleTriggerKey(KeyEvent event, VoidCallback onActivate) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter && key != LogicalKeyboardKey.space) return KeyEventResult.ignored;
    onActivate();
    return KeyEventResult.handled;
  }

  Widget _buildOption(BuildContext context, T option, {required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: context.colors.hover,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.spacing.lg, vertical: context.spacing.md),
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
