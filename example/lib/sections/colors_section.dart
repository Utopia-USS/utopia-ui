import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// `UtopiaThemeColors` - every surface-agnostic token of the active theme, plus
/// the three "on colored" tokens meant for gradient/coloured surfaces.
class ColorsSection extends StatelessWidget {
  /// Creates the colors section.
  const ColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final divider = colors.divider;
    final tokens = <(String, Color, String)>[
      ('primary', colors.primary, 'buttons, selection, active states'),
      ('accent', colors.accent, 'second gradient stop'),
      ('canvas', colors.canvas, 'page background'),
      ('surface', colors.surface, 'cards, popovers'),
      ('field', colors.field, 'input chrome'),
      ('border', colors.border, 'card hairlines'),
      // The divider slot is nullable (null derives a contrast-safe line at
      // paint time); the swatch row only shows it when the theme pins a value.
      if (divider != null) ('divider', divider, 'row separators'),
      ('rowAlt', colors.rowAlt, 'alternating rows'),
      ('hover', colors.hover, 'pointer feedback'),
      ('chipBackground', colors.chipBackground, 'tag fills'),
      ('chipForeground', colors.chipForeground, 'tag content'),
      ('text', colors.text, 'body copy'),
      ('hint', colors.hint, 'placeholders, secondary text'),
      ('error', colors.error, 'destructive, invalid'),
      ('disabled', colors.disabled, 'inert controls'),
    ];
    return SheetSection(
      title: 'Colors',
      subtitle: 'UtopiaThemeColors - the full token set of the active theme. Hover a swatch for its role '
          'and its WCAG contrast ratio against the surface.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 32,
            runSpacing: 24,
            children: [for (final (name, color, role) in tokens) _Swatch(name: name, color: color, role: role)],
          ),
          const SizedBox(height: 16),
          const _OnColoredStrip(),
        ],
      ),
    );
  }
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

class _Swatch extends StatelessWidget {
  final String name;
  final Color color;
  final String role;

  const _Swatch({required this.name, required this.color, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = context.colors;
    final textStyles = context.textStyles;
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toLowerCase()}';
    final ratio = _contrast(color, colors.surface);
    return Tooltip(
      message: '$role - ${ratio.toStringAsFixed(1)}:1 vs surface',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: context.spacing.xxxl,
            decoration: BoxDecoration(
              color: color,
              borderRadius: theme.borderRadius,
              border: Border.all(color: colors.border, width: context.tokens.borders.hairline),
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Text(name, style: textStyles.caption.copyWith(color: colors.text)),
          Text(
            hex,
            style: textStyles.caption.copyWith(color: colors.hint, fontWeight: context.tokens.fontWeights.regular),
          ),
        ],
      ),
    );
  }
}

/// The three `onColored*` tokens rendered as circles over the default
/// primary/accent gradient, since they are only ever meant to be read on top
/// of a coloured surface.
class _OnColoredStrip extends StatelessWidget {
  const _OnColoredStrip();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = context.theme;
    return ClipRRect(
      borderRadius: theme.borderRadius,
      child: SizedBox(
        height: 72,
        child: UtopiaGradientBackground(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OnColoredItem(name: 'onColoredContent', color: colors.onColoredContent),
                const SizedBox(width: 32),
                _OnColoredItem(name: 'onColoredSelected', color: colors.onColoredSelected),
                const SizedBox(width: 32),
                _OnColoredItem(name: 'onColoredHover', color: colors.onColoredHover),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnColoredItem extends StatelessWidget {
  final String name;
  final Color color;

  const _OnColoredItem({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(name, style: context.textStyles.caption.copyWith(color: context.colors.onColoredContent)),
      ],
    );
  }
}
