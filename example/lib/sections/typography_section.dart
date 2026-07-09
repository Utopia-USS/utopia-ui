import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// `UtopiaThemeTextStyles` - the six text roles every component draws from,
/// each shown next to its size and weight.
class TypographySection extends StatelessWidget {
  /// Creates the typography section.
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    return SheetSection(
      title: 'Typography',
      subtitle: 'UtopiaThemeTextStyles - the six roles every component draws from.',
      child: UtopiaCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypographyRow(name: 'header', style: textStyles.header),
              const SizedBox(height: 16),
              const UtopiaDivider(),
              const SizedBox(height: 16),
              _TypographyRow(name: 'title', style: textStyles.title),
              const SizedBox(height: 16),
              const UtopiaDivider(),
              const SizedBox(height: 16),
              _TypographyRow(name: 'label', style: textStyles.label),
              const SizedBox(height: 16),
              const UtopiaDivider(),
              const SizedBox(height: 16),
              _TypographyRow(name: 'text', style: textStyles.text),
              const SizedBox(height: 16),
              const UtopiaDivider(),
              const SizedBox(height: 16),
              _TypographyRow(name: 'caption', style: textStyles.caption),
              const SizedBox(height: 16),
              const UtopiaDivider(),
              const SizedBox(height: 16),
              _TypographyRow(name: 'button', style: textStyles.button, onGradient: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the typography table: a live text sample styled with [style],
/// followed by a hint-colored caption describing its size and weight.
class _TypographyRow extends StatelessWidget {
  final String name;
  final TextStyle style;
  final bool onGradient;

  const _TypographyRow({required this.name, required this.style, this.onGradient = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final size = style.fontSize?.toStringAsFixed(0) ?? '-';
    final weight = style.fontWeight != null ? 'w${style.fontWeight!.value}' : '-';
    final sample = Text('The quick brown fox 0123', style: style);
    final specimen = onGradient
        ? ClipRRect(
            borderRadius: theme.borderRadius,
            child: SizedBox(
              height: 40,
              width: 220,
              child: UtopiaGradientBackground(child: Center(child: sample)),
            ),
          )
        : sample;
    return Wrap(
      spacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        specimen,
        Text('$name - ${size}px $weight', style: context.textStyles.caption.copyWith(color: context.colors.hint)),
      ],
    );
  }
}
