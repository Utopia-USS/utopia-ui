import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A themed check box, drawn entirely from `UtopiaThemeData` - no Material
/// `Checkbox` underneath, so its extent, corner radius and stroke widths
/// follow the token scale (a rebranded base unit rescales the box with every
/// other control) instead of Material's fixed 18px geometry.
///
/// Fully controlled, like every other selection control here: it renders
/// [value] and reports the flipped value through [onChanged]. Pass
/// [indeterminate] for a "some of many" box (the header check box above a
/// table's rows) and [readOnly] to display state without offering a way to
/// change it.
class UtopiaCheckbox extends HookWidget {
  /// Whether the box renders as checked.
  final bool value;

  /// Called with the flipped value when tapped; `null` disables interaction.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool)? onChanged;

  /// When `true`, blocks interaction while keeping the full-color styling
  /// (instead of a faded disabled look).
  final bool readOnly;

  /// Renders the mixed ("some, not all") state: a horizontal bar instead of
  /// the check glyph, drawn on the same filled ground as a checked box.
  ///
  /// Purely presentational and independent of [value] - the classic
  /// "select all" box above a partially selected list stays a normal check box
  /// underneath, so a tap still reports `!value` through [onChanged]. Exposed
  /// to assistive technology as the semantics `mixed` state (mutually
  /// exclusive with `checked`, so an indeterminate box reports no checked
  /// state at all).
  final bool indeterminate;

  /// Fade applied when [onChanged] is `null` without [readOnly] - the
  /// disabled affordance a Material `Checkbox` would otherwise provide.
  /// Deliberately duplicated from `UtopiaSwitch._disabledOpacity` (and
  /// `UtopiaRadio._disabledOpacity`) rather than hoisted into a token: the
  /// token tree is closed, and one shared private constant across three files
  /// would outweigh the duplication it saves.
  static const double _disabledOpacity = 0.5;

  /// Creates a themed check box.
  const UtopiaCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.readOnly = false,
    this.indeterminate = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    final interactive = !readOnly && onChanged != null;
    final hovering = useState<bool>(false);
    // The glyph sits on a primary fill - the same ground a UtopiaButton's
    // label sits on - so it follows the button text colour instead of
    // hard-coding white, and adapts to themes whose on-primary content is
    // dark. Same rule as UtopiaSwitch's thumb.
    final glyphColor = context.textStyles.button.color ?? const Color(0xFFFFFFFF);
    // Geometry derives from the token base (a 5x square, a 3.5x check glyph,
    // a 2.5x indeterminate bar) so the box rescales with every other control
    // on a base-unit rebrand; the twin mirrors these multiples in
    // `components.css`.
    final extent = tokens.x * 5;
    // Both the checked and the mixed state are "the box carries a value", so
    // they share one filled rendering and differ only in the glyph.
    final filled = value || indeterminate;
    // readOnly is a display-of-state mode, so it keeps the full-color styling;
    // a null onChanged is a disabled control and reads as one.
    final faded = !readOnly && onChanged == null;
    // The edge leads and the fill supports: an empty box is defined by its
    // border, which steps one shade darker on hover (the same doctrine the
    // fields follow) and gives way to the primary fill once the box carries a
    // value.
    final borderColor = filled ? colors.primary : (interactive && hovering.value ? colors.hint : colors.disabled);

    return Semantics(
      checked: indeterminate ? null : value,
      mixed: indeterminate ? true : null,
      enabled: interactive,
      child: Opacity(
        opacity: faded ? _disabledOpacity : 1,
        child: MouseRegion(
          cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => hovering.value = true,
          onExit: (_) => hovering.value = false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: interactive ? () => onChanged!(!value) : null,
            child: AnimatedContainer(
              duration: tokens.durations.xs,
              curve: Curves.ease,
              width: extent,
              height: extent,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? colors.primary : colors.field,
                borderRadius: tokens.radius.xsAll,
                border: Border.all(color: borderColor, width: tokens.borders.thin),
              ),
              child: indeterminate
                  ? Container(
                      width: tokens.x * 2.5,
                      height: tokens.borders.thick,
                      decoration: BoxDecoration(color: glyphColor, borderRadius: tokens.radius.fullAll),
                    )
                  : (value ? Icon(Icons.check, size: tokens.x * 3.5, color: glyphColor) : const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}
