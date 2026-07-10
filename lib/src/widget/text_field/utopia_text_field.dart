import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/wrapper/utopia_field_wrapper.dart';

/// The base editable text field: floating label, optional prefix/suffix and
/// error slot, sharing its chrome with every other utopia_ui field via
/// [UtopiaFieldWrapper].
///
/// Uncontrolled: `value` seeds the internal field state on first build and
/// is NOT resynced on later rebuilds - changes flow out through `onChanged`
/// only. To force a new value from outside, change the widget's [key].
class UtopiaTextField extends HookWidget {
  /// Seeds the internal field state on first build; not resynced afterwards.
  final String value;

  /// The keyboard type requested for the underlying `TextField`.
  final TextInputType? keyboardType;

  /// When `true`, masks the entered text (e.g. for passwords).
  final bool obscureText;

  /// Optional focus node controlling/observing this field's focus.
  final FocusNode? focusNode;

  /// The floating label shown above the field.
  final Widget? label;

  /// Error content shown below the field when non-null; the field chrome
  /// simultaneously outlines itself in the error colour.
  final Widget? error;

  /// Placeholder shown while the field is empty.
  final Widget? hint;

  /// Leading widget shown before the input, inside the field chrome.
  final Widget? prefix;

  /// Trailing widget shown after the input, inside the field chrome.
  final Widget? suffix;

  /// Optional input formatters applied to keystrokes.
  final List<TextInputFormatter>? formatters;

  /// Maximum number of characters accepted by the field; `null` for no limit.
  final int? maxLength;

  /// Number of visible text lines.
  final int lines;

  /// When `true`, blocks editing while keeping the field's normal styling.
  final bool readOnly;

  /// Compact chrome matching a dense `UtopiaButton`'s height. No room for a
  /// floating label, so [label] is ignored - use [hint].
  final bool dense;

  /// Called with the current text, or `null` when it is empty.
  final void Function(String?) onChanged;

  /// Called when the field is tapped.
  final void Function()? onTap;

  /// Creates the base editable text field.
  const UtopiaTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.dense = false,
    this.focusNode,
    this.label,
    this.error,
    this.hint,
    this.prefix,
    this.suffix,
    this.formatters,
    this.lines = 1,
    this.maxLength,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
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
      builder: (controller) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildField(context, controller),
          // Message below the chrome, flush with the field's left edge.
          if (error != null)
            DefaultTextStyle(
              style: textStyles.caption.copyWith(color: colors.error),
              child: error!,
            ),
        ].separatedWith(SizedBox(height: context.spacing.xs)),
      ),
    );
  }

  Widget _buildField(BuildContext context, TextEditingController controller) {
    return UtopiaFieldWrapper(
      hasError: error != null,
      dense: dense,
      child: Row(
        children: [
          ?prefix,
          Flexible(child: _buildTextField(context, controller)),
          ?suffix,
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller) {
    final textStyles = context.textStyles;
    final multiline = lines > 1;
    // The dense chrome has no room for a floating label - hints only.
    final label = dense ? null : this.label;
    return IgnorePointer(
      ignoring: readOnly,
      child: TextField(
        readOnly: readOnly,
        cursorColor: context.colors.primary,
        controller: controller,
        focusNode: focusNode,
        onTap: onTap,
        keyboardType: keyboardType ?? (multiline ? TextInputType.multiline : null),
        obscureText: obscureText,
        // `next` on a multiline field would swallow the Enter key instead of
        // inserting a newline.
        textInputAction: multiline ? TextInputAction.newline : TextInputAction.next,
        minLines: lines,
        maxLines: lines,
        inputFormatters: formatters,
        decoration: utopiaFieldDecoration(
          context,
          label: label,
          hint: hint,
          // Anchor the resting label/hint to the top of the input instead of
          // the decorator's vertical centre.
          alignLabelWithHint: multiline,
          // Reserve headroom for the floated label: multiline content fills
          // the decorator, so without it the floated label sits flush with
          // the chrome. 1.5x matches the single-line fields' centring slack,
          // so the floated label lands at the same top offset in both.
          contentPadding: multiline && label != null ? EdgeInsets.only(top: context.tokens.x * 1.5) : null,
        ),
        style: textStyles.text,
      ),
    );
  }
}
