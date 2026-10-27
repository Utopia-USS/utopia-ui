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
    /// the vertical [fieldContentPadding] and the two hairline borders, and
    /// that total is pinned to a resting `UtopiaButton`'s extent (48 at the
    /// default 4-based scale): a field and a button standing side by side in
    /// a toolbar row must be exactly as tall as each other.
    @Default(34.0) double fieldMinHeight,

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
  ///
  /// [textStyles] is optional: omitted, the type family is
  /// `UtopiaThemeTextStyles.fromColors(colors)` - the default ramp wearing this
  /// palette's tones - so a theme is fully determined by its colours. Pass a
  /// family explicitly only to change the type *structure*, and build it with
  /// `fromColors` too if it should keep tracking the palette.
  factory UtopiaThemeData.fromTokens({
    required UtopiaThemeColors colors,
    UtopiaThemeTextStyles? textStyles,
    UtopiaTokens tokens = const UtopiaTokens(),
  }) {
    final spacing = tokens.spacing;
    final radius = tokens.radius;
    return UtopiaThemeData(
      tokens: tokens,
      colors: colors,
      textStyles: textStyles ?? UtopiaThemeTextStyles.fromColors(colors),
      // Controls sit on radius.lg (12): a visible step of softness on a 48px
      // control while the ladder stays monotonic - chip (6) < controls (12) <
      // cards (16). radius.md (8) read stiff next to the reference input bars
      // this scale is calibrated against.
      borderRadius: radius.lgAll,
      cardRadius: radius.xlAll,
      // Vertically biased on purpose: the text stack is box-symmetric inside
      // the chrome, but the value line reserves descender space below the
      // baseline that digits/caps never fill, which reads as extra bottom gap.
      // Shifting the content down 0.5x rebalances the *visual* gaps.
      fieldContentPadding: EdgeInsets.fromLTRB(spacing.lg, tokens.x * 2, spacing.lg, tokens.x * 1),
      fieldMinHeight: tokens.x * 8.5,
      pageTopPadding: spacing.xxxl,
    );
  }

  /// The shipped light theme: the default token scale wearing
  /// `UtopiaThemeColors.defaultTheme`.
  static final UtopiaThemeData defaultTheme = UtopiaThemeData.fromTokens(colors: UtopiaThemeColors.defaultTheme);

  /// The shipped dark theme - the same token scale and type ramp as
  /// [defaultTheme], differing only in `UtopiaThemeColors.darkTheme`. Dark mode
  /// therefore costs a consumer one line:
  ///
  /// ```dart
  /// UtopiaTheme(
  ///   data: MediaQuery.platformBrightnessOf(context) == Brightness.dark
  ///       ? UtopiaThemeData.darkTheme
  ///       : UtopiaThemeData.defaultTheme,
  ///   child: ...,
  /// )
  /// ```
  ///
  /// A branded app does the same over its own palette rather than copying this
  /// one: build the dark colours, and the type and elevation follow.
  static final UtopiaThemeData darkTheme = UtopiaThemeData.fromTokens(colors: UtopiaThemeColors.darkTheme);

  /// Shorthand for `tokens.spacing`.
  UtopiaSpacingTokens get spacing => tokens.spacing;

  /// Shorthand for `tokens.radius`.
  UtopiaRadiusTokens get radius => tokens.radius;

  /// Drop shadow of floating overlays (menus, the gradient rail).
  List<BoxShadow> get menuShadow => _tinted(tokens.shadows.lg);

  /// Drop shadow cast by card surfaces.
  List<BoxShadow> get cardShadow => _tinted(tokens.shadows.sm);

  /// Paints an elevation preset in the palette's shadow hue.
  ///
  /// `UtopiaShadowTokens` owns the *geometry* of each preset - offset, blur,
  /// spread, and the per-layer alpha that makes a stack read as one shadow -
  /// while `UtopiaThemeColors.shadow` owns the hue. Only the tint's RGB is
  /// taken; every layer keeps its own alpha, so a stack's internal balance
  /// survives a re-tint and re-tinting an already-tinted stack is a no-op.
  ///
  /// That idempotence is load-bearing: the design protocol exports the tinted
  /// stack (what actually paints) and reads it back into a theme that tints
  /// again, so anything but an exactly repeatable operation would compound on
  /// every export/generate cycle. To make elevation globally heavier or
  /// lighter, tune the alphas in `tokens.shadows` - the family that owns them.
  List<BoxShadow> _tinted(List<BoxShadow> preset) {
    final tint = colors.shadow;
    return [
      for (final layer in preset) layer.copyWith(color: tint.withValues(alpha: layer.color.a)),
    ];
  }

  /// Stroke width of the card's hairline border.
  double get cardBorderWidth => tokens.borders.thin;

  /// Thickness of row / header dividers.
  double get dividerThickness => tokens.borders.hairline;

  /// Corner radius of a `UtopiaChip` - the smallest usable tier, well below
  /// [borderRadius], so a badge never reads as rounder than the control it
  /// sits in.
  double get chipRadius => tokens.radius.sm;

  /// Field chrome at rest: fill, radius and the quiet hairline edge.
  ///
  /// The border belongs to the decoration rather than the widget so every
  /// state below is one `copyWith` away from it and the stroke width is
  /// identical in all of them - focus and error change colour, never
  /// geometry.
  BoxDecoration get fieldDecoration => BoxDecoration(
    borderRadius: borderRadius,
    color: colors.field,
    border: Border.all(color: colors.border, width: tokens.borders.hairline),
  );

  /// Hovered field chrome: the edge steps toward [UtopiaThemeColors.hint].
  /// The fill is unchanged - a field should acknowledge the pointer, not
  /// light up.
  BoxDecoration get fieldHoverDecoration => fieldDecoration.copyWith(
    border: Border.all(
      color: Color.lerp(colors.border, colors.hint, 0.35)!,
      width: tokens.borders.hairline,
    ),
  );

  /// Focused field chrome: the edge turns [UtopiaThemeColors.primary] and
  /// thickens to `borders.thick` in total - one hairline inward (the border
  /// itself) plus one hairline outward (an unblurred shadow, so the ring has
  /// a hard edge). That composition is the Flutter equivalent of the twin's
  /// `outline: 2px solid primary; outline-offset: -1px`, which Flutter has no
  /// primitive for. The fill lifts to [UtopiaThemeColors.surface] so the
  /// field reads as live.
  ///
  /// Geometry note: the outward half is a shadow, so focusing never shifts
  /// layout.
  BoxDecoration get fieldFocusDecoration => fieldDecoration.copyWith(
    color: colors.surface,
    border: Border.all(color: colors.primary, width: tokens.borders.hairline),
    boxShadow: [BoxShadow(color: colors.primary, spreadRadius: tokens.borders.hairline)],
  );

  /// Errored field chrome: the resting shape in the error hue.
  BoxDecoration get fieldErrorDecoration =>
      fieldDecoration.copyWith(border: Border.all(color: colors.error, width: tokens.borders.hairline));

  /// Errored *and* focused field chrome: the focus ring in the error hue, so
  /// a field being corrected keeps signalling the error instead of reverting
  /// to the neutral focus look.
  BoxDecoration get fieldErrorFocusDecoration => fieldErrorDecoration.copyWith(
    boxShadow: [BoxShadow(color: colors.error, spreadRadius: tokens.borders.hairline)],
  );

  /// Read-only / inert field chrome: recessed to the page colour, no ring,
  /// edge left quiet - the field reads as a value on the page rather than a
  /// control waiting for input.
  BoxDecoration get fieldReadOnlyDecoration => fieldDecoration.copyWith(color: colors.canvas);

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
