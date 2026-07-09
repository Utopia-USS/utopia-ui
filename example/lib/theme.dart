import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// The stock [UtopiaThemeData] retuned to a polished admin look: a soft canvas,
/// white rounded/bordered table card, light-blue dividers and chips, and a real
/// weight hierarchy in the typography.
///
/// Everything visual flows through theme tokens - the widgets themselves carry
/// no hard-coded colours.
UtopiaThemeData buildExampleTheme() => _buildShowcaseTheme(
  colors: UtopiaThemeData.defaultTheme.colors.copyWith(
    primary: const Color(0xFF4A6FFF),
    accent: const Color(0xFF4466FF),
    field: const Color(0xFFF8F9FD),
    canvas: const Color(0xFFF4F6FD),
    text: const Color(0xFF141518),
    surface: const Color(0xFFFFFFFF),
    border: const Color(0xFFF1F4FF),
    rowAlt: const Color(0xFFF6F9FF),
    hover: const Color(0xFFEDF1FF),
    chipBackground: const Color(0xFFE2E9FF),
    chipForeground: const Color(0xFF4A6FFF),
    hint: const Color(0xFF9A9FB8),
  ),
  buttonLabel: Colors.white,
);

/// The theme modes selectable from the menu's theme picker. [light] and
/// [kawaii] are the light looks ([light] is the stock showcase theme,
/// [buildExampleTheme]); [dracula], [cyberpunk] and [forest] are the dark
/// variants. All are resolved to a [UtopiaThemeData] at runtime from global state.
enum ExampleThemeMode {
  light,
  dracula,
  cyberpunk,
  kawaii,
  forest;

  /// Short label shown in the picker.
  String get label => switch (this) {
    ExampleThemeMode.light => 'Light',
    ExampleThemeMode.dracula => 'Dracula',
    ExampleThemeMode.cyberpunk => 'Neon',
    ExampleThemeMode.kawaii => 'Kawaii',
    ExampleThemeMode.forest => 'Forest',
  };

  /// A 3-colour preview (primary, accent, surface) for the picker swatch. The
  /// hex values mirror the `primary`, `accent` and `surface` tokens of each
  /// mode's theme so the swatch always matches what the picker will apply.
  List<Color> get swatches => switch (this) {
    // blue primary, blue accent, white card
    ExampleThemeMode.light => const [Color(0xFF4A6FFF), Color(0xFF4466FF), Color(0xFFFFFFFF)],
    // Dracula purple primary + a deeper purple accent (subtle gradient), slate card
    ExampleThemeMode.dracula => const [Color(0xFFBD93F9), Color(0xFF9F7AEA), Color(0xFF282A36)],
    // neon yellow primary + amber accent (subtle gradient), near-black card
    ExampleThemeMode.cyberpunk => const [Color(0xFFFCEE0A), Color(0xFFFFC400), Color(0xFF11111F)],
    // kawaii rose primary + light-pink accent, white card
    ExampleThemeMode.kawaii => const [Color(0xFFDB3E86), Color(0xFFF77FBC), Color(0xFFFFFFFF)],
    // forest leaf-green primary + deeper green accent, warm bark-brown card
    ExampleThemeMode.forest => const [Color(0xFF4ECB71), Color(0xFF2FA85C), Color(0xFF241A11)],
  };
}

/// The official Dracula palette (https://draculatheme.com) mapped onto the same
/// base structure as [buildExampleTheme] - identical radii, tile height,
/// dividers, chip radius and type weights, only the colours change.
///
/// The canvas/surface/rowAlt/hover ramp is deliberately stepped (1E1F29 ->
/// 282A36 -> 2D2F3C -> 3A3D4D) so the page background, the table card, alternate
/// rows and the hover state stay visually distinct on a dark ground. All
/// foreground type is lifted to Dracula's foreground 0xFFF8F8F2 so light text
/// reads cleanly on every dark surface.
UtopiaThemeData buildDraculaTheme() => _buildShowcaseTheme(
  colors: UtopiaThemeData.defaultTheme.colors.copyWith(
    primary: const Color(0xFFBD93F9),
    accent: const Color(0xFF9F7AEA),
    field: const Color(0xFF21222C),
    canvas: const Color(0xFF1E1F29),
    text: const Color(0xFFF8F8F2),
    surface: const Color(0xFF282A36),
    border: const Color(0xFF44475A),
    rowAlt: const Color(0xFF2D2F3C),
    hover: const Color(0xFF3A3D4D),
    chipBackground: const Color(0xFF44475A),
    chipForeground: const Color(0xFF8BE9FD),
    hint: const Color(0xFF6272A4),
    error: const Color(0xFFFF5555),
    disabled: const Color(0xFF6272A4),
  ),
  // primary -> accent button gradient is a tight purple -> deeper-purple sweep
  // (not a purple/pink clash); near-white label on top.
  buttonLabel: const Color(0xFFF8F8F2),
);

/// A cyberpunk neon variant on the same base structure as [buildExampleTheme] -
/// identical radii, tile height, dividers, chip radius and type weights.
///
/// The palette is the classic cyberpunk yellow-on-black: an almost-black ground
/// (canvas 0x07070F, surface 0x11111F) with a neon-yellow primary 0xFFFCEE0A that
/// sweeps to amber 0xFFFFC400 for buttons (a tight, same-family gradient). Chips
/// keep an electric-cyan 0xFF00E5FF foreground as the secondary neon, so the
/// yellow primary and cyan chips read as a duotone. The surface/rowAlt/hover ramp
/// (11111F -> 16162A -> 1E1E3A) keeps rows separable without breaking the dark
/// mood, and foreground type is an icy 0xFFE8FBFF for crisp contrast.
UtopiaThemeData buildCyberpunkTheme() => _buildShowcaseTheme(
  colors: UtopiaThemeData.defaultTheme.colors.copyWith(
    primary: const Color(0xFFFCEE0A),
    accent: const Color(0xFFFFC400),
    field: const Color(0xFF0C0C18),
    canvas: const Color(0xFF07070F),
    text: const Color(0xFFE8FBFF),
    surface: const Color(0xFF11111F),
    border: const Color(0xFF242442),
    rowAlt: const Color(0xFF16162A),
    hover: const Color(0xFF1E1E3A),
    chipBackground: const Color(0xFF1A1A33),
    chipForeground: const Color(0xFF00E5FF),
    hint: const Color(0xFF7A7AB0),
    error: const Color(0xFFFF3B6B),
    disabled: const Color(0xFF3A3A55),
  ),
  // neon yellow -> amber button gradient; near-black label is the signature
  // high-contrast cyberpunk pairing.
  buttonLabel: const Color(0xFF0A0A14),
);

/// A soft "kawaii" variant on the same base structure as [buildExampleTheme] -
/// the only LIGHT theme besides the stock one.
///
/// Pastel pink on white: a faintly pink canvas (0xFFFFF0F7) over crisp white table
/// cards (0xFFFFFFFF), with a rose primary 0xFFDB3E86 that sweeps to a lighter pink
/// 0xFFF77FBC for buttons. Chips, hovers and alternate rows are all soft pink tints
/// so the cute mood carries without muddying the data. Body type is a deep plum
/// 0xFF5A2D47 (not black) so it reads softly yet high-contrast on the pink ground;
/// button labels stay white on the pink gradient, like the stock white-on-blue
/// buttons.
UtopiaThemeData buildKawaiiTheme() => _buildShowcaseTheme(
  colors: UtopiaThemeData.defaultTheme.colors.copyWith(
    primary: const Color(0xFFDB3E86),
    accent: const Color(0xFFF77FBC),
    field: const Color(0xFFFFF3F9),
    canvas: const Color(0xFFFFF0F7),
    text: const Color(0xFF5A2D47),
    surface: const Color(0xFFFFFFFF),
    border: const Color(0xFFFCDDEC),
    rowAlt: const Color(0xFFFFF6FB),
    hover: const Color(0xFFFCE7F2),
    chipBackground: const Color(0xFFFCDCEB),
    chipForeground: const Color(0xFFC13D7E),
    hint: const Color(0xFFC79BB4),
    error: const Color(0xFFF43F5E),
    disabled: const Color(0xFFE6BCD2),
  ),
  // tight rose -> light-pink button sweep; white label keeps the cute look and
  // matches the stock light theme.
  buttonLabel: Colors.white,
);

/// Resolves an [ExampleThemeMode] to its concrete [UtopiaThemeData]. Wired into the
/// menu's theme picker so switching modes swaps the whole palette at runtime.
UtopiaThemeData themeFor(ExampleThemeMode mode) => switch (mode) {
  ExampleThemeMode.light => buildExampleTheme(),
  ExampleThemeMode.dracula => buildDraculaTheme(),
  ExampleThemeMode.cyberpunk => buildCyberpunkTheme(),
  ExampleThemeMode.kawaii => buildKawaiiTheme(),
  ExampleThemeMode.forest => buildForestTheme(),
};

/// A deep-woods "forest" variant on the same base structure as
/// [buildExampleTheme] - identical radii, tile height, dividers, chip radius and
/// type weights, only the colours change.
///
/// An earthy palette: a warm bark/soil-brown ground (canvas 0x17110A -> surface
/// 0x241A11 -> rowAlt 0x2A1F14 -> hover 0x342718, a stepped ramp so rows stay
/// separable) lit by a vibrant leaf-green primary 0xFF4ECB71 that sweeps to a
/// deeper forest green 0xFF2FA85C for buttons - foliage against bark. Chips keep
/// a mossy green (mint 0xFF8FE3A0 on 0xFF2A3A1C). Foreground type is a warm
/// parchment 0xFFEDE8DB; the button label is a deep-forest near-black 0xFF06160C,
/// high-contrast on the bright green sweep (the same bright-fill / dark-label
/// pairing the Neon theme uses).
UtopiaThemeData buildForestTheme() => _buildShowcaseTheme(
  colors: UtopiaThemeData.defaultTheme.colors.copyWith(
    primary: const Color(0xFF4ECB71),
    accent: const Color(0xFF2FA85C),
    field: const Color(0xFF1E150C),
    canvas: const Color(0xFF17110A),
    text: const Color(0xFFEDE8DB),
    surface: const Color(0xFF241A11),
    border: const Color(0xFF43341F),
    rowAlt: const Color(0xFF2A1F14),
    hover: const Color(0xFF342718),
    chipBackground: const Color(0xFF2A3A1C),
    chipForeground: const Color(0xFF8FE3A0),
    hint: const Color(0xFFA1916F),
    error: const Color(0xFFE5736B),
    disabled: const Color(0xFF53472F),
  ),
  // bright leaf -> forest-green button gradient; deep near-black label for
  // high-contrast text across the sweep.
  buttonLabel: const Color(0xFF06160C),
);

/// Shared chrome for the showcase themes: every mode uses the same base
/// structure (radii, tile height, dividers, chip radius, top padding) and the
/// same Roboto weight hierarchy - bold headers/titles/buttons, semibold body,
/// bold chips. Only [colors] and the on-gradient [buttonLabel] vary; all other
/// foreground type follows `colors.text`.
UtopiaThemeData _buildShowcaseTheme({required UtopiaThemeColors colors, required Color buttonLabel}) {
  final foreground = colors.text;
  return UtopiaThemeData.defaultTheme.copyWith(
    colors: colors,
    borderRadius: BorderRadius.circular(12),
    cardRadius: BorderRadius.circular(16),
    cardBorderWidth: 1.5,
    tileHeight: 58,
    dividerThickness: 1.5,
    chipRadius: 8,
    pageTopPadding: 16,
    textStyles: UtopiaThemeTextStyles(
      header: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: -0.5, color: foreground),
      title: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.3, color: foreground),
      label: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: -0.2, color: foreground),
      text: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, letterSpacing: 0, color: foreground),
      caption: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0, color: foreground),
      button: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0, color: buttonLabel),
    ),
  );
}
