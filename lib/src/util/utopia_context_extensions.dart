import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/theme/utopia_theme.dart';
import 'package:utopia_ui/src/theme/utopia_theme_colors.dart';
import 'package:utopia_ui/src/theme/utopia_theme_data.dart';
import 'package:utopia_ui/src/theme/utopia_theme_text_styles.dart';

/// Shorthand theme lookups: `context.theme`, `context.colors`,
/// `context.textStyles`, `context.fieldDecoration`.
///
/// Backed by [UtopiaTheme.of], so they fall back to
/// [UtopiaThemeData.defaultTheme] when no [UtopiaTheme] ancestor exists.
extension UtopiaThemeContextExtensions on BuildContext {
  /// The ambient `UtopiaThemeData`, resolved via [UtopiaTheme.of].
  UtopiaThemeData get theme => UtopiaTheme.of(this);

  /// Shorthand for `theme.colors`.
  UtopiaThemeColors get colors => theme.colors;

  /// Shorthand for `theme.textStyles`.
  UtopiaThemeTextStyles get textStyles => theme.textStyles;

  /// Shorthand for `theme.fieldDecoration`.
  BoxDecoration get fieldDecoration => theme.fieldDecoration;
}
