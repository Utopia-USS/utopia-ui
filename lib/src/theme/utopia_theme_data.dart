import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:utopia_ui/src/theme/utopia_theme_colors.dart';
import 'package:utopia_ui/src/theme/utopia_theme_text_styles.dart';
import 'package:utopia_ui/src/theme/utopia_tokens.dart';

part 'utopia_theme_data.freezed.dart';

/// The aggregate theme carried through context: the token scale, the colour
/// and type families, and the small set of *semantic* slots - values that
/// encode a design decision beyond "which token" (which radius step controls
/// use, the optically-biased field padding, the table row height).
///
/// Anything that is a pure alias of one token (shadows, stroke widths, the
/// chip radius) is exposed as a derived getter instead of a stored slot, so
/// it always tracks [tokens] - swapping or rescaling the token set can never
/// leave a stale copy behind. To tune those values, tune the token family
/// they derive from.
@freezed
abstract class UtopiaThemeData with _$UtopiaThemeData {
  const UtopiaThemeData._();

  const factory UtopiaThemeData({
    /// The foundational token scale (base unit, spacing, radii) this theme
    /// carries. Components resolve it through context - `context.theme.tokens`
    /// or the `context.spacing` / `context.radius` shorthands - so nested
    /// `UtopiaTheme`s can swap or rescale the whole system per subtree.
    @Default(UtopiaTokens()) UtopiaTokens tokens,
    required UtopiaThemeColors colors,
    required UtopiaThemeTextStyles textStyles,

    /// Corner radius of interactive controls (fields, buttons, tiles) -
    /// which radius step controls sit on is a theme decision, so this is a
    /// slot rather than a fixed token alias.
    required BorderRadius borderRadius,
    required EdgeInsets fieldContentPadding,

    /// Minimum height of the content area inside a field's chrome (the
    /// `UtopiaFieldWrapper` floor). Total resting field height is this plus
    /// the vertical [fieldContentPadding].
    @Default(44.0) double fieldMinHeight,

    /// Vertical padding above page-level content (and the sidebar rail).
    required double pageTopPadding,

    /// Corner radius of card surfaces (the table card, dialogs).
    @Default(BorderRadius.all(Radius.circular(16))) BorderRadius cardRadius,

    /// Height of a single table row.
    @Default(58.0) double tileHeight,
  }) = _UtopiaThemeData;

  /// Builds a theme whose every dimensional slot (radii, padding, spacing) is
  /// derived from [tokens] - the canonical way to construct a
  /// [UtopiaThemeData] so the whole theme sits on one grid. Pass a rescaled
  /// set (`UtopiaTokens.fromBase(5)`) to resize the entire system; use
  /// `copyWith` afterwards for per-slot deviations.
  ///
  /// The raw constructor stays available for fully manual themes, but its
  /// dimensional defaults are frozen at the 4-based scale and do not follow
  /// [tokens].
  factory UtopiaThemeData.fromTokens({
    required UtopiaThemeColors colors,
    required UtopiaThemeTextStyles textStyles,
    UtopiaTokens tokens = const UtopiaTokens(),
  }) {
    final spacing = tokens.spacing;
    final radius = tokens.radius;
    return UtopiaThemeData(
      tokens: tokens,
      colors: colors,
      textStyles: textStyles,
      borderRadius: radius.mdAll,
      cardRadius: radius.xlAll,
      // Vertically biased on purpose: the text stack is box-symmetric inside
      // the chrome, but the value line reserves descender space below the
      // baseline that digits/caps never fill, which reads as extra bottom gap.
      // Shifting the content down 0.5x rebalances the *visual* gaps.
      fieldContentPadding: EdgeInsets.fromLTRB(spacing.lg, tokens.x * 2.5, spacing.lg, tokens.x * 1.5),
      fieldMinHeight: tokens.x * 11,
      pageTopPadding: spacing.xxxl,
    );
  }

  static final UtopiaThemeData defaultTheme = UtopiaThemeData.fromTokens(
    colors: UtopiaThemeColors.defaultTheme,
    textStyles: UtopiaThemeTextStyles.defaultTheme,
  );

  /// Shorthand for `tokens.spacing`.
  UtopiaSpacingTokens get spacing => tokens.spacing;

  /// Shorthand for `tokens.radius`.
  UtopiaRadiusTokens get radius => tokens.radius;

  /// Drop shadow of floating overlays (menus, the gradient rail).
  List<BoxShadow> get menuShadow => tokens.shadows.lg;

  /// Drop shadow cast by card surfaces.
  List<BoxShadow> get cardShadow => tokens.shadows.sm;

  /// Stroke width of the card's hairline border.
  double get cardBorderWidth => tokens.borders.thin;

  /// Thickness of row / header dividers.
  double get dividerThickness => tokens.borders.hairline;

  /// Corner radius of a `UtopiaChip` - one step below [borderRadius], so a
  /// badge never reads as rounder than the control it sits in.
  double get chipRadius => tokens.radius.sm;

  BoxDecoration get fieldDecoration => BoxDecoration(borderRadius: borderRadius, color: colors.field);

  /// Fill + radius + shadow for the table card (the back layer of the card).
  BoxDecoration get cardDecoration =>
      BoxDecoration(color: colors.surface, borderRadius: cardRadius, boxShadow: cardShadow);

  /// Card chrome lifted to the overlay tier: a dialog sits above a barrier,
  /// so it takes [menuShadow] rather than the resting [cardShadow] a card
  /// underneath it would use.
  BoxDecoration get dialogDecoration => cardDecoration.copyWith(boxShadow: menuShadow);

  /// Foreground hairline border for the table card, drawn on top of its content.
  BoxDecoration get cardBorderDecoration => BoxDecoration(
    borderRadius: cardRadius,
    border: Border.all(color: colors.border, width: cardBorderWidth),
  );
}
