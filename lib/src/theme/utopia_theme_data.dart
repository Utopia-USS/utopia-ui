import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:utopia_ui/src/theme/utopia_theme_colors.dart';
import 'package:utopia_ui/src/theme/utopia_theme_text_styles.dart';

part 'utopia_theme_data.freezed.dart';

@freezed
abstract class UtopiaThemeData with _$UtopiaThemeData {
  const UtopiaThemeData._();

  const factory UtopiaThemeData({
    required UtopiaThemeColors colors,
    required UtopiaThemeTextStyles textStyles,
    required BorderRadius borderRadius,
    required EdgeInsets fieldContentPadding,
    required double pageTopPadding,
    required List<BoxShadow> menuShadow,
    required BorderRadius menuRadius,
    required double shortButtonWidth,

    /// Corner radius of the table card.
    @Default(BorderRadius.all(Radius.circular(16))) BorderRadius cardRadius,

    /// Stroke width of the table card border.
    @Default(1.5) double cardBorderWidth,

    /// Drop shadow cast by the table card.
    @Default(<BoxShadow>[BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 1))])
    List<BoxShadow> cardShadow,

    /// Height of a single table row.
    @Default(58.0) double tileHeight,

    /// Thickness of row / header dividers.
    @Default(1.0) double dividerThickness,

    /// Corner radius of a `UtopiaChip`.
    @Default(8.0) double chipRadius,
  }) = _UtopiaThemeData;

  static final UtopiaThemeData defaultTheme = UtopiaThemeData(
    colors: UtopiaThemeColors.defaultTheme,
    textStyles: UtopiaThemeTextStyles.defaultTheme,
    menuRadius: BorderRadius.circular(12),
    borderRadius: BorderRadius.circular(6),
    fieldContentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    menuShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        offset: const Offset(3, 3), //(x,y)
        blurRadius: 14,
      ),
    ],
    pageTopPadding: 48,
    shortButtonWidth: 144,
  );

  BoxDecoration get fieldDecoration => BoxDecoration(borderRadius: borderRadius, color: colors.field);

  /// Fill + radius + shadow for the table card (the back layer of the card).
  BoxDecoration get cardDecoration =>
      BoxDecoration(color: colors.surface, borderRadius: cardRadius, boxShadow: cardShadow);

  /// Foreground hairline border for the table card, drawn on top of its content.
  BoxDecoration get cardBorderDecoration => BoxDecoration(
    borderRadius: cardRadius,
    border: Border.all(color: colors.border, width: cardBorderWidth),
  );
}
