import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A shimmering rectangle placeholder for text/content that has not loaded
/// yet - a skeleton-loading building block sized to mimic the real content.
class UtopiaMockLoadingBox extends StatelessWidget {
  /// The placeholder's height.
  final double height;

  /// The placeholder's width.
  final double width;

  /// Optional padding around the shimmering box.
  final EdgeInsets? padding;

  /// Creates a shimmering skeleton-loading placeholder.
  const UtopiaMockLoadingBox({super.key, this.height = 6, this.width = 60, this.padding});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The skeleton is a placeholder, so it rests one step INTO the page rather
    // than above it: `hover` is the cool tint that reads on both grounds a
    // skeleton ever lands on (a white surface card, e.g. `UtopiaTable`'s loader
    // rows, and the canvas), while `field` - the previous base - sits lighter
    // than the canvas and made the bar disappear into it. The sweep then runs
    // UP to `surface`, so the shimmer brightens like every other skeleton in
    // the reference systems instead of dimming. Both colours are opaque: an
    // alpha highlight composites against the child and inverted the sweep's
    // direction, which is what flattened the animation before.
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: colors.hover,
        highlightColor: colors.surface,
        // Shimmer masks the child (srcATop), so the child only supplies the
        // silhouette - painted in the base colour so the box still reads as a
        // skeleton in the frame before the first sweep.
        child: Container(height: height, width: width, color: colors.hover),
      ),
    );
  }
}
