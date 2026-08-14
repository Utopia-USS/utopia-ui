import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A page-level heading, styled with `UtopiaThemeTextStyles.header`.
///
/// Use this for the screen's top heading; use `UtopiaTitle` for section
/// headings within a page.
class UtopiaHeader extends StatelessWidget {
  /// The heading text.
  final String title;

  /// Creates a page-level heading.
  const UtopiaHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: context.textStyles.header);
  }
}
