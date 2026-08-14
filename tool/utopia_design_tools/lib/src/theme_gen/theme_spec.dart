/// Pure-Dart resolved intermediate between a parsed [TokenDocument] and
/// generated Dart source (`dart_emitter.dart`). Every value lands as a plain
/// number, string or resolved-color record - aliases followed, derivations
/// not re-derived (the validator already checked coherence upstream). This
/// keeps the emitter a straightforward "print these values" pass with no
/// alias-walking or DTCG-shape knowledge of its own.
library;

import 'package:utopia_design_tools/src/dtcg/token_document.dart';

/// A resolved color: the 8-bit ARGB channels the generator emits as
/// `Color(0xAARRGGBB)`. Resolution rounds the DTCG `alpha` (a 0..1 double) to
/// an 8-bit channel the same way `Color.toARGB32()` does, so a round trip
/// through the exporter and back is stable.
class ResolvedColor {
  /// Creates a resolved color from already-8-bit [alpha]/[red]/[green]/[blue]
  /// channels (each 0..255).
  const ResolvedColor({required this.alpha, required this.red, required this.green, required this.blue});

  /// Builds a [ResolvedColor] from a DTCG color `$value` object: sRGB
  /// `components` (0..1 doubles) for the channels, `alpha` (0..1, defaults to
  /// 1 when absent per protocol SPEC 2.3) rounded to 8 bits.
  factory ResolvedColor.fromDtcg(Map<String, dynamic> value) {
    final components = (value['components'] as List).cast<num>();
    final alpha = (value['alpha'] as num?)?.toDouble() ?? 1.0;
    return ResolvedColor(
      alpha: _to8Bit(alpha),
      red: _to8Bit(components[0].toDouble()),
      green: _to8Bit(components[1].toDouble()),
      blue: _to8Bit(components[2].toDouble()),
    );
  }

  /// Alpha channel, 0..255.
  final int alpha;

  /// Red channel, 0..255.
  final int red;

  /// Green channel, 0..255.
  final int green;

  /// Blue channel, 0..255.
  final int blue;

  /// The packed ARGB32 value, matching `Color.toARGB32()`.
  int get argb32 => (alpha << 24) | (red << 16) | (green << 8) | blue;

  static int _to8Bit(double channel) => (channel * 255).round().clamp(0, 255);
}

/// A single resolved box-shadow layer.
class ResolvedShadowLayer {
  /// Creates a resolved shadow layer.
  const ResolvedShadowLayer({
    required this.color,
    required this.offsetX,
    required this.offsetY,
    required this.blur,
    required this.spread,
  });

  /// The layer's color.
  final ResolvedColor color;

  /// Horizontal offset in logical px.
  final double offsetX;

  /// Vertical offset in logical px.
  final double offsetY;

  /// Blur radius in logical px.
  final double blur;

  /// Spread radius in logical px.
  final double spread;
}

/// A resolved `textStyle.<role>` entry, paired with its sibling
/// `textStyle-colors.<role>` color (protocol SPEC 2.4).
class ResolvedTextStyle {
  /// Creates a resolved text style.
  const ResolvedTextStyle({
    required this.fontFamily,
    required this.fontFamilyFallback,
    required this.fontPackage,
    required this.fontSize,
    required this.fontWeight,
    required this.letterSpacing,
    required this.color,
  });

  /// The primary font family name.
  final String fontFamily;

  /// Additional font family names beyond [fontFamily] (from a DTCG
  /// `fontFamily` array), emitted as `TextStyle.fontFamilyFallback`.
  final List<String> fontFamilyFallback;

  /// The Flutter package bundling the font family, or `null` when the
  /// `fontPackage` extension is absent.
  final String? fontPackage;

  /// Font size in logical px.
  final double fontSize;

  /// Numeric font weight (100..900).
  final int fontWeight;

  /// Letter spacing in logical px.
  final double letterSpacing;

  /// The bound sibling color (protocol SPEC 2.4 `colorToken`).
  final ResolvedColor color;
}

/// The full set of theme colors, mirroring `UtopiaThemeColors`' fields.
class ResolvedThemeColors {
  /// Creates the resolved color set. [divider] is `null` when the document
  /// has no `color.divider` token (protocol SPEC 2.2: derive at paint time).
  const ResolvedThemeColors({
    required this.primary,
    required this.accent,
    required this.field,
    required this.canvas,
    required this.error,
    required this.disabled,
    required this.text,
    required this.surface,
    required this.border,
    required this.divider,
    required this.rowAlt,
    required this.hover,
    required this.chipBackground,
    required this.chipForeground,
    required this.hint,
    required this.onColoredContent,
    required this.onColoredSelected,
    required this.onColoredHover,
  });

  final ResolvedColor primary;
  final ResolvedColor accent;
  final ResolvedColor field;
  final ResolvedColor canvas;
  final ResolvedColor error;
  final ResolvedColor disabled;
  final ResolvedColor text;
  final ResolvedColor surface;
  final ResolvedColor border;
  final ResolvedColor? divider;
  final ResolvedColor rowAlt;
  final ResolvedColor hover;
  final ResolvedColor chipBackground;
  final ResolvedColor chipForeground;
  final ResolvedColor hint;
  final ResolvedColor onColoredContent;
  final ResolvedColor onColoredSelected;
  final ResolvedColor onColoredHover;
}

/// The full set of resolved text styles, mirroring `UtopiaThemeTextStyles`.
class ResolvedThemeTextStyles {
  /// Creates the resolved text style set.
  const ResolvedThemeTextStyles({
    required this.header,
    required this.label,
    required this.text,
    required this.title,
    required this.caption,
    required this.button,
  });

  final ResolvedTextStyle header;
  final ResolvedTextStyle label;
  final ResolvedTextStyle text;
  final ResolvedTextStyle title;
  final ResolvedTextStyle caption;
  final ResolvedTextStyle button;
}

/// The resolved `theme.*` semantic slots (protocol SPEC 2.2).
class ResolvedThemeSlots {
  /// Creates the resolved theme slots.
  const ResolvedThemeSlots({
    required this.borderRadius,
    required this.cardRadius,
    required this.fieldContentPaddingTop,
    required this.fieldContentPaddingRight,
    required this.fieldContentPaddingBottom,
    required this.fieldContentPaddingLeft,
    required this.fieldMinHeight,
    required this.pageTopPadding,
    required this.tileHeight,
  });

  final double borderRadius;
  final double cardRadius;
  final double fieldContentPaddingTop;
  final double fieldContentPaddingRight;
  final double fieldContentPaddingBottom;
  final double fieldContentPaddingLeft;
  final double fieldMinHeight;
  final double pageTopPadding;
  final double tileHeight;
}

/// The fully-resolved token document: every value a plain number/string/
/// [ResolvedColor], aliases followed, ready for `dart_emitter.dart` to print
/// as Dart source with no further DTCG knowledge.
class ThemeSpec {
  /// Creates a resolved theme spec. Use [ThemeSpec.fromDocument] to build one
  /// from a parsed [TokenDocument].
  const ThemeSpec({
    required this.x,
    required this.spacingXxs,
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.spacingXxl,
    required this.spacingXxxl,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusFull,
    required this.borderHairline,
    required this.borderThin,
    required this.borderThick,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.fontWeightRegular,
    required this.fontWeightMedium,
    required this.fontWeightSemiBold,
    required this.fontWeightBold,
    required this.durationXs,
    required this.durationSm,
    required this.durationMd,
    required this.durationLg,
    required this.durationXl,
    required this.breakpointTabletMin,
    required this.breakpointWebMin,
    required this.breakpointSidebarMin,
    required this.colors,
    required this.textStyles,
    required this.themeSlots,
  });

  /// Resolves a full [ThemeSpec] from a parsed [document]. Assumes the
  /// document already passed the token validator (the caller validates first
  /// and refuses to generate on errors); this resolver does not re-validate.
  factory ThemeSpec.fromDocument(TokenDocument document) {
    double dim(String path) => _resolveDimension(document, path);
    List<ResolvedShadowLayer> shadow(String path) => _resolveShadow(document, path);
    int fontWeight(String path) => _resolveFontWeight(document, path);
    int durationMs(String path) => _resolveDurationMs(document, path);
    ResolvedColor color(String path) => _resolveColor(document, path);

    final x = _resolveNumber(document, 'x');

    final spacingLg = dim('spacing.lg');
    final spacingXxxl = dim('spacing.xxxl');
    final radiusSm = dim('radius.sm');
    final radiusXl = dim('radius.xl');

    return ThemeSpec(
      x: x,
      spacingXxs: dim('spacing.xxs'),
      spacingXs: dim('spacing.xs'),
      spacingSm: dim('spacing.sm'),
      spacingMd: dim('spacing.md'),
      spacingLg: spacingLg,
      spacingXl: dim('spacing.xl'),
      spacingXxl: dim('spacing.xxl'),
      spacingXxxl: spacingXxxl,
      radiusXs: dim('radius.xs'),
      radiusSm: radiusSm,
      radiusMd: dim('radius.md'),
      radiusLg: dim('radius.lg'),
      radiusXl: radiusXl,
      radiusFull: dim('radius.full'),
      borderHairline: dim('border.hairline'),
      borderThin: dim('border.thin'),
      borderThick: dim('border.thick'),
      shadowSm: shadow('shadow.sm'),
      shadowMd: shadow('shadow.md'),
      shadowLg: shadow('shadow.lg'),
      fontWeightRegular: fontWeight('fontWeight.regular'),
      fontWeightMedium: fontWeight('fontWeight.medium'),
      fontWeightSemiBold: fontWeight('fontWeight.semiBold'),
      fontWeightBold: fontWeight('fontWeight.bold'),
      durationXs: durationMs('duration.xs'),
      durationSm: durationMs('duration.sm'),
      durationMd: durationMs('duration.md'),
      durationLg: durationMs('duration.lg'),
      durationXl: durationMs('duration.xl'),
      breakpointTabletMin: dim('breakpoint.tablet'),
      breakpointWebMin: dim('breakpoint.web'),
      breakpointSidebarMin: dim('breakpoint.sidebar'),
      colors: ResolvedThemeColors(
        primary: color('color.primary'),
        accent: color('color.accent'),
        field: color('color.field'),
        canvas: color('color.canvas'),
        error: color('color.error'),
        disabled: color('color.disabled'),
        text: color('color.text'),
        surface: color('color.surface'),
        border: color('color.border'),
        divider: document.tokensByPath.containsKey('color.divider') ? color('color.divider') : null,
        rowAlt: color('color.rowAlt'),
        hover: color('color.hover'),
        chipBackground: color('color.chipBackground'),
        chipForeground: color('color.chipForeground'),
        hint: color('color.hint'),
        onColoredContent: color('color.onColoredContent'),
        onColoredSelected: color('color.onColoredSelected'),
        onColoredHover: color('color.onColoredHover'),
      ),
      textStyles: ResolvedThemeTextStyles(
        header: _resolveTextStyle(document, 'header'),
        label: _resolveTextStyle(document, 'label'),
        text: _resolveTextStyle(document, 'text'),
        title: _resolveTextStyle(document, 'title'),
        caption: _resolveTextStyle(document, 'caption'),
        button: _resolveTextStyle(document, 'button'),
      ),
      themeSlots: ResolvedThemeSlots(
        borderRadius: dim('theme.borderRadius'),
        cardRadius: dim('theme.cardRadius'),
        fieldContentPaddingTop: dim('theme.fieldContentPadding.top'),
        fieldContentPaddingRight: dim('theme.fieldContentPadding.right'),
        fieldContentPaddingBottom: dim('theme.fieldContentPadding.bottom'),
        fieldContentPaddingLeft: dim('theme.fieldContentPadding.left'),
        fieldMinHeight: dim('theme.fieldMinHeight'),
        pageTopPadding: dim('theme.pageTopPadding'),
        tileHeight: dim('theme.tileHeight'),
      ),
    );
  }

  final double x;

  final double spacingXxs;
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;
  final double spacingXxl;
  final double spacingXxxl;

  final double radiusXs;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusFull;

  final double borderHairline;
  final double borderThin;
  final double borderThick;

  final List<ResolvedShadowLayer> shadowSm;
  final List<ResolvedShadowLayer> shadowMd;
  final List<ResolvedShadowLayer> shadowLg;

  final int fontWeightRegular;
  final int fontWeightMedium;
  final int fontWeightSemiBold;
  final int fontWeightBold;

  final int durationXs;
  final int durationSm;
  final int durationMd;
  final int durationLg;
  final int durationXl;

  final double breakpointTabletMin;
  final double breakpointWebMin;
  final double breakpointSidebarMin;

  final ResolvedThemeColors colors;
  final ResolvedThemeTextStyles textStyles;
  final ResolvedThemeSlots themeSlots;

  // -------------------------------------------------------------------
  // Resolution helpers.
  // -------------------------------------------------------------------

  static TokenNode _terminalNode(TokenDocument document, String path) {
    final node = document.tokensByPath[path];
    if (node == null) {
      throw StateError('generate_theme: no token at "$path" (the input should have been validated first)');
    }
    final aliasPath = aliasPathOf(node.value);
    if (aliasPath == null) {
      return node;
    }
    final resolution = resolveAlias(document, aliasPath);
    if (!resolution.isResolved) {
      throw StateError('generate_theme: $path: ${resolution.error}');
    }
    return resolution.terminal!;
  }

  static double _resolveNumber(TokenDocument document, String path) {
    final node = _terminalNode(document, path);
    final value = node.value;
    if (value is num) {
      return value.toDouble();
    }
    throw StateError('generate_theme: "$path" did not resolve to a number');
  }

  static double _resolveDimension(TokenDocument document, String path) {
    final node = _terminalNode(document, path);
    final value = node.value;
    if (value is Map && value['value'] is num) {
      return (value['value'] as num).toDouble();
    }
    throw StateError('generate_theme: "$path" did not resolve to a dimension');
  }

  static int _resolveDurationMs(TokenDocument document, String path) {
    final node = _terminalNode(document, path);
    final value = node.value;
    if (value is Map && value['value'] is num) {
      return (value['value'] as num).round();
    }
    throw StateError('generate_theme: "$path" did not resolve to a duration');
  }

  static int _resolveFontWeight(TokenDocument document, String path) {
    final node = _terminalNode(document, path);
    final value = node.value;
    if (value is num) {
      return value.round();
    }
    throw StateError('generate_theme: "$path" did not resolve to a fontWeight');
  }

  static ResolvedColor _resolveColor(TokenDocument document, String path) {
    final node = _terminalNode(document, path);
    final value = node.value;
    if (value is Map<String, dynamic>) {
      return ResolvedColor.fromDtcg(value);
    }
    throw StateError('generate_theme: "$path" did not resolve to a color');
  }

  static List<ResolvedShadowLayer> _resolveShadow(TokenDocument document, String path) {
    final node = _terminalNode(document, path);
    final value = node.value;
    if (value is! List) {
      throw StateError('generate_theme: "$path" did not resolve to a shadow');
    }
    return value.map((rawLayer) {
      final layer = _resolveShadowLayer(document, path, rawLayer);
      return layer;
    }).toList();
  }

  static ResolvedShadowLayer _resolveShadowLayer(TokenDocument document, String path, dynamic rawLayer) {
    Map<String, dynamic> layer;
    if (rawLayer is String) {
      final aliasPath = aliasPathOf(rawLayer);
      if (aliasPath == null) {
        throw StateError('generate_theme: "$path" shadow layer is a malformed alias');
      }
      final resolution = resolveAlias(document, aliasPath);
      if (!resolution.isResolved) {
        throw StateError('generate_theme: "$path": ${resolution.error}');
      }
      final terminalValue = resolution.terminal!.value;
      if (terminalValue is! List || terminalValue.isEmpty) {
        throw StateError('generate_theme: "$path" alias did not resolve to a shadow layer');
      }
      // A per-layer alias names one layer, but a shadow token's value is a
      // layer *array*: silently keeping only the first layer would drop the
      // rest of the referenced shadow, so refuse instead.
      if (terminalValue.length > 1) {
        throw StateError(
          'generate_theme: "$path": shadow-layer alias "{$aliasPath}" resolves to '
          '"${resolution.terminal!.path}", which has ${terminalValue.length} layers; a per-layer alias '
          'must target a single-layer shadow (alias the whole shadow token instead)',
        );
      }
      layer = (terminalValue.first as Map).cast<String, dynamic>();
    } else if (rawLayer is Map) {
      layer = rawLayer.cast<String, dynamic>();
    } else {
      throw StateError('generate_theme: "$path" shadow layer has an unexpected shape');
    }
    return ResolvedShadowLayer(
      color: ResolvedColor.fromDtcg((layer['color'] as Map).cast<String, dynamic>()),
      offsetX: _dimensionOf(layer['offsetX']),
      offsetY: _dimensionOf(layer['offsetY']),
      blur: _dimensionOf(layer['blur']),
      spread: _dimensionOf(layer['spread']),
    );
  }

  /// Reads a `fontFamily` array as `List<String>`, checking every element up
  /// front: `.cast<String>()` is lazy, so a non-string element would surface
  /// later as a raw TypeError on the first read instead of the named error the
  /// sibling (non-list, non-string) branch raises.
  static List<String> _stringList(List<dynamic> raw, String path) {
    final families = <String>[];
    for (final entry in raw) {
      if (entry is! String) {
        throw StateError('generate_theme: "$path" must be a string or array of strings');
      }
      families.add(entry);
    }
    return families;
  }

  static double _dimensionOf(dynamic value) {
    if (value is Map && value['value'] is num) {
      return (value['value'] as num).toDouble();
    }
    throw StateError('generate_theme: expected a dimension object, got "$value"');
  }

  /// Follows an inner alias inside a composite `$value` (a typography
  /// sub-property, protocol SPEC 2.4: each of fontFamily/fontSize/fontWeight/
  /// letterSpacing is `oneOf {value, alias}`) to its terminal token's
  /// `$value`. Non-alias values pass through unchanged.
  static dynamic _resolveInnerValue(TokenDocument document, String path, dynamic raw) {
    final aliasPath = aliasPathOf(raw);
    if (aliasPath == null) {
      return raw;
    }
    final resolution = resolveAlias(document, aliasPath);
    if (!resolution.isResolved) {
      throw StateError('generate_theme: "$path": ${resolution.error}');
    }
    return resolution.terminal!.value;
  }

  static ResolvedTextStyle _resolveTextStyle(TokenDocument document, String role) {
    final path = 'textStyle.$role';
    final node = _terminalNode(document, path);
    final value = node.value;
    if (value is! Map<String, dynamic>) {
      throw StateError('generate_theme: "$path" did not resolve to a typography value');
    }

    // Every typography sub-property may itself be an alias (protocol SPEC 2.4
    // / tokens.schema.json), exactly like a per-layer shadow alias, so each
    // one is resolved before it is read.
    final fontFamilyRaw = _resolveInnerValue(document, '$path.fontFamily', value['fontFamily']);
    final List<String> families;
    if (fontFamilyRaw is String) {
      families = [fontFamilyRaw];
    } else if (fontFamilyRaw is List) {
      families = _stringList(fontFamilyRaw, '$path.fontFamily');
    } else {
      throw StateError('generate_theme: "$path.fontFamily" must be a string or array of strings');
    }
    if (families.isEmpty) {
      throw StateError('generate_theme: "$path.fontFamily" must not be empty');
    }

    final fontSize = _dimensionOf(_resolveInnerValue(document, '$path.fontSize', value['fontSize']));
    final fontWeightRaw = _resolveInnerValue(document, '$path.fontWeight', value['fontWeight']);
    final fontWeight = fontWeightRaw is num
        ? fontWeightRaw.round()
        : throw StateError('generate_theme: "$path.fontWeight" did not resolve to a number');
    final letterSpacing = _dimensionOf(_resolveInnerValue(document, '$path.letterSpacing', value['letterSpacing']));

    // The typography token's own $extensions live on the node reached after
    // alias resolution: a typography token is never itself an alias to
    // another typography token with different extensions in practice, but we
    // read extensions from the same terminal node used for $value for
    // consistency.
    final extensions = node.utopiaExtensions;
    final fontPackage = extensions?['fontPackage'] as String?;
    final colorTokenPath = extensions?['colorToken'] as String?;
    if (colorTokenPath == null) {
      throw StateError('generate_theme: "$path" is missing its colorToken extension binding');
    }
    final color = _resolveColor(document, colorTokenPath);

    return ResolvedTextStyle(
      fontFamily: families.first,
      fontFamilyFallback: families.skip(1).toList(),
      fontPackage: fontPackage,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}
