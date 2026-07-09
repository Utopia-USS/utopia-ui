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
    final tokens = <String, Color>{
      'primary': colors.primary,
      'accent': colors.accent,
      'canvas': colors.canvas,
      'surface': colors.surface,
      'field': colors.field,
      'border': colors.border,
      'rowAlt': colors.rowAlt,
      'hover': colors.hover,
      'chipBackground': colors.chipBackground,
      'chipForeground': colors.chipForeground,
      'text': colors.text,
      'hint': colors.hint,
      'error': colors.error,
      'disabled': colors.disabled,
    };
    return SheetSection(
      title: 'Colors',
      subtitle: 'UtopiaThemeColors - the full token set of the active theme. Swatches update live with the picker.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 32,
            runSpacing: 24,
            children: [for (final entry in tokens.entries) _Swatch(name: entry.key, color: entry.value)],
          ),
          const SizedBox(height: 16),
          const _OnColoredStrip(),
        ],
      ),
    );
  }
}

/// A single named swatch: a bordered color rectangle with the token name and
/// its hex value printed underneath.
class _Swatch extends StatelessWidget {
  final String name;
  final Color color;

  const _Swatch({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final textStyles = context.textStyles;
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: theme.borderRadius,
            border: Border.all(color: context.colors.border),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: textStyles.caption),
        Text(hex, style: textStyles.caption.copyWith(color: context.colors.hint)),
      ],
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
