import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A page/section heading, styled with `UtopiaThemeTextStyles.title`.
class UtopiaTitle extends StatelessWidget {
  /// The heading text.
  final String title;

  /// Creates a page/section heading.
  const UtopiaTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: context.textStyles.title);
  }
}
