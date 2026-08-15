import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A themed value slider, drawn entirely from `UtopiaThemeData` - no Material
/// `Slider` underneath, so it carries none of Material's foreign idioms (the
/// press halo, the floating value indicator, the tick marks) and its track,
/// fill and thumb follow the token scale instead of Material's fixed geometry.
///
/// Fully controlled, like every other control here: it renders [value] and
/// reports the value under the pointer through [onChanged]. A tap anywhere on
/// the track jumps to that value (animated over `durations.sm`); a horizontal
/// drag follows the pointer one-to-one, unanimated, so the thumb never lags
/// the finger.
///
/// The track spans the full available width, and the thumb's centre travels
/// between the two half-thumb insets, so the thumb stays inside the control's
/// box at both ends of the range.
///
/// ```dart
/// UtopiaSlider(
///   value: volume.value,
///   onChanged: (next) => volume.value = next,
///   max: 100,
///   divisions: 20,
/// )
/// ```
class UtopiaSlider extends HookWidget {
  /// The value the slider renders, in `[min, max]`.
  ///
  /// Asserted to be in range in debug builds, and clamped when drawing, so a
  /// stale out-of-range value from a parent still renders at an end of the
  /// track rather than off it.
  final double value;

  /// Called with the value under the pointer on a tap or a drag; `null`
  /// disables interaction.
  ///
  /// With [divisions] set, the reported value is always snapped to a step -
  /// the widget never reports a value it could not render.
  final void Function(double)? onChanged;

  /// The lower end of the range, rendered at the left edge of the track.
  final double min;

  /// The upper end of the range, rendered at the right edge of the track.
  /// Must be greater than [min].
  final double max;

  /// When set, the number of equal steps the range is divided into: the
  /// values reported through [onChanged] snap to `min + n * (max - min) /
  /// divisions`.
  ///
  /// Deliberately without a visual expression - no tick marks. The system's
  /// restraint doctrine keeps a resting control quiet, and a snapping thumb
  /// already tells the user the range is stepped. Must be greater than zero.
  final int? divisions;

  /// When `true`, blocks interaction while keeping the full-color styling
  /// (instead of a faded disabled look).
  final bool readOnly;

  /// Fade applied when [onChanged] is `null` without [readOnly] - the
  /// disabled affordance a Material `Slider` would otherwise provide.
  /// Deliberately duplicated from `UtopiaSwitch._disabledOpacity` (and the
  /// check box's / radio's) rather than hoisted into a token: the token tree
  /// is closed, and one shared private constant across four files would
  /// outweigh the duplication it saves.
  static const double _disabledOpacity = 0.5;

  /// Fallback width used when the slider is laid out without a bounded width
  /// (a `Row` child with no `Expanded` around it). A slider has no intrinsic
  /// width of its own, so - like Material's - it falls back to a usable
  /// default instead of overflowing; the value is a token multiple so it
  /// rescales on a rebrand.
  static const double _unboundedWidthMultiple = 36;

  /// Number of steps a continuous slider moves per accessibility increase /
  /// decrease action. A stepped slider uses its own [divisions] instead.
  static const int _semanticSteps = 10;

  /// Creates a themed value slider.
  const UtopiaSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.readOnly = false,
  }) : assert(min < max, 'UtopiaSlider needs a non-empty range: min must be less than max'),
       assert(value >= min && value <= max, 'UtopiaSlider value must sit inside [min, max]'),
       assert(divisions == null || divisions > 0, 'UtopiaSlider divisions must be greater than zero');

  /// Snaps [raw] to the nearest step when [divisions] is set, and clamps it to
  /// the range either way.
  double _resolve(double raw) {
    final clamped = raw.clamp(min, max);
    final steps = divisions;
    if (steps == null) return clamped;
    final step = (max - min) / steps;
    return (min + ((clamped - min) / step).roundToDouble() * step).clamp(min, max);
  }

  /// The announced value: at most two decimals, with trailing zeros trimmed
  /// (`0.40` -> `0.4`, `1.00` -> `1`).
  ///
  /// Deliberately the raw number rather than Material's "percent of the
  /// range": this slider is generic over `[min, max]`, so "40%" would be a
  /// lie for every range that is not a fraction. Consumers needing a domain
  /// label (currency, a unit suffix) wrap the slider in their own `Semantics`.
  static String _announce(double value) {
    final fixed = value.toStringAsFixed(2);
    if (!fixed.contains('.')) return fixed;
    return fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    final interactive = !readOnly && onChanged != null;
    final hovering = useState<bool>(false);
    final dragging = useState<bool>(false);
    // Geometry derives from the token base (a 1x track carrying the selection
    // family's 5x thumb) so the slider rescales with every other control on a
    // base-unit rebrand; the twin mirrors these multiples in `components.css`.
    final trackHeight = tokens.x;
    final thumbExtent = tokens.x * 5;
    final thumbRadius = thumbExtent / 2;
    // readOnly is a display-of-state mode, so it keeps the full-color styling;
    // a null onChanged is a disabled control and reads as one.
    final faded = !readOnly && onChanged == null;
    // The edge leads and the fill supports: the thumb is defined by its
    // border, which steps one shade darker on hover and to the primary while
    // the value is being dragged - the same doctrine the fields and the
    // selection controls follow. No resting shadow: controls in this system
    // never carry one.
    final thumbBorderColor = dragging.value
        ? colors.primary
        : (interactive && hovering.value ? colors.hint : colors.disabled);
    final fraction = (value.clamp(min, max) - min) / (max - min);
    // A drag has to track the pointer exactly; everything else (a tap on the
    // track, a value pushed in from outside) moves over the standard small
    // duration.
    final duration = dragging.value ? Duration.zero : tokens.durations.sm;

    return Semantics(
      slider: true,
      enabled: interactive,
      value: _announce(value),
      increasedValue: _announce(_resolve(value + _step)),
      decreasedValue: _announce(_resolve(value - _step)),
      onIncrease: interactive ? () => onChanged!(_resolve(value + _step)) : null,
      onDecrease: interactive ? () => onChanged!(_resolve(value - _step)) : null,
      child: Opacity(
        opacity: faded ? _disabledOpacity : 1,
        child: MouseRegion(
          cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => hovering.value = true,
          onExit: (_) => hovering.value = false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.hasBoundedWidth ? constraints.maxWidth : tokens.x * _unboundedWidthMultiple;
              // The thumb's centre travels between the half-thumb insets, so
              // the thumb sits inside the box at both ends; the fill runs from
              // the left edge to that centre.
              final travel = math.max(0.0, width - thumbExtent);
              final centre = thumbRadius + fraction * travel;

              void report(double dx) {
                if (travel == 0) return;
                final position = ((dx - thumbRadius) / travel).clamp(0.0, 1.0);
                onChanged!(_resolve(min + position * (max - min)));
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                // A tap reports on release rather than on press, so a drag
                // that starts with a press never reports its origin twice.
                onTapUp: interactive ? (details) => report(details.localPosition.dx) : null,
                onHorizontalDragStart: interactive
                    ? (details) {
                        dragging.value = true;
                        report(details.localPosition.dx);
                      }
                    : null,
                onHorizontalDragUpdate: interactive ? (details) => report(details.localPosition.dx) : null,
                onHorizontalDragEnd: interactive ? (_) => dragging.value = false : null,
                onHorizontalDragCancel: interactive ? () => dragging.value = false : null,
                child: SizedBox(
                  width: width,
                  height: thumbExtent,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: width,
                          height: trackHeight,
                          decoration: BoxDecoration(color: colors.border, borderRadius: tokens.radius.fullAll),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: duration,
                          curve: Curves.ease,
                          width: centre,
                          height: trackHeight,
                          decoration: BoxDecoration(color: colors.primary, borderRadius: tokens.radius.fullAll),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: duration,
                        curve: Curves.ease,
                        left: centre - thumbRadius,
                        top: 0,
                        child: AnimatedContainer(
                          duration: tokens.durations.xs,
                          curve: Curves.ease,
                          width: thumbExtent,
                          height: thumbExtent,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: tokens.radius.fullAll,
                            border: Border.all(color: thumbBorderColor, width: tokens.borders.thin),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// One accessibility increase / decrease step: a division when the slider is
  /// stepped, a tenth of the range when it is continuous.
  double get _step => (max - min) / (divisions ?? _semanticSteps);
}
