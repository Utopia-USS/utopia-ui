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

    /// Hairline colour for the card border and the table header's bottom rule.
    /// Sits one step darker than [divider] so a surface's outer edge always
    /// reads stronger than the lines drawn inside it.
    @Default(Color(0xFFD8DCEB)) Color border,

    /// Colour of `UtopiaDivider` hairlines. `null` derives a contrast-safe
    /// colour from [text] over [surface] at paint time, so dividers stay
    /// visible in a hand-built theme (dark included) without being set
    /// explicitly. The default light theme sets it explicitly, one step
    /// lighter than [border].
    Color? divider,

    /// Tint of alternating (odd) table rows.
    @Default(Color(0xFFF6F7FC)) Color rowAlt,

    /// Row background while hovered.
    @Default(Color(0xFFEDF0FA)) Color hover,

    /// Fill of a `UtopiaChip`.
    @Default(Color(0xFFE9EDFD)) Color chipBackground,

    /// Content (text / icon) colour of a `UtopiaChip`.
    @Default(Color(0xFF3A4BCC)) Color chipForeground,

    /// Muted colour for hints, placeholders and secondary text.
    @Default(Color(0xFF6E748B)) Color hint,

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

  /// The light default palette: one hue family (225-233) at low saturation for
  /// every neutral and the same hue at full saturation for the brand, so no
  /// pure grey is left in the system. [primary] and [accent] are a deliberate
  /// pair - both clear 4.5:1 against white, so a white label is safe across the
  /// whole gradient sweep they define.
  static final UtopiaThemeColors defaultTheme = UtopiaThemeColors(
    primary: const Color(0xFF3F51E5),
    accent: const Color(0xFF4A5CE9),
    error: const Color(0xFFD3302F),
    field: const Color(0xFFF8F9FD),
    canvas: const Color(0xFFF4F5FA),
    disabled: const Color(0xFFB9BECF),
    text: const Color(0xFF14161F),
    divider: const Color(0xFFE6E9F2),
    onColoredContent: Colors.white.withValues(alpha: 0.85),
    onColoredSelected: Colors.white.withValues(alpha: 0.18),
    onColoredHover: Colors.white.withValues(alpha: 0.08),
  );
}
