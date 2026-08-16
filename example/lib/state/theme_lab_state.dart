import 'package:flutter/painting.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../theme.dart';

class ThemeLabState {
  final MutableValue<ExampleThemeMode> preset;
  final MutableValue<double> baseUnit;
  final MutableValue<double> roundness;
  final MutableValue<Color?> primaryOverride;

  const ThemeLabState({
    required this.preset,
    required this.baseUnit,
    required this.roundness,
    required this.primaryOverride,
  });

  bool get isModified => baseUnit.value != 4 || roundness.value != 1 || primaryOverride.value != null;

  void selectPreset(ExampleThemeMode mode) {
    preset.value = mode;
    primaryOverride.value = null;
  }

  void reset() {
    baseUnit.value = 4;
    roundness.value = 1;
    primaryOverride.value = null;
  }

  static Color deriveAccent(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    return hsl
        .withLightness((hsl.lightness * 0.82).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 1.05).clamp(0.0, 1.0))
        .toColor();
  }

  UtopiaThemeData buildTheme() {
    final x = baseUnit.value;
    final tokens = UtopiaTokens.fromBase(x).copyWith(borders: const UtopiaBorderTokens(hairline: 1.5));
    final base = themeFor(preset.value, tokens: tokens);
    final radiusFactor = roundness.value;

    final primary = primaryOverride.value;
    final colors = primary == null
        ? base.colors
        : base.colors.copyWith(primary: primary, accent: deriveAccent(primary), chipForeground: primary);

    return base.copyWith(
      colors: colors,
      borderRadius: BorderRadius.all(Radius.circular(tokens.radius.lg * radiusFactor)),
      cardRadius: BorderRadius.all(Radius.circular(tokens.radius.xl * radiusFactor)),
    );
  }

  String dartSnippet() {
    final x = baseUnit.value;
    final primary = primaryOverride.value;
    return [
      'final theme = UtopiaThemeData.fromTokens(',
      if (x == 4) '  tokens: const UtopiaTokens(),' else '  tokens: UtopiaTokens.fromBase($x),',
      if (primary != null) ...[
        '  colors: UtopiaThemeColors.defaultTheme.copyWith(',
        '    primary: const Color(0x${_hex(primary)}),',
        '    accent: const Color(0x${_hex(deriveAccent(primary))}),',
        '  ),',
      ] else
        '  colors: UtopiaThemeColors.defaultTheme,',
      '  textStyles: UtopiaThemeTextStyles.defaultTheme,',
      ');',
    ].join('\n');
  }

  static String _hex(Color color) => color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
}

ThemeLabState useThemeLabState() {
  final preset = useState(_initialMode());
  final baseUnit = useState<double>(4);
  final roundness = useState<double>(1);
  final primaryOverride = useState<Color?>(null);
  return ThemeLabState(preset: preset, baseUnit: baseUnit, roundness: roundness, primaryOverride: primaryOverride);
}

ExampleThemeMode _initialMode() {
  final requested = Uri.base.queryParameters['theme'];
  return ExampleThemeMode.values.where((it) => it.name == requested).firstOrNull ?? ExampleThemeMode.light;
}
