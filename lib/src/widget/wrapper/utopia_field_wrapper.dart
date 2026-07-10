import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// Shared borderless chrome and interactive-height floor for every utopia_ui field.
///
/// Wraps [child] with the field decoration/padding from the ambient
/// `UtopiaThemeData` so text, dropdown and switch fields share one look and one
/// minimum height whether or not they carry a floating label.
class UtopiaFieldWrapper extends StatelessWidget {
  /// The content laid over the field chrome.
  final Widget child;

  /// When `true`, outlines the chrome in the theme's error colour - the
  /// field-level half of the error state (`UtopiaTextField` renders the
  /// message below the field).
  final bool hasError;

  /// Compact chrome whose resting height matches a dense `UtopiaButton`, for
  /// toolbar rows where fields and dense buttons sit side by side.
  final bool dense;

  /// Creates the shared field chrome around [child].
  const UtopiaFieldWrapper({super.key, required this.child, this.hasError = false, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final fieldTheme = context.fieldDecoration;
    final themeValues = context.theme;

    return AnimatedContainer(
      duration: context.tokens.durations.sm,
      // The border is always present (hairline when valid, error-coloured
      // otherwise) at one width, so toggling the error state never shifts
      // the field's size or its content.
      decoration: fieldTheme.copyWith(
        border: Border.all(
          color: hasError ? context.colors.error : context.colors.border,
          width: context.tokens.borders.hairline,
        ),
      ),
      padding: dense ? themeValues.fieldContentPadding.copyWith(top: 0, bottom: 0) : themeValues.fieldContentPadding,
      // Floor every field's content area at the themed minimum so text,
      // dropdown and switch fields share one height whether or not they carry
      // a floating label; the child Row centres content within it. Total
      // resting height = fieldMinHeight + vertical fieldContentPadding. Dense
      // fields floor at the dense button extent minus the border widths,
      // which the container adds back on top.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: dense
              ? context.tokens.x * 10 - 2 * context.tokens.borders.hairline
              : themeValues.fieldMinHeight,
        ),
        child: child,
      ),
    );
  }
}

/// The shared [InputDecoration] for every utopia_ui field - the single source of the
/// borderless chrome and the floating-label styling.
///
/// Used by `UtopiaTextField` (and, through it, every text-backed field: text, num,
/// date, country) and by the read-only `UtopiaLabeledField` that backs the
/// dropdowns - so a label looks and floats the same everywhere.
///
/// One placeholder look everywhere: hints and *resting* labels render in the
/// body size, regular weight and the muted hint colour ([utopiaPlaceholderStyle]);
/// the *floated* label renders in the small semi-bold label style - resting
/// reads as a placeholder, floated reads as a caption.
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
    floatingLabelStyle: textStyles.label,
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
