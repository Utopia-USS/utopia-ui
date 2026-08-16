import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'utopia_theme_text_styles.freezed.dart';

@freezed
abstract class UtopiaThemeTextStyles with _$UtopiaThemeTextStyles {
  const UtopiaThemeTextStyles._();

  const factory UtopiaThemeTextStyles({
    required TextStyle header,
    required TextStyle label,
    required TextStyle text,
    required TextStyle title,
    required TextStyle caption,
    required TextStyle button,
  }) = _UtopiaThemeTextStyles;

  /// The default type family. Colour carries a three-tier hierarchy so text
  /// stratifies without a new token: `#14161F` (18.0:1) is the heading tone
  /// carried by [header] / [title] and mirrored by `UtopiaThemeColors.text`,
  /// `#5B6076` (6.2:1) is the body tone carried by [text] / [label] /
  /// [caption], and `UtopiaThemeColors.hint` (`#6E748B`, 4.6:1) is the muted
  /// tone. Widgets that want the body tone simply honour the style's own
  /// colour instead of overriding it with `colors.text`.
  ///
  /// Deliberately NOT derived from the token base unit: readability is pinned
  /// to pixels, so rescaling the spatial grid leaves the type ramp alone.
  static const UtopiaThemeTextStyles defaultTheme = UtopiaThemeTextStyles(
    header: TextStyle(fontFamily: 'Sora', package: 'utopia_ui', fontWeight: FontWeight.w700, fontSize: 24, color: Color(0xFF14161F), letterSpacing: -0.5),
    title: TextStyle(fontFamily: 'Sora', package: 'utopia_ui', fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF14161F), letterSpacing: -0.3),
    label: TextStyle(fontFamily: 'Sora', package: 'utopia_ui', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF5B6076), letterSpacing: -0.1),
    text: TextStyle(fontFamily: 'Sora', package: 'utopia_ui', fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF5B6076), letterSpacing: -0.1),
    caption: TextStyle(fontFamily: 'Sora', package: 'utopia_ui', fontWeight: FontWeight.w500, fontSize: 10, color: Color(0xFF5B6076), letterSpacing: 0),
    button: TextStyle(fontFamily: 'Sora', package: 'utopia_ui', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white, letterSpacing: -0.1),
  );
}
