import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'utopia_tokens.freezed.dart';

/// The base unit the default token scale derives from. Kept private: runtime
/// code reads the base from [UtopiaTokens.x] so a rescaled theme stays
/// consistent; this constant only seeds the compile-time defaults below.
const double _x = 4;

/// Foundational design tokens for the Utopia design system.
///
/// Every *spatial* token derives from a single base unit, [x] (4 logical
/// pixels by default). Tokens are plain data carried by `UtopiaThemeData` and
/// resolved through context (`context.tokens`, or the `context.spacing` /
/// `context.radius` shorthands), so an app - or any subtree under a nested
/// `UtopiaTheme` - can swap or rescale the whole system at runtime:
/// `UtopiaTokens.fromBase(5)` re-derives every spatial step from a new base.
///
/// Token families and their Mix / design-tool equivalents:
///
/// * `spacing` - `SpaceToken`: gaps, margins, padding
/// * `radius` - `RadiusToken`: corner radii
/// * `borders` - `BorderSideToken`: stroke widths (colour composes from
///   `UtopiaThemeColors` at the use site, keeping colour single-sourced)
/// * `shadows` - `BoxShadowToken`: elevation presets
/// * `fontWeights` - `FontWeightToken`: type weights
/// * `durations` - `DurationToken`: motion timing
/// * `breakpoints` - `BreakpointToken`: responsive thresholds
/// * `ColorToken` / `TextStyleToken` live as `UtopiaThemeColors` and
///   `UtopiaThemeTextStyles` on the theme itself; [x] covers the generic
///   `DoubleToken` role (`tokens.x * n` for one-off multiples).
///
/// The hierarchical identifiers below are the canonical names for mirroring
/// the system into external tools (Figma variables, CSS custom properties):
///
/// | Identifier          | Multiple | Default        |
/// |---------------------|----------|----------------|
/// | `spacing.xxs`       | 0.5x     | 2              |
/// | `spacing.xs`        | 1x       | 4              |
/// | `spacing.sm`        | 2x       | 8              |
/// | `spacing.md`        | 3x       | 12             |
/// | `spacing.lg`        | 4x       | 16             |
/// | `spacing.xl`        | 6x       | 24             |
/// | `spacing.xxl`       | 8x       | 32             |
/// | `spacing.xxxl`      | 12x      | 48             |
/// | `radius.xs`         | 1x       | 4              |
/// | `radius.sm`         | 1.5x     | 6              |
/// | `radius.md`         | 2x       | 8              |
/// | `radius.lg`         | 3x       | 12             |
/// | `radius.xl`         | 4x       | 16             |
/// | `border.hairline`   | -        | 1              |
/// | `border.thin`       | -        | 1.5            |
/// | `border.thick`      | -        | 2              |
/// | `shadow.sm`         | -        | y1 blur6 5%    |
/// | `shadow.md`         | -        | y2 blur10 15%  |
/// | `shadow.lg`         | -        | xy3 blur14 35% |
/// | `fontWeight.*`      | -        | 400-700        |
/// | `duration.xs`       | -        | 100ms          |
/// | `duration.sm`       | -        | 150ms          |
/// | `duration.md`       | -        | 200ms          |
/// | `duration.lg`       | -        | 300ms          |
/// | `duration.xl`       | -        | 400ms          |
/// | `breakpoint.tablet` | -        | 600            |
/// | `breakpoint.web`    | -        | 900            |
/// | `breakpoint.sidebar`| -        | 1000           |
@freezed
abstract class UtopiaTokens with _$UtopiaTokens {
  const UtopiaTokens._();

  const factory UtopiaTokens({
    /// The base unit of the design system. Every spacing and radius token is
    /// a multiple of this value. For a one-off multiple outside the named
    /// scale, derive it explicitly (`tokens.x * 5`) so it rescales with the
    /// system.
    @Default(_x) double x,

    /// Spacing scale - gaps, margins and padding.
    @Default(UtopiaSpacingTokens()) UtopiaSpacingTokens spacing,

    /// Corner-radius scale.
    @Default(UtopiaRadiusTokens()) UtopiaRadiusTokens radius,

    /// Stroke-width scale for borders and dividers.
    @Default(UtopiaBorderTokens()) UtopiaBorderTokens borders,

    /// Elevation (box-shadow) presets.
    @Default(UtopiaShadowTokens()) UtopiaShadowTokens shadows,

    /// Font-weight steps.
    @Default(UtopiaFontWeightTokens()) UtopiaFontWeightTokens fontWeights,

    /// Motion-timing scale.
    @Default(UtopiaDurationTokens()) UtopiaDurationTokens durations,

    /// Responsive layout thresholds.
    @Default(UtopiaBreakpointTokens()) UtopiaBreakpointTokens breakpoints,
  }) = _UtopiaTokens;

  /// Derives the spatial token families (`spacing`, `radius`) from [x],
  /// keeping every step on the same multiples as the default scale.
  /// Non-spatial families (borders, shadows, weights, durations,
  /// breakpoints) keep their defaults - adjust them with `copyWith`.
  factory UtopiaTokens.fromBase(double x) =>
      UtopiaTokens(x: x, spacing: UtopiaSpacingTokens.fromBase(x), radius: UtopiaRadiusTokens.fromBase(x));
}

/// Spacing scale - multiples of the base unit [UtopiaTokens.x].
///
/// Prefer these named steps; for a one-off multiple outside the scale use an
/// explicit `tokens.x * n` so the derivation stays visible and rescalable.
@freezed
abstract class UtopiaSpacingTokens with _$UtopiaSpacingTokens {
  const factory UtopiaSpacingTokens({
    /// 0.5x = 2. Hairline gaps, icon-to-text nudges.
    @Default(_x * 0.5) double xxs,

    /// 1x = 4. Tight gaps inside compact controls.
    @Default(_x) double xs,

    /// 2x = 8. Default gap between related elements.
    @Default(_x * 2) double sm,

    /// 3x = 12. Gap between loosely related elements.
    @Default(_x * 3) double md,

    /// 4x = 16. Standard content padding.
    @Default(_x * 4) double lg,

    /// 6x = 24. Section padding, dialog insets.
    @Default(_x * 6) double xl,

    /// 8x = 32. Gap between distinct content blocks.
    @Default(_x * 8) double xxl,

    /// 12x = 48. Page-level padding.
    @Default(_x * 12) double xxxl,
  }) = _UtopiaSpacingTokens;

  /// Derives every step from a base unit [x].
  factory UtopiaSpacingTokens.fromBase(double x) => UtopiaSpacingTokens(
    xxs: x * 0.5,
    xs: x,
    sm: x * 2,
    md: x * 3,
    lg: x * 4,
    xl: x * 6,
    xxl: x * 8,
    xxxl: x * 12,
  );
}

/// Corner-radius scale - multiples of the base unit [UtopiaTokens.x].
///
/// Each step is available as a raw [double] and as a ready-made uniform
/// [BorderRadius] (`smAll`, `mdAll`, ...) for direct use in decorations.
@freezed
abstract class UtopiaRadiusTokens with _$UtopiaRadiusTokens {
  const UtopiaRadiusTokens._();

  const factory UtopiaRadiusTokens({
    /// 1x = 4. Smallest rounding - tags, thumbnails.
    @Default(_x) double xs,

    /// 1.5x = 6. Fields and other inline controls.
    @Default(_x * 1.5) double sm,

    /// 2x = 8. Chips, buttons.
    @Default(_x * 2) double md,

    /// 3x = 12. Menus, popovers.
    @Default(_x * 3) double lg,

    /// 4x = 16. Cards and other large surfaces.
    @Default(_x * 4) double xl,

    /// Effectively-infinite radius for pill / circular shapes.
    @Default(9999.0) double full,
  }) = _UtopiaRadiusTokens;

  /// Derives every step from a base unit [x]. [full] stays effectively
  /// infinite regardless of base.
  factory UtopiaRadiusTokens.fromBase(double x) =>
      UtopiaRadiusTokens(xs: x, sm: x * 1.5, md: x * 2, lg: x * 3, xl: x * 4);

  BorderRadius get xsAll => BorderRadius.all(Radius.circular(xs));
  BorderRadius get smAll => BorderRadius.all(Radius.circular(sm));
  BorderRadius get mdAll => BorderRadius.all(Radius.circular(md));
  BorderRadius get lgAll => BorderRadius.all(Radius.circular(lg));
  BorderRadius get xlAll => BorderRadius.all(Radius.circular(xl));
  BorderRadius get fullAll => BorderRadius.all(Radius.circular(full));
}

/// Stroke-width scale for borders and dividers.
///
/// Widths only: colour composes from `UtopiaThemeColors` at the use site
/// (`BorderSide(color: colors.border, width: tokens.borders.thin)`), keeping
/// colour single-sourced in the theme.
@freezed
abstract class UtopiaBorderTokens with _$UtopiaBorderTokens {
  const factory UtopiaBorderTokens({
    /// 1.0. Row / header dividers, subtle separators.
    @Default(1.0) double hairline,

    /// 1.5. Card and field outlines.
    @Default(1.5) double thin,

    /// 2.0. Emphasised / focus outlines.
    @Default(2.0) double thick,
  }) = _UtopiaBorderTokens;
}

/// Elevation presets - box shadows in increasing prominence.
@freezed
abstract class UtopiaShadowTokens with _$UtopiaShadowTokens {
  const factory UtopiaShadowTokens({
    /// Subtle lift for resting surfaces (cards).
    @Default(<BoxShadow>[BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 1))])
    List<BoxShadow> sm,

    /// Intermediate lift for hovering / dragged elements.
    @Default(<BoxShadow>[BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 2))])
    List<BoxShadow> md,

    /// Strong lift for floating overlays (menus, popovers).
    @Default(<BoxShadow>[BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(3, 3))])
    List<BoxShadow> lg,
  }) = _UtopiaShadowTokens;
}

/// Font-weight steps used across the type system.
@freezed
abstract class UtopiaFontWeightTokens with _$UtopiaFontWeightTokens {
  const factory UtopiaFontWeightTokens({
    /// Body copy.
    @Default(FontWeight.w400) FontWeight regular,

    /// Slight emphasis - secondary labels.
    @Default(FontWeight.w500) FontWeight medium,

    /// Primary emphasis - the system's default display weight.
    @Default(FontWeight.w600) FontWeight semiBold,

    /// Strong emphasis.
    @Default(FontWeight.w700) FontWeight bold,
  }) = _UtopiaFontWeightTokens;
}

/// Motion-timing scale for animations and transitions.
@freezed
abstract class UtopiaDurationTokens with _$UtopiaDurationTokens {
  const factory UtopiaDurationTokens({
    /// 100ms. Instant feedback - hovers, presses.
    @Default(Duration(milliseconds: 100)) Duration xs,

    /// 150ms. Small state changes - toggles, checkmarks.
    @Default(Duration(milliseconds: 150)) Duration sm,

    /// 200ms. Standard transitions - fades, colour shifts.
    @Default(Duration(milliseconds: 200)) Duration md,

    /// 300ms. Structural motion - expand / collapse, reflow.
    @Default(Duration(milliseconds: 300)) Duration lg,

    /// 400ms. Large movements - panels, drawers.
    @Default(Duration(milliseconds: 400)) Duration xl,
  }) = _UtopiaDurationTokens;
}

/// Responsive layout thresholds.
///
/// Same two families as `UtopiaBreakpoints`, carried as theme data so they
/// can be tuned per app. See that class for the content-vs-shell measurement
/// distinction; these tokens are the values, `UtopiaBreakpoints` remains the
/// compile-time default set.
@freezed
abstract class UtopiaBreakpointTokens with _$UtopiaBreakpointTokens {
  const factory UtopiaBreakpointTokens({
    /// At or above this *content* width the layout is at least tablet-class.
    @Default(600.0) double tabletMin,

    /// At or above this *content* width the layout is web-class.
    @Default(900.0) double webMin,

    /// At or above this *window* width the shell shows the sidebar as a rail;
    /// below it the sidebar hides behind a drawer.
    @Default(1000.0) double sidebarMin,
  }) = _UtopiaBreakpointTokens;
}
