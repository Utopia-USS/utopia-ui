import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// Three dots pulsing in a staggered wave - the loading indicator shown inside
/// `UtopiaButton`. Hand-rolled so this package does not depend on `flutter_spinkit`.
class UtopiaThreeBounce extends HookWidget {
  /// The dots' color. Defaults to `UtopiaThemeColors.primary`, the same
  /// activity colour `UtopiaLoader` rests on. Pass the content colour of the
  /// ground instead when the dots sit on a filled surface - which is what
  /// `UtopiaButton` does with its own label colour.
  final Color? color;

  /// The overall height of the indicator; dot size scales with it.
  final double size;

  /// Creates the staggered three-dot loading indicator.
  const UtopiaThreeBounce({super.key, this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: const Duration(milliseconds: 1400));
    useEffect(() {
      unawaited(controller.repeat());
      return null;
    }, [controller]);

    final dotSize = size * 0.5;
    // A null colour used to reach BoxDecoration untouched, and a BoxDecoration
    // with no colour paints no fill: a bare UtopiaThreeBounce() rendered three
    // invisible dots. The token default keeps the indicator visible wherever it
    // is dropped, on the same reading as UtopiaLoader (activity = brand).
    final dotColor = color ?? context.colors.primary;
    return SizedBox(
      height: size,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final scale = (math.sin((controller.value - index * 0.2) * 2 * math.pi) + 1) / 2;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: dotSize * 0.15),
              child: Transform.scale(
                scale: scale,
                child: SizedBox.square(
                  dimension: dotSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
