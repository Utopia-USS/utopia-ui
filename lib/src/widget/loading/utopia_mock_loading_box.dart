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
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: context.colors.field,
        highlightColor: context.colors.field.withValues(alpha: 0.2),
        child: Container(height: height, width: width, color: context.colors.canvas),
      ),
    );
  }
}
