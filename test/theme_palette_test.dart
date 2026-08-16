import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// Pins the palette-completeness invariant from CHARTER "Theming": every colour
/// a theme paints resolves from `UtopiaThemeColors`, so swapping `colors` alone
/// yields a complete, coherent theme.
///
/// The two escapes this guards against are the ones that were actually there:
/// the type family carrying its own literal colours (so a dark theme had to
/// rebuild the whole type block just to flip the button label), and the shadow
/// presets carrying a hardcoded blue-black tint.
///
/// It also pins the contrast claims the dark palette's doc comment makes, since
/// those are the reason its brand pair and `onPrimary` look inverted next to the
/// light one.
void main() {
  group('type family tracks the palette', () {
    test('the light theme is unchanged by the indirection', () {
      // fromColors(defaultTheme colours) must reproduce the literal family
      // byte for byte, or every shipped artifact and golden shifts under us.
      expect(UtopiaThemeData.defaultTheme.textStyles, UtopiaThemeTextStyles.defaultTheme);
    });

    test('the three foreground tiers come from their tokens', () {
      final colors = UtopiaThemeColors.darkTheme;
      final styles = UtopiaThemeTextStyles.fromColors(colors);

      expect(styles.header.color, colors.text, reason: 'heading tone');
      expect(styles.title.color, colors.text, reason: 'heading tone');
      expect(styles.text.color, colors.textBody, reason: 'body tone');
      expect(styles.label.color, colors.textBody, reason: 'body tone');
      expect(styles.caption.color, colors.textBody, reason: 'body tone');
      expect(styles.button.color, colors.onPrimary, reason: 'painted on the primary sweep');
    });

    test('re-tinting keeps the structure of a custom ramp', () {
      const base = UtopiaThemeTextStyles(
        header: TextStyle(fontFamily: 'Custom', fontSize: 40, fontWeight: FontWeight.w900),
        title: TextStyle(fontFamily: 'Custom', fontSize: 30),
        text: TextStyle(fontFamily: 'Custom', fontSize: 20),
        label: TextStyle(fontFamily: 'Custom', fontSize: 15),
        caption: TextStyle(fontFamily: 'Custom', fontSize: 10),
        button: TextStyle(fontFamily: 'Custom', fontSize: 18),
      );
      final styles = UtopiaThemeTextStyles.fromColors(UtopiaThemeColors.darkTheme, base: base);

      expect(styles.header.fontFamily, 'Custom');
      expect(styles.header.fontSize, 40);
      expect(styles.header.fontWeight, FontWeight.w900);
      expect(styles.header.color, UtopiaThemeColors.darkTheme.text);
    });

    test('a palette swap alone re-tints the whole theme', () {
      // The regression this exists for: building a dark theme used to require
      // passing a rebuilt UtopiaThemeTextStyles alongside the colours.
      final dark = UtopiaThemeData.fromTokens(colors: UtopiaThemeColors.darkTheme);

      expect(dark.textStyles.header.color, UtopiaThemeColors.darkTheme.text);
      expect(dark.textStyles.button.color, UtopiaThemeColors.darkTheme.onPrimary);
      expect(dark.cardShadow.first.color.r, 0);
      expect(dark.textStyles.header.fontSize, UtopiaThemeData.defaultTheme.textStyles.header.fontSize);
    });
  });

  group('elevation tracks the palette', () {
    test('the default tint reproduces the raw presets', () {
      final theme = UtopiaThemeData.defaultTheme;

      expect(theme.cardShadow, theme.tokens.shadows.sm);
      expect(theme.menuShadow, theme.tokens.shadows.lg);
    });

    test("the tint replaces the hue and keeps each layer's weight", () {
      final theme = UtopiaThemeData.fromTokens(
        colors: UtopiaThemeColors.defaultTheme.copyWith(shadow: const Color(0xFF00FF00)),
      );

      final preset = theme.tokens.shadows.lg;
      expect(theme.menuShadow.length, preset.length);
      for (var i = 0; i < preset.length; i++) {
        final tinted = theme.menuShadow[i];
        expect(tinted.color.r, 0);
        expect(tinted.color.g, 1);
        expect(tinted.color.b, 0);
        // Geometry and per-layer weight survive the re-tint.
        expect(tinted.color.a, closeTo(preset[i].color.a, 1 / 255));
        expect(tinted.offset, preset[i].offset);
        expect(tinted.blurRadius, preset[i].blurRadius);
        expect(tinted.spreadRadius, preset[i].spreadRadius);
      }
    });

    test('re-tinting an already-tinted stack is a no-op', () {
      // The protocol exports the tinted stack and reads it back into a theme
      // that tints again; anything but an idempotent operation would compound
      // on every export/generate cycle.
      final theme = UtopiaThemeData.fromTokens(
        colors: UtopiaThemeColors.defaultTheme.copyWith(shadow: const Color(0xFF00FF00)),
      );
      final once = theme.cardShadow;
      final twice = theme.copyWith(tokens: theme.tokens.copyWith(shadows: UtopiaShadowTokens(sm: once))).cardShadow;

      expect(twice, once);
    });

    test('the tint alpha is ignored, so a stack keeps its shape', () {
      final theme = UtopiaThemeData.fromTokens(
        colors: UtopiaThemeColors.defaultTheme.copyWith(shadow: const Color(0x80101828)),
      );

      final preset = theme.tokens.shadows.sm;
      for (var i = 0; i < preset.length; i++) {
        expect(theme.cardShadow[i].color.a, closeTo(preset[i].color.a, 1 / 255));
      }
    });
  });

  group('dark palette contrast', () {
    final dark = UtopiaThemeColors.darkTheme;

    test('the button label clears 4.5:1 at both ends of the primary sweep', () {
      // A gradient gives the label no single background, so both ends must pass.
      expect(_contrast(dark.onPrimary, dark.primary), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.onPrimary, dark.accent), greaterThanOrEqualTo(4.5));
    });

    test('every foreground tier clears 4.5:1 on the card surface', () {
      expect(_contrast(dark.text, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.textBody, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.hint, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.error, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.chipForeground, dark.chipBackground), greaterThanOrEqualTo(4.5));
    });

    test('the tiers stay ordered and the surface ramp stays stepped', () {
      // Heading darker-to-lighter ordering is what makes the hierarchy read.
      expect(_luminance(dark.text), greaterThan(_luminance(dark.textBody)));
      expect(_luminance(dark.textBody), greaterThan(_luminance(dark.hint)));

      // Page < card < alternate row < hover, so surfaces separate without shadow.
      expect(_luminance(dark.canvas), lessThan(_luminance(dark.surface)));
      expect(_luminance(dark.surface), lessThan(_luminance(dark.rowAlt)));
      expect(_luminance(dark.rowAlt), lessThan(_luminance(dark.hover)));

      // On a dark ground "stronger" means lighter, so the light theme's
      // border-below-divider rule inverts.
      expect(_luminance(dark.border), greaterThan(_luminance(dark.divider!)));
      expect(
        _luminance(UtopiaThemeColors.defaultTheme.border),
        lessThan(_luminance(UtopiaThemeColors.defaultTheme.divider!)),
      );
    });
  });
}

/// WCAG 2.1 relative luminance.
double _luminance(Color color) {
  double channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
}

/// WCAG 2.1 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
