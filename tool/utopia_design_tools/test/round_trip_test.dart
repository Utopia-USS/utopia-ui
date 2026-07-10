// The A6 acceptance gate: `buildUtopiaTheme()` from the committed golden
// (generated from the canonical tokens/utopia.tokens.json - see
// theme_gen_test.dart for the exact command) must equal
// `UtopiaThemeData.defaultTheme` up to 8-bit color quantization (protocol
// SPEC.md section 5). A structured comparator is required rather than plain
// `==`: `defaultTheme` contains float-constructed colors
// (`Colors.white.withValues(alpha: 0.85)`) whose exact component doubles
// cannot equal the 8-bit-quantized `Color(0xD9FFFFFF)` the generator emits,
// since DTCG hex/8-bit is the protocol's color resolution. Every stored
// UtopiaThemeData field (9 total; derived getters follow automatically) is
// asserted; on mismatch the failure prints the field name and both values.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

import 'goldens/default_theme.g.dart' as golden;

void main() {
  test('buildUtopiaTheme() equals UtopiaThemeData.defaultTheme up to 8-bit color quantization', () {
    final generated = golden.buildUtopiaTheme();
    final expected = UtopiaThemeData.defaultTheme;

    _expectThemeEquals(generated, expected);
  });
}

void _expectThemeEquals(UtopiaThemeData actual, UtopiaThemeData expected) {
  _expectTokensEqual(actual.tokens, expected.tokens);
  _expectColorsEqual(actual.colors, expected.colors);
  _expectTextStylesEqual(actual.textStyles, expected.textStyles);
  _expectBorderRadiusEqual('borderRadius', actual.borderRadius, expected.borderRadius);
  _expectEdgeInsetsEqual('fieldContentPadding', actual.fieldContentPadding, expected.fieldContentPadding);
  _expectDoubleEqual('fieldMinHeight', actual.fieldMinHeight, expected.fieldMinHeight);
  _expectDoubleEqual('pageTopPadding', actual.pageTopPadding, expected.pageTopPadding);
  _expectBorderRadiusEqual('cardRadius', actual.cardRadius, expected.cardRadius);
  _expectDoubleEqual('tileHeight', actual.tileHeight, expected.tileHeight);
}

// ---------------------------------------------------------------------
// tokens
// ---------------------------------------------------------------------

void _expectTokensEqual(UtopiaTokens actual, UtopiaTokens expected) {
  _expectDoubleEqual('tokens.x', actual.x, expected.x);

  _expectDoubleEqual('tokens.spacing.xxs', actual.spacing.xxs, expected.spacing.xxs);
  _expectDoubleEqual('tokens.spacing.xs', actual.spacing.xs, expected.spacing.xs);
  _expectDoubleEqual('tokens.spacing.sm', actual.spacing.sm, expected.spacing.sm);
  _expectDoubleEqual('tokens.spacing.md', actual.spacing.md, expected.spacing.md);
  _expectDoubleEqual('tokens.spacing.lg', actual.spacing.lg, expected.spacing.lg);
  _expectDoubleEqual('tokens.spacing.xl', actual.spacing.xl, expected.spacing.xl);
  _expectDoubleEqual('tokens.spacing.xxl', actual.spacing.xxl, expected.spacing.xxl);
  _expectDoubleEqual('tokens.spacing.xxxl', actual.spacing.xxxl, expected.spacing.xxxl);

  _expectDoubleEqual('tokens.radius.xs', actual.radius.xs, expected.radius.xs);
  _expectDoubleEqual('tokens.radius.sm', actual.radius.sm, expected.radius.sm);
  _expectDoubleEqual('tokens.radius.md', actual.radius.md, expected.radius.md);
  _expectDoubleEqual('tokens.radius.lg', actual.radius.lg, expected.radius.lg);
  _expectDoubleEqual('tokens.radius.xl', actual.radius.xl, expected.radius.xl);
  _expectDoubleEqual('tokens.radius.full', actual.radius.full, expected.radius.full);

  _expectDoubleEqual('tokens.borders.hairline', actual.borders.hairline, expected.borders.hairline);
  _expectDoubleEqual('tokens.borders.thin', actual.borders.thin, expected.borders.thin);
  _expectDoubleEqual('tokens.borders.thick', actual.borders.thick, expected.borders.thick);

  _expectShadowListEqual('tokens.shadows.sm', actual.shadows.sm, expected.shadows.sm);
  _expectShadowListEqual('tokens.shadows.md', actual.shadows.md, expected.shadows.md);
  _expectShadowListEqual('tokens.shadows.lg', actual.shadows.lg, expected.shadows.lg);

  _expectFontWeightEqual('tokens.fontWeights.regular', actual.fontWeights.regular, expected.fontWeights.regular);
  _expectFontWeightEqual('tokens.fontWeights.medium', actual.fontWeights.medium, expected.fontWeights.medium);
  _expectFontWeightEqual('tokens.fontWeights.semiBold', actual.fontWeights.semiBold, expected.fontWeights.semiBold);
  _expectFontWeightEqual('tokens.fontWeights.bold', actual.fontWeights.bold, expected.fontWeights.bold);

  _expectEqual('tokens.durations.xs', actual.durations.xs, expected.durations.xs);
  _expectEqual('tokens.durations.sm', actual.durations.sm, expected.durations.sm);
  _expectEqual('tokens.durations.md', actual.durations.md, expected.durations.md);
  _expectEqual('tokens.durations.lg', actual.durations.lg, expected.durations.lg);
  _expectEqual('tokens.durations.xl', actual.durations.xl, expected.durations.xl);

  _expectDoubleEqual('tokens.breakpoints.tabletMin', actual.breakpoints.tabletMin, expected.breakpoints.tabletMin);
  _expectDoubleEqual('tokens.breakpoints.webMin', actual.breakpoints.webMin, expected.breakpoints.webMin);
  _expectDoubleEqual(
    'tokens.breakpoints.sidebarMin',
    actual.breakpoints.sidebarMin,
    expected.breakpoints.sidebarMin,
  );
}

void _expectShadowListEqual(String field, List<BoxShadow> actual, List<BoxShadow> expected) {
  _expectEqual('$field.length', actual.length, expected.length);
  for (var i = 0; i < actual.length && i < expected.length; i++) {
    _expectColorEqual('$field[$i].color', actual[i].color, expected[i].color);
    _expectDoubleEqual('$field[$i].blurRadius', actual[i].blurRadius, expected[i].blurRadius);
    _expectDoubleEqual('$field[$i].spreadRadius', actual[i].spreadRadius, expected[i].spreadRadius);
    _expectDoubleEqual('$field[$i].offset.dx', actual[i].offset.dx, expected[i].offset.dx);
    _expectDoubleEqual('$field[$i].offset.dy', actual[i].offset.dy, expected[i].offset.dy);
  }
}

// ---------------------------------------------------------------------
// colors
// ---------------------------------------------------------------------

void _expectColorsEqual(UtopiaThemeColors actual, UtopiaThemeColors expected) {
  _expectColorEqual('colors.primary', actual.primary, expected.primary);
  _expectColorEqual('colors.accent', actual.accent, expected.accent);
  _expectColorEqual('colors.field', actual.field, expected.field);
  _expectColorEqual('colors.canvas', actual.canvas, expected.canvas);
  _expectColorEqual('colors.error', actual.error, expected.error);
  _expectColorEqual('colors.disabled', actual.disabled, expected.disabled);
  _expectColorEqual('colors.text', actual.text, expected.text);
  _expectColorEqual('colors.surface', actual.surface, expected.surface);
  _expectColorEqual('colors.border', actual.border, expected.border);
  _expectNullableColorEqual('colors.divider', actual.divider, expected.divider);
  _expectColorEqual('colors.rowAlt', actual.rowAlt, expected.rowAlt);
  _expectColorEqual('colors.hover', actual.hover, expected.hover);
  _expectColorEqual('colors.chipBackground', actual.chipBackground, expected.chipBackground);
  _expectColorEqual('colors.chipForeground', actual.chipForeground, expected.chipForeground);
  _expectColorEqual('colors.hint', actual.hint, expected.hint);
  _expectColorEqual('colors.onColoredContent', actual.onColoredContent, expected.onColoredContent);
  _expectColorEqual('colors.onColoredSelected', actual.onColoredSelected, expected.onColoredSelected);
  _expectColorEqual('colors.onColoredHover', actual.onColoredHover, expected.onColoredHover);
}

// ---------------------------------------------------------------------
// text styles
// ---------------------------------------------------------------------

void _expectTextStylesEqual(UtopiaThemeTextStyles actual, UtopiaThemeTextStyles expected) {
  _expectTextStyleEqual('textStyles.header', actual.header, expected.header);
  _expectTextStyleEqual('textStyles.label', actual.label, expected.label);
  _expectTextStyleEqual('textStyles.text', actual.text, expected.text);
  _expectTextStyleEqual('textStyles.title', actual.title, expected.title);
  _expectTextStyleEqual('textStyles.caption', actual.caption, expected.caption);
  _expectTextStyleEqual('textStyles.button', actual.button, expected.button);
}

void _expectTextStyleEqual(String field, TextStyle actual, TextStyle expected) {
  _expectEqual('$field.fontFamily', actual.fontFamily, expected.fontFamily);
  _expectEqual('$field.package (via fontFamily)', _packageOf(actual), _packageOf(expected));
  _expectEqual('$field.fontFamilyFallback', actual.fontFamilyFallback, expected.fontFamilyFallback);
  _expectNullableDoubleEqual('$field.fontSize', actual.fontSize, expected.fontSize);
  _expectEqual('$field.fontWeight', actual.fontWeight, expected.fontWeight);
  _expectNullableDoubleEqual('$field.letterSpacing', actual.letterSpacing, expected.letterSpacing);
  _expectNullableColorEqual('$field.color', actual.color, expected.color);
  if (actual.height != null || expected.height != null) {
    fail('$field.height must be null on both sides (lineHeight is out of protocol scope); '
        'got actual=${actual.height}, expected=${expected.height}');
  }
}

/// `TextStyle` does not expose its `package:` argument directly - it is
/// folded into `fontFamily` as `packages/<package>/<family>` by the
/// framework. Extracting it this way lets the comparator verify the
/// generated style's package prefix matches `defaultTheme`'s.
String? _packageOf(TextStyle style) {
  final family = style.fontFamily;
  if (family == null) return null;
  final match = RegExp('^packages/([^/]+)/').firstMatch(family);
  return match?.group(1);
}

// ---------------------------------------------------------------------
// geometry
// ---------------------------------------------------------------------

void _expectBorderRadiusEqual(String field, BorderRadius actual, BorderRadius expected) {
  _expectDoubleEqual('$field.topLeft.x', actual.topLeft.x, expected.topLeft.x);
  _expectDoubleEqual('$field.topLeft.y', actual.topLeft.y, expected.topLeft.y);
  _expectDoubleEqual('$field.topRight.x', actual.topRight.x, expected.topRight.x);
  _expectDoubleEqual('$field.topRight.y', actual.topRight.y, expected.topRight.y);
  _expectDoubleEqual('$field.bottomLeft.x', actual.bottomLeft.x, expected.bottomLeft.x);
  _expectDoubleEqual('$field.bottomLeft.y', actual.bottomLeft.y, expected.bottomLeft.y);
  _expectDoubleEqual('$field.bottomRight.x', actual.bottomRight.x, expected.bottomRight.x);
  _expectDoubleEqual('$field.bottomRight.y', actual.bottomRight.y, expected.bottomRight.y);
}

void _expectEdgeInsetsEqual(String field, EdgeInsets actual, EdgeInsets expected) {
  _expectDoubleEqual('$field.top', actual.top, expected.top);
  _expectDoubleEqual('$field.right', actual.right, expected.right);
  _expectDoubleEqual('$field.bottom', actual.bottom, expected.bottom);
  _expectDoubleEqual('$field.left', actual.left, expected.left);
}

// ---------------------------------------------------------------------
// primitive comparators - each prints the field name and both values on
// mismatch, per the A6 spec's failure-reporting requirement.
// ---------------------------------------------------------------------

void _expectColorEqual(String field, Color actual, Color expected) {
  _expectEqual(field, actual.toARGB32(), expected.toARGB32());
}

void _expectNullableColorEqual(String field, Color? actual, Color? expected) {
  if (actual == null || expected == null) {
    _expectEqual(field, actual, expected);
    return;
  }
  _expectColorEqual(field, actual, expected);
}

void _expectFontWeightEqual(String field, FontWeight actual, FontWeight expected) {
  _expectEqual(field, actual.value, expected.value);
}

void _expectDoubleEqual(String field, double actual, double expected) {
  _expectEqual(field, actual, expected);
}

void _expectNullableDoubleEqual(String field, double? actual, double? expected) {
  _expectEqual(field, actual, expected);
}

void _expectEqual(String field, Object? actual, Object? expected) {
  expect(actual, equals(expected), reason: 'field "$field" mismatch: actual=$actual, expected=$expected');
}
