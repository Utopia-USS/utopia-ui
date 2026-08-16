import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// Shared chrome and interactive-height floor for every utopia_ui field.
///
/// Wraps [child] with the field decoration/padding from the ambient
/// `UtopiaThemeData` so text, dropdown and switch fields share one look and one
/// minimum height whether or not they carry a floating label.
///
/// The wrapper owns the field's *chrome states* too: it observes pointer
/// hover and descendant focus itself, so any field composed on top of it
/// (`UtopiaTextField`, `UtopiaSearchField`, `UtopiaLabeledField` and the
/// dropdowns built on it) picks up hover and focus feedback without wiring a
/// `FocusNode`. Precedence, highest first: read-only, error + focus, error,
/// focus, hover, rest.
class UtopiaFieldWrapper extends HookWidget {
  /// The content laid over the field chrome.
  final Widget child;

  /// When `true`, outlines the chrome in the theme's error colour - the
  /// field-level half of the error state (`UtopiaTextField` renders the
  /// message below the field).
  final bool hasError;

  /// When `true`, renders the inert chrome (recessed to the page colour, no
  /// focus ring) so a field that cannot be edited reads as a displayed value
  /// rather than an empty control. Outranks every other state.
  final bool readOnly;

  /// Compact chrome whose resting height matches a dense `UtopiaButton`, for
  /// toolbar rows where fields and dense buttons sit side by side.
  final bool dense;

  /// Creates the shared field chrome around [child].
  const UtopiaFieldWrapper({
    super.key,
    required this.child,
    this.hasError = false,
    this.readOnly = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeValues = context.theme;
    final isFocused = useState<bool>(false);
    final isHovered = useState<bool>(false);

    // Chrome for the current state, highest precedence first: read-only
    // outranks everything (an inert field never rings), an errored field
    // keeps its hue while focused, and hover is the quietest step.
    BoxDecoration decoration() {
      if (readOnly) return themeValues.fieldReadOnlyDecoration;
      if (hasError) {
        return isFocused.value ? themeValues.fieldErrorFocusDecoration : themeValues.fieldErrorDecoration;
      }
      if (isFocused.value) return themeValues.fieldFocusDecoration;
      if (isHovered.value) return themeValues.fieldHoverDecoration;
      return themeValues.fieldDecoration;
    }

    return Focus(
      // The wrapper is chrome, not a stop: it never takes focus itself and
      // never appears in the tab order - it only listens, so `onFocusChange`
      // fires for the real input nested inside it.
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) => isFocused.value = value,
      child: MouseRegion(
        onEnter: (_) => isHovered.value = true,
        onExit: (_) => isHovered.value = false,
        child: AnimatedContainer(
          duration: context.tokens.durations.sm,
          // Every state carries a border of the SAME width and paints its
          // ring as an outward box shadow, so no state change - error, focus
          // or read-only - ever shifts the field's size or its content.
          decoration: decoration(),
          padding: dense
              ? themeValues.fieldContentPadding.copyWith(top: 0, bottom: 0)
              : themeValues.fieldContentPadding,
          // Floor every field's content area at the themed minimum so text,
          // dropdown and switch fields share one height whether or not they
          // carry a floating label; the child Row centres content within it.
          // Total resting height = fieldMinHeight + vertical
          // fieldContentPadding + both borders, which equals a resting
          // UtopiaButton's extent. Dense fields floor at the dense button
          // extent minus the border widths, which the container adds back on
          // top.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: dense
                  ? context.tokens.x * 10 - 2 * context.tokens.borders.hairline
                  : themeValues.fieldMinHeight,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The factor Flutter's `InputDecorator` applies to a floated label ON TOP of
/// the supplied `floatingLabelStyle` (`_kFinalLabelScale` in
/// `flutter/src/material/input_decorator.dart`). The themed size is divided by
/// it so the label LANDS at the caption size on both surfaces - the HTML twin
/// renders the same label unscaled.
const double _floatingLabelScale = 0.75;

/// The shared [InputDecoration] for every utopia_ui field - the single source of the
/// field chrome and the floating-label styling.
///
/// Used by `UtopiaTextField` (and, through it, every text-backed field: text, num,
/// date, country) and by the read-only `UtopiaLabeledField` that backs the
/// dropdowns - so a label looks and floats the same everywhere.
///
/// One placeholder look everywhere: hints and *resting* labels render in the
/// body size, regular weight and the muted hint colour ([utopiaPlaceholderStyle]);
/// the *floated* label renders as microcopy - `textStyles.caption` in the hint
/// colour, quieter and smaller than the value it labels rather than heavier.
InputDecoration utopiaFieldDecoration(
  BuildContext context, {
  Widget? label,
  Widget? hint,
  FloatingLabelBehavior? floatingLabelBehavior,
  EdgeInsets? contentPadding,
  bool alignLabelWithHint = false,
}) {
  final textStyles = context.textStyles;
  final placeholderStyle = utopiaPlaceholderStyle(context);
  final captionStyle = textStyles.caption;
  final captionSize = captionStyle.fontSize;
  return InputDecoration(
    // Dense + zero content padding: the surrounding UtopiaFieldWrapper already
    // supplies the field padding, so the decorator only needs room for the
    // (floating) label and value - this keeps fields compact and a uniform
    // height alongside the search field and buttons in a toolbar row.
    // Multiline fields pass a [contentPadding] with top headroom instead: their
    // content fills the decorator, so without it the floated label clips.
    isDense: true,
    contentPadding: contentPadding ?? EdgeInsets.zero,
    border: InputBorder.none,
    focusedBorder: InputBorder.none,
    enabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    label: label,
    // InputDecorator applies hintStyle only to hintText strings; a widget hint
    // renders as-is, so it needs the placeholder style wrapped around it.
    hint: hint == null ? null : DefaultTextStyle.merge(style: placeholderStyle, child: hint),
    hintStyle: placeholderStyle,
    floatingLabelBehavior: floatingLabelBehavior,
    // Floated label = `caption` (the role the design language assigns to
    // microcopy) in the hint colour: smaller and quieter than the value it
    // labels. The size is pre-divided by [_floatingLabelScale] because
    // Flutter's InputDecorator scales the floated label on top of this style,
    // so without the division the label would ship a quarter smaller in
    // Flutter than the twin renders it.
    floatingLabelStyle: captionStyle.copyWith(
      fontSize: captionSize == null ? null : captionSize / _floatingLabelScale,
      color: context.colors.hint,
    ),
    labelStyle: placeholderStyle,
    // Multiline fields set this so the RESTING label/hint anchors to the top
    // of the input (where typing starts) instead of the decorator's vertical
    // centre - mid-field placeholders read as a bug on tall fields.
    alignLabelWithHint: alignLabelWithHint,
  );
}

/// The single placeholder text style shared by every field's hint and resting
/// label: body size, regular weight, muted colour. Search and text fields use
/// it alike so placeholders never differ in weight between fields.
TextStyle utopiaPlaceholderStyle(BuildContext context) => context.textStyles.text.copyWith(
  color: context.colors.hint,
  fontWeight: context.tokens.fontWeights.regular,
);
