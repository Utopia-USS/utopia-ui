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

  static const UtopiaThemeTextStyles defaultTheme = UtopiaThemeTextStyles(
    header: TextStyle(
      fontFamily: "Sora",
      package: "utopia_ui",
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: Colors.black87,
      letterSpacing: -0.5,
    ),
    label: TextStyle(
      fontFamily: "Sora",
      package: "utopia_ui",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.black87,
      letterSpacing: -0.1,
    ),
    caption: TextStyle(
      fontFamily: "Sora",
      package: "utopia_ui",
      fontWeight: FontWeight.w500,
      fontSize: 10,
      color: Colors.black87,
      letterSpacing: 0,
    ),
    text: TextStyle(
      fontFamily: "Sora",
      package: "utopia_ui",
      fontWeight: FontWeight.w500,
      fontSize: 12,
      color: Colors.black87,
      letterSpacing: -0.1,
    ),
    title: TextStyle(
      fontFamily: "Sora",
      package: "utopia_ui",
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: Colors.black87,
      letterSpacing: -0.3,
    ),
    button: TextStyle(
      fontFamily: "Sora",
      package: "utopia_ui",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.white,
      letterSpacing: -0.1,
    ),
  );
}
