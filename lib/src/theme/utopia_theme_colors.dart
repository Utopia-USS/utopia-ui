import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'utopia_theme_colors.freezed.dart';

@freezed
abstract class UtopiaThemeColors with _$UtopiaThemeColors {
  const UtopiaThemeColors._();

  factory UtopiaThemeColors({
    required Color primary,
    required Color accent,
    required Color field,
    required Color canvas,
    required Color error,
    required Color disabled,
    required Color text,

    /// Background of the table card and other raised surfaces.
    @Default(Color(0xFFFFFFFF)) Color surface,

    /// Hairline colour for the card border and row / header dividers.
    @Default(Color(0xFFE8EAF0)) Color border,

    /// Colour of `UtopiaDivider` hairlines. `null` (the default) derives a
    /// contrast-safe colour from [text] over [surface] at paint time, so
    /// dividers stay visible in any theme without being set explicitly.
    Color? divider,

    /// Tint of alternating (odd) table rows.
    @Default(Color(0xFFF7F8FB)) Color rowAlt,

    /// Row background while hovered.
    @Default(Color(0xFFEFF1F8)) Color hover,

    /// Fill of a `UtopiaChip`.
    @Default(Color(0xFFE7EAFD)) Color chipBackground,

    /// Content (text / icon) colour of a `UtopiaChip`.
    @Default(Color(0xFF536DFE)) Color chipForeground,

    /// Muted colour for hints, placeholders and secondary text.
    @Default(Color(0xFF9AA0B5)) Color hint,

    /// Content (text / icon) colour used by components rendered on an
    /// opt-in coloured / gradient background (e.g. `UtopiaSidebar`'s
    /// `backgroundColors` mode).
    required Color onColoredContent,

    /// Selected-state overlay colour used by components rendered on an
    /// opt-in coloured / gradient background (e.g. `UtopiaSidebar`'s
    /// `backgroundColors` mode).
    required Color onColoredSelected,

    /// Hover-state overlay colour used by components rendered on an opt-in
    /// coloured / gradient background (e.g. `UtopiaSidebar`'s
    /// `backgroundColors` mode).
    required Color onColoredHover,
  }) = _UtopiaThemeColors;

  static final UtopiaThemeColors defaultTheme = UtopiaThemeColors(
    primary: Colors.indigoAccent[200]!,
    accent: Colors.indigoAccent,
    error: Colors.redAccent,
    field: const Color(0xFFEDEDED),
    canvas: Colors.grey[100]!,
    disabled: Colors.grey[400]!,
    text: Colors.black87,
    onColoredContent: Colors.white.withValues(alpha: 0.85),
    onColoredSelected: Colors.white.withValues(alpha: 0.18),
    onColoredHover: Colors.white.withValues(alpha: 0.08),
  );
}
