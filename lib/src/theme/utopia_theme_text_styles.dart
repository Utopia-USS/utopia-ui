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
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
      fontSize: 24,
      color: Colors.black87,
      letterSpacing: 1,
    ),
    label: TextStyle(
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.black87,
      letterSpacing: 1,
    ),
    caption: TextStyle(
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
      fontSize: 10,
      color: Colors.black87,
      letterSpacing: 1,
    ),
    text: TextStyle(
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.black87,
      letterSpacing: 1,
    ),
    title: TextStyle(
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: Colors.black87,
      letterSpacing: 1,
    ),
    button: TextStyle(
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.white,
      letterSpacing: 1,
    ),
  );
}
