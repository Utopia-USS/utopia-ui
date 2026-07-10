import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/wrapper/utopia_field_wrapper.dart';

/// A prominent, full-width search field: a leading magnifier, a muted [hint]
/// and no floating label - the search affordance at the top of a `UtopiaTable`
/// card. Shares its field decoration and text state with `UtopiaTextField`.
///
/// Uncontrolled: `value` seeds the internal field state on first build and
/// is NOT resynced on later rebuilds - changes flow out through `onChanged`
/// only. To force a new value from outside, change the widget's [key].
class UtopiaSearchField extends HookWidget {
  /// Seeds the internal field state on first build; not resynced afterwards.
  final String value;

  /// Muted placeholder text shown while the field is empty.
  final String hint;

  /// Called with the current text, or `null` when it is empty.
  final void Function(String?) onChanged;

  /// Optional input formatters applied to keystrokes.
  final List<TextInputFormatter>? formatters;

  /// Compact chrome matching a dense `UtopiaButton`'s height.
  final bool dense;

  /// Creates a full-width search field.
  const UtopiaSearchField({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.formatters,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = useFieldState(initialValue: value);
    // Notify only on actual edits: a plain useEffect keyed on the value would
    // also fire on first build, echoing the seed value back into `onChanged`
    // before the user touched the field.
    final isFirstNotify = useMemoized(() => [true]);
    useEffect(() {
      if (isFirstNotify[0]) {
        isFirstNotify[0] = false;
        return null;
      }
      onChanged(state.value.isEmpty ? null : state.value);
      return null;
    }, [state.value]);

    return TextEditingControllerWrapper(
      text: state,
      builder: (controller) => UtopiaFieldWrapper(
        dense: dense,
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: colors.hint),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                cursorColor: colors.primary,
                inputFormatters: formatters,
                textInputAction: TextInputAction.search,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                style: context.textStyles.text,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: utopiaPlaceholderStyle(context),
                ),
              ),
            ),
            if (state.value.isNotEmpty) _ClearButton(onTap: () => state.value = ''),
          ],
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final void Function() onTap;

  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.only(left: context.spacing.sm),
          child: Icon(Icons.close, size: 16, color: context.colors.hint),
        ),
      ),
    );
  }
}
