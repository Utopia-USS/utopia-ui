import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A small circular progress indicator, sized and coloured to fit inline in
/// text-scale contexts (e.g. a loading row or a compact overlay).
class UtopiaLoader extends StatelessWidget {
  /// Overrides the indicator's colour. Defaults to `UtopiaThemeColors.primary`:
  /// a running indicator reports activity, and activity is the brand colour in
  /// this system - the same reading `UtopiaThreeBounce(color: colors.primary)`
  /// carries. Pass a colour explicitly when the spinner sits on a coloured
  /// ground (e.g. `textStyles.button.color` inside a filled button).
  final Color? color;

  /// The square dimension of the indicator.
  final double size;

  /// Creates a small inline loading indicator.
  const UtopiaLoader({super.key, this.color, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: CircularProgressIndicator(color: color ?? context.colors.primary, strokeWidth: size / 6),
        ),
      ),
    );
  }
}
