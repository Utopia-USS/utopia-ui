import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'utopia_theme_colors.freezed.dart';

@freezed
abstract class UtopiaThemeColors with _$UtopiaThemeColors {
  const UtopiaThemeColors._();

  factory UtopiaThemeColors({
    required Color primary,
    required Color accent,

    /// Content (text / icon) colour of anything painted on the
    /// [primary] -> [accent] sweep - the filled button label above all.
    /// Must clear 4.5:1 against *both* ends of that sweep, since a gradient
    /// gives the label no single background to be checked against.
    @Default(Color(0xFFFFFFFF)) Color onPrimary,
    required Color field,
    required Color canvas,
    required Color error,
    required Color disabled,

    /// The heading tone: the strongest foreground in the system, carried by
    /// the `header` and `title` type styles.
    required Color text,

    /// The body tone - one step quieter than [text], carried by the `text`,
    /// `label` and `caption` type styles. Sits between [text] and [hint] so
    /// running copy recedes from headings without dropping to the muted tier.
    @Default(Color(0xFF5B6076)) Color textBody,

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

    /// Tint of every elevation shadow. `UtopiaShadowTokens` owns the geometry
    /// of each preset (offset, blur, spread and per-layer alpha); this supplies
    /// the hue only - its own alpha is ignored, since each layer keeps the
    /// alpha that gives the stack its shape. Tune `tokens.shadows` to make
    /// elevation heavier or lighter.
    ///
    /// Light themes use the system's blue-black rather than pure black so
    /// elevation stays in the neutrals' hue family. Dark themes should not try
    /// to compensate by darkening further - a shadow cannot out-darken a dark
    /// ground. There, separation is [border]'s job plus the
    /// [canvas]/[surface]/[rowAlt]/[hover] ramp, and the shadow only adds a
    /// faint halo.
    @Default(Color(0xFF101828)) Color shadow,

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

  /// The dark palette - [defaultTheme] inverted inside the same hue family
  /// (225-233), not a separate design. Everything structural (radii, spacing,
  /// type scale, elevation geometry) is shared; only these values differ,
  /// which is the whole point: `UtopiaThemeData.fromTokens(colors: darkTheme)`
  /// is a complete dark theme.
  ///
  /// Two things carry the dark ground where a light theme leans on shadow:
  ///
  /// * a stepped surface ramp - [canvas] `#0D0F16` -> [surface] `#161925` ->
  ///   [rowAlt] `#1C2030` -> [hover] `#242938` - so page, card, alternate row
  ///   and hover stay separable without a single drop shadow;
  /// * a [border] light enough to read (`#2E3446`), one step *above* [divider]
  ///   rather than below it: on a dark ground "stronger" means lighter, so the
  ///   light theme's border-darker-than-divider rule inverts.
  ///
  /// The brand pair lifts to `#6E7CFF` / `#828EFF` - a mid-tone brand goes
  /// muddy on a dark canvas - and that lift is what flips [onPrimary] to
  /// near-black: white clears only 3.5:1 on `#6E7CFF`, while `#0B0D14` clears
  /// 5.4:1 at the dark end of the sweep and 6.6:1 at the light end.
  static final UtopiaThemeColors darkTheme = UtopiaThemeColors(
    primary: const Color(0xFF6E7CFF),
    accent: const Color(0xFF828EFF),
    onPrimary: const Color(0xFF0B0D14),
    error: const Color(0xFFFF6B6B),
    field: const Color(0xFF11141E),
    canvas: const Color(0xFF0D0F16),
    disabled: const Color(0xFF454B60),
    text: const Color(0xFFEEF0F7),
    textBody: const Color(0xFF9AA0B4),
    hint: const Color(0xFF7E859B),
    surface: const Color(0xFF161925),
    border: const Color(0xFF2E3446),
    divider: const Color(0xFF242A3A),
    rowAlt: const Color(0xFF1C2030),
    hover: const Color(0xFF242938),
    chipBackground: const Color(0xFF232942),
    chipForeground: const Color(0xFFA9B4FF),
    shadow: const Color(0xFF000000),
    onColoredContent: Colors.white.withValues(alpha: 0.85),
    onColoredSelected: Colors.white.withValues(alpha: 0.18),
    onColoredHover: Colors.white.withValues(alpha: 0.08),
  );
}
