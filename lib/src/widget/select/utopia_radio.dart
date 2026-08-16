import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A themed radio button, drawn entirely from `UtopiaThemeData` - no Material
/// `Radio` underneath, so its extent and stroke widths follow the token scale
/// and its chrome matches `UtopiaCheckbox` exactly (same square extent, same
/// resting border, same hover step), differing only in shape and glyph.
///
/// Fully controlled and generic over the option type [T]: the button renders
/// as selected while `value == groupValue`, and every tap reports [value]
/// through [onChanged] - including a tap on the already-selected option, so
/// the owner of the group decides whether re-selecting is a no-op or clears
/// the group.
///
/// ```dart
/// UtopiaRadio<Plan>(
///   value: Plan.pro,
///   groupValue: selected.value,
///   onChanged: (plan) => selected.value = plan,
/// )
/// ```
class UtopiaRadio<T> extends HookWidget {
  /// The option this button stands for.
  final T value;

  /// The group's currently selected option; the button renders as selected
  /// while it equals [value].
  final T? groupValue;

  /// Called with [value] when tapped; `null` disables interaction.
  final void Function(T)? onChanged;

  /// When `true`, blocks interaction while keeping the full-color styling
  /// (instead of a faded disabled look).
  final bool readOnly;

  /// Fade applied when [onChanged] is `null` without [readOnly] - the
  /// disabled affordance a Material `Radio` would otherwise provide.
  /// Deliberately duplicated from `UtopiaCheckbox._disabledOpacity` (and
  /// `UtopiaSwitch._disabledOpacity`) rather than hoisted into a token: the
  /// token tree is closed, and one shared private constant across three files
  /// would outweigh the duplication it saves.
  static const double _disabledOpacity = 0.5;

  /// Creates a themed radio button for one option of a group.
  const UtopiaRadio({super.key, required this.value, this.groupValue, this.onChanged, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    final interactive = !readOnly && onChanged != null;
    final hovering = useState<bool>(false);
    final selected = value == groupValue;
    // The dot sits on a primary fill - the same ground a UtopiaButton's label
    // sits on - so it follows the button text colour instead of hard-coding
    // white. Same rule as UtopiaSwitch's thumb and UtopiaCheckbox's glyph.
    final dotColor = context.textStyles.button.color ?? const Color(0xFFFFFFFF);
    // Geometry derives from the token base (a 5x circle carrying a 1.5x dot),
    // matching UtopiaCheckbox's extent so a mixed column of check boxes and
    // radio buttons lines up; the twin mirrors these multiples in
    // `components.css`.
    final extent = tokens.x * 5;
    final dotExtent = tokens.x * 1.5;
    // readOnly is a display-of-state mode, so it keeps the full-color styling;
    // a null onChanged is a disabled control and reads as one.
    final faded = !readOnly && onChanged == null;
    // Identical doctrine to UtopiaCheckbox: the edge leads while the button is
    // empty (stepping one shade darker on hover) and gives way to the primary
    // fill once the option is the selected one.
    final borderColor = selected ? colors.primary : (interactive && hovering.value ? colors.hint : colors.disabled);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: interactive,
      child: Opacity(
        opacity: faded ? _disabledOpacity : 1,
        child: MouseRegion(
          cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => hovering.value = true,
          onExit: (_) => hovering.value = false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: interactive ? () => onChanged!(value) : null,
            child: AnimatedContainer(
              duration: tokens.durations.xs,
              curve: Curves.ease,
              width: extent,
              height: extent,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.primary : colors.field,
                borderRadius: tokens.radius.fullAll,
                border: Border.all(color: borderColor, width: tokens.borders.thin),
              ),
              // The dot grows out of nothing rather than fading in, so the
              // selection reads as a single motion with the fill.
              child: AnimatedContainer(
                duration: tokens.durations.xs,
                curve: Curves.ease,
                width: selected ? dotExtent : 0,
                height: selected ? dotExtent : 0,
                decoration: BoxDecoration(color: dotColor, borderRadius: tokens.radius.fullAll),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
