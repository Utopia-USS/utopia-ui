import 'package:flutter/widgets.dart';
import 'package:utopia_design_tools/src/dtcg/token_document.dart' show derivationTolerance;
import 'package:utopia_design_tools/src/dtcg/validator.dart' show protocolVersion;
import 'package:utopia_ui/utopia_ui.dart';

/// Raised when a [UtopiaThemeData] uses a Flutter feature that is out of
/// scope for the Utopia Design Protocol v0 token profile (protocol SPEC
/// 2.3/2.4). Carries an actionable, one-line [message].
class UnsupportedThemeFeature implements Exception {
  /// Creates the exception with the given actionable [message].
  const UnsupportedThemeFeature(this.message);

  /// Actionable, one-line description of the unsupported feature.
  final String message;

  @override
  String toString() => 'UnsupportedThemeFeature: $message';
}

/// Captures a [UtopiaThemeData] into the DTCG token-document shape defined by
/// the Utopia Design Protocol (protocol/SPEC.md section 2). The result is a
/// plain `Map<String, dynamic>` - JSON-encodable, no Flutter types left in it
/// - matching `protocol/schemas/tokens.schema.json` key order and shapes.
///
/// This is the only file in the package that imports Flutter beyond the
/// `bin/` entrypoints' pure-Dart orchestration; it is exercised exclusively
/// through `flutter test` (see `test/export_runner_test.dart`), never
/// directly from `bin/export_tokens.dart`.
class ThemeCapture {
  const ThemeCapture._();

  /// The protocol version stamped at the document root. Aliases the
  /// validator's [protocolVersion] so the stamp and the compatibility check
  /// can never disagree (the pair drifted once already).
  static const String profileVersion = protocolVersion;

  /// Captures [theme] into an ordered token-document map. Throws
  /// [UnsupportedThemeFeature] when the theme uses a shape the protocol does
  /// not cover in v0 (non-uniform border radii, `TextStyle.height`).
  static Map<String, dynamic> capture(UtopiaThemeData theme) {
    final tokens = theme.tokens;
    final x = tokens.x;

    final spacing = _captureSpacingGroup(tokens.spacing, x);
    final radius = _captureRadiusGroup(tokens.radius, x);
    final border = _captureBorderGroup(tokens.borders);
    final shadow = _captureShadowGroup(tokens.shadows);
    final fontWeight = _captureFontWeightGroup(tokens.fontWeights);
    final duration = _captureDurationGroup(tokens.durations);
    final breakpoint = _captureBreakpointGroup(tokens.breakpoints);
    final color = _captureColorGroup(theme.colors);
    final textStyle = _captureTextStyleGroup(theme.textStyles);
    final textStyleColors = _captureTextStyleColorsGroup(theme.textStyles);
    final themeSlots = _captureThemeGroup(theme, x, spacing: tokens.spacing, radius: tokens.radius);

    return {
      r'$extensions': {
        'io.utopiasoft.design': {'profileVersion': profileVersion},
      },
      'x': _numberToken(x),
      'spacing': spacing,
      'radius': radius,
      'border': border,
      'shadow': shadow,
      'fontWeight': fontWeight,
      'duration': duration,
      'breakpoint': breakpoint,
      'color': color,
      'textStyle': textStyle,
      'textStyle-colors': textStyleColors,
      'theme': themeSlots,
    };
  }

  static Map<String, dynamic> _numberToken(double value) => {r'$type': 'number', r'$value': _jsonNumber(value)};

  static Map<String, dynamic> _dimensionToken(double value, {String? derivation}) {
    final map = <String, dynamic>{
      r'$type': 'dimension',
      r'$value': {'value': _jsonNumber(value), 'unit': 'px'},
    };
    if (derivation != null) {
      map[r'$extensions'] = {
        'io.utopiasoft.design': {'derivation': derivation},
      };
    }
    return map;
  }

  static Map<String, dynamic> _aliasDimensionToken(String aliasPath) => {
    r'$type': 'dimension',
    r'$value': '{$aliasPath}',
  };

  static Map<String, dynamic> _captureSpacingGroup(UtopiaSpacingTokens spacing, double x) => {
    'xxs': _dimensionToken(spacing.xxs, derivation: _derivationOf(spacing.xxs, x)),
    'xs': _dimensionToken(spacing.xs, derivation: _derivationOf(spacing.xs, x)),
    'sm': _dimensionToken(spacing.sm, derivation: _derivationOf(spacing.sm, x)),
    'md': _dimensionToken(spacing.md, derivation: _derivationOf(spacing.md, x)),
    'lg': _dimensionToken(spacing.lg, derivation: _derivationOf(spacing.lg, x)),
    'xl': _dimensionToken(spacing.xl, derivation: _derivationOf(spacing.xl, x)),
    'xxl': _dimensionToken(spacing.xxl, derivation: _derivationOf(spacing.xxl, x)),
    'xxxl': _dimensionToken(spacing.xxxl, derivation: _derivationOf(spacing.xxxl, x)),
  };

  static Map<String, dynamic> _captureRadiusGroup(UtopiaRadiusTokens radius, double x) => {
    'xs': _dimensionToken(radius.xs, derivation: _derivationOf(radius.xs, x)),
    'sm': _dimensionToken(radius.sm, derivation: _derivationOf(radius.sm, x)),
    'md': _dimensionToken(radius.md, derivation: _derivationOf(radius.md, x)),
    'lg': _dimensionToken(radius.lg, derivation: _derivationOf(radius.lg, x)),
    'xl': _dimensionToken(radius.xl, derivation: _derivationOf(radius.xl, x)),
    // radius.full is deliberately not base-derived: never stamp derivation.
    'full': _dimensionToken(radius.full),
  };

  static Map<String, dynamic> _captureBorderGroup(UtopiaBorderTokens border) => {
    'hairline': _dimensionToken(border.hairline),
    'thin': _dimensionToken(border.thin),
    'thick': _dimensionToken(border.thick),
  };

  static Map<String, dynamic> _captureShadowGroup(UtopiaShadowTokens shadows) => {
    'sm': _shadowToken(shadows.sm),
    'md': _shadowToken(shadows.md),
    'lg': _shadowToken(shadows.lg),
  };

  static Map<String, dynamic> _shadowToken(List<BoxShadow> layers) => {
    r'$type': 'shadow',
    r'$value': layers.map(_shadowLayer).toList(),
  };

  static Map<String, dynamic> _shadowLayer(BoxShadow shadow) => {
    'color': _colorValue(shadow.color),
    'offsetX': {'value': _jsonNumber(shadow.offset.dx), 'unit': 'px'},
    'offsetY': {'value': _jsonNumber(shadow.offset.dy), 'unit': 'px'},
    'blur': {'value': _jsonNumber(shadow.blurRadius), 'unit': 'px'},
    'spread': {'value': _jsonNumber(shadow.spreadRadius), 'unit': 'px'},
  };

  static Map<String, dynamic> _captureFontWeightGroup(UtopiaFontWeightTokens weights) => {
    'regular': _fontWeightToken(weights.regular),
    'medium': _fontWeightToken(weights.medium),
    'semiBold': _fontWeightToken(weights.semiBold),
    'bold': _fontWeightToken(weights.bold),
  };

  static Map<String, dynamic> _fontWeightToken(FontWeight weight) => {
    r'$type': 'fontWeight',
    r'$value': weight.value,
  };

  static Map<String, dynamic> _captureDurationGroup(UtopiaDurationTokens durations) => {
    'xs': _durationToken(durations.xs),
    'sm': _durationToken(durations.sm),
    'md': _durationToken(durations.md),
    'lg': _durationToken(durations.lg),
    'xl': _durationToken(durations.xl),
  };

  static Map<String, dynamic> _durationToken(Duration duration) => {
    r'$type': 'duration',
    r'$value': {'value': duration.inMilliseconds, 'unit': 'ms'},
  };

  static Map<String, dynamic> _captureBreakpointGroup(UtopiaBreakpointTokens breakpoints) => {
    'tablet': _dimensionToken(breakpoints.tabletMin),
    'web': _dimensionToken(breakpoints.webMin),
    'sidebar': _dimensionToken(breakpoints.sidebarMin),
  };

  static Map<String, dynamic> _captureColorGroup(UtopiaThemeColors colors) {
    final map = <String, dynamic>{
      'primary': _colorToken(colors.primary),
      'accent': _colorToken(colors.accent),
      'field': _colorToken(colors.field),
      'canvas': _colorToken(colors.canvas),
      'error': _colorToken(colors.error),
      'disabled': _colorToken(colors.disabled),
      'text': _colorToken(colors.text),
      'surface': _colorToken(colors.surface),
      'border': _colorToken(colors.border),
    };
    // color.divider is OPTIONAL: an absent token means "derive at paint
    // time"; tools must not invent a concrete value (protocol SPEC 2.2).
    final divider = colors.divider;
    if (divider != null) {
      map['divider'] = _colorToken(divider);
    }
    map.addAll({
      'rowAlt': _colorToken(colors.rowAlt),
      'hover': _colorToken(colors.hover),
      'chipBackground': _colorToken(colors.chipBackground),
      'chipForeground': _colorToken(colors.chipForeground),
      'hint': _colorToken(colors.hint),
      'onColoredContent': _colorToken(colors.onColoredContent),
      'onColoredSelected': _colorToken(colors.onColoredSelected),
      'onColoredHover': _colorToken(colors.onColoredHover),
    });
    return map;
  }

  static Map<String, dynamic> _colorToken(Color color) => {r'$type': 'color', r'$value': _colorValue(color)};

  static Map<String, dynamic> _colorValue(Color color) {
    final argb = color.toARGB32();
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return {
      'colorSpace': 'srgb',
      'components': [_channel(r), _channel(g), _channel(b)],
      'alpha': _jsonNumber(_round6(a / 255)),
      'hex': '#${_hex2(r)}${_hex2(g)}${_hex2(b)}',
    };
  }

  static dynamic _channel(int value8Bit) => _jsonNumber(_round6(value8Bit / 255));

  static String _hex2(int value8Bit) => value8Bit.toRadixString(16).padLeft(2, '0');

  static Map<String, dynamic> _captureTextStyleGroup(UtopiaThemeTextStyles textStyles) => {
    'header': _typographyToken('header', textStyles.header),
    'label': _typographyToken('label', textStyles.label),
    'text': _typographyToken('text', textStyles.text),
    'title': _typographyToken('title', textStyles.title),
    'caption': _typographyToken('caption', textStyles.caption),
    'button': _typographyToken('button', textStyles.button),
  };

  static Map<String, dynamic> _typographyToken(String role, TextStyle style) {
    if (style.height != null) {
      throw UnsupportedThemeFeature(
        'textStyle.$role: TextStyle.height (lineHeight) is set but lineHeight is not part of '
        'the Utopia Design Protocol v0 typography profile; unset it or extend the protocol '
        'before exporting.',
      );
    }
    final fontFamilyRaw = style.fontFamily;
    if (fontFamilyRaw == null) {
      throw UnsupportedThemeFeature('textStyle.$role: fontFamily must be set to export a typography token.');
    }
    String family = fontFamilyRaw;
    String? fontPackage;
    final packageMatch = RegExp(r'^packages/([^/]+)/(.+)$').firstMatch(fontFamilyRaw);
    if (packageMatch != null) {
      fontPackage = packageMatch.group(1);
      family = packageMatch.group(2)!;
    }

    final fontSize = style.fontSize;
    final fontWeight = style.fontWeight;
    final letterSpacing = style.letterSpacing;
    if (fontSize == null) {
      throw UnsupportedThemeFeature('textStyle.$role: fontSize must be set to export a typography token.');
    }
    if (fontWeight == null) {
      throw UnsupportedThemeFeature('textStyle.$role: fontWeight must be set to export a typography token.');
    }
    if (letterSpacing == null) {
      throw UnsupportedThemeFeature('textStyle.$role: letterSpacing must be set to export a typography token.');
    }

    final extensions = <String, dynamic>{'colorToken': 'textStyle-colors.$role'};
    if (fontPackage != null) {
      extensions['fontPackage'] = fontPackage;
    }

    return {
      r'$type': 'typography',
      r'$value': {
        'fontFamily': family,
        'fontSize': {'value': _jsonNumber(fontSize), 'unit': 'px'},
        'fontWeight': fontWeight.value,
        'letterSpacing': {'value': _jsonNumber(letterSpacing), 'unit': 'px'},
      },
      r'$extensions': {'io.utopiasoft.design': extensions},
    };
  }

  static Map<String, dynamic> _captureTextStyleColorsGroup(UtopiaThemeTextStyles textStyles) => {
    'header': _textStyleColorToken('header', textStyles.header),
    'label': _textStyleColorToken('label', textStyles.label),
    'text': _textStyleColorToken('text', textStyles.text),
    'title': _textStyleColorToken('title', textStyles.title),
    'caption': _textStyleColorToken('caption', textStyles.caption),
    'button': _textStyleColorToken('button', textStyles.button),
  };

  static Map<String, dynamic> _textStyleColorToken(String role, TextStyle style) {
    final color = style.color;
    if (color == null) {
      throw UnsupportedThemeFeature('textStyle.$role: color must be set to export the sibling textStyle-colors token.');
    }
    return _colorToken(color);
  }

  static Map<String, dynamic> _captureThemeGroup(
    UtopiaThemeData theme, double x, {
    required UtopiaSpacingTokens spacing,
    required UtopiaRadiusTokens radius,
  }) {
    final borderRadius = _uniformRadius(theme.borderRadius, slotName: 'theme.borderRadius');
    final cardRadius = _uniformRadius(theme.cardRadius, slotName: 'theme.cardRadius');

    // Derivation stamps are limited to the slots UtopiaThemeData.fromTokens actually derives
    // from the base unit (SPEC 2.5): fieldContentPadding.top/bottom and fieldMinHeight.
    // Other slots either alias a token or are plain design decisions (tileHeight) that the
    // Dart theme does NOT rescale with x - stamping them would break surface parity.
    final borderRadiusToken =
        borderRadius == radius.md ? _aliasDimensionToken('radius.md') : _dimensionToken(borderRadius);
    final cardRadiusToken = cardRadius == radius.xl ? _aliasDimensionToken('radius.xl') : _dimensionToken(cardRadius);

    final padding = theme.fieldContentPadding;
    final leftToken = padding.left == spacing.lg ? _aliasDimensionToken('spacing.lg') : _dimensionToken(padding.left);
    final rightToken =
        padding.right == spacing.lg ? _aliasDimensionToken('spacing.lg') : _dimensionToken(padding.right);
    final topToken = _dimensionToken(padding.top, derivation: _derivationOf(padding.top, x));
    final bottomToken = _dimensionToken(padding.bottom, derivation: _derivationOf(padding.bottom, x));

    final fieldMinHeightToken = _dimensionToken(theme.fieldMinHeight, derivation: _derivationOf(theme.fieldMinHeight, x));
    final pageTopPaddingToken = theme.pageTopPadding == spacing.xxxl
        ? _aliasDimensionToken('spacing.xxxl')
        : _dimensionToken(theme.pageTopPadding);
    final tileHeightToken = _dimensionToken(theme.tileHeight);

    return {
      'borderRadius': borderRadiusToken,
      'cardRadius': cardRadiusToken,
      'fieldContentPadding': {'top': topToken, 'right': rightToken, 'bottom': bottomToken, 'left': leftToken},
      'fieldMinHeight': fieldMinHeightToken,
      'pageTopPadding': pageTopPaddingToken,
      'tileHeight': tileHeightToken,
    };
  }

  /// Reads the uniform corner radius of a `BorderRadius` theme slot. Fails
  /// export when the four corners are not uniform: non-uniform border radii
  /// are out of scope for the protocol v0 (SPEC 2.3).
  static double _uniformRadius(BorderRadius borderRadius, {required String slotName}) {
    final tl = borderRadius.topLeft;
    final tr = borderRadius.topRight;
    final bl = borderRadius.bottomLeft;
    final br = borderRadius.bottomRight;
    if (tl.x != tl.y || tl != tr || tl != bl || tl != br) {
      throw UnsupportedThemeFeature(
        '$slotName: non-uniform BorderRadius is not supported by the Utopia Design Protocol v0 '
        '(corners must all match a single circular radius).',
      );
    }
    return tl.x;
  }

  /// Computes the `x*<multiple>` derivation stamp for [value] against base
  /// [x], or `null` when a 3-decimal multiple cannot reproduce [value] within
  /// [derivationTolerance].
  ///
  /// The check is deliberately in value-space (`|value - x*rounded|`), the
  /// same space the validator's derivation gate uses: rounding the multiple
  /// itself always lands within 0.0005 of the exact multiple, so a
  /// multiple-space comparison would accept every slot and stamp derivations
  /// the validator then rejects (the value-space error scales with [x], e.g.
  /// x=6 with value 47 stamps `x*7.833` but re-derives to 46.998).
  static String? _derivationOf(double value, double x) {
    if (x == 0) {
      return null;
    }
    final multiple = value / x;
    final rounded = _roundTo(multiple, 3);
    if ((value - x * rounded).abs() > derivationTolerance) {
      return null;
    }
    return 'x*${_formatMultiple(rounded)}';
  }

  static double _roundTo(double value, int decimals) {
    final factor = _pow10(decimals);
    return (value * factor).round() / factor;
  }

  static double _round6(double value) => _roundTo(value, 6);

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  /// Formats a multiple without trailing zeros (`0.5`, `1`, `1.5`, `3`, `11`).
  static String _formatMultiple(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    var text = value.toStringAsFixed(3);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  /// Converts a [double] to the JSON-friendly numeric representation: an
  /// [int] when the value is whole (`6` not `6.0`), otherwise the [double]
  /// unchanged.
  static dynamic _jsonNumber(double value) {
    if (value == value.roundToDouble() && value.isFinite) {
      return value.toInt();
    }
    return value;
  }
}
