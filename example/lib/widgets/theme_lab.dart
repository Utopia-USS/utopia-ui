import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../state/theme_lab_state.dart';
import 'section.dart';
import 'theme_mode_picker.dart';

class ThemeLab extends HookWidget {
  const ThemeLab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useProvided<ThemeLabState>();
    final spacing = context.spacing;

    return SheetSection(
      title: 'Theme lab',
      subtitle: 'The whole page runs on one UtopiaThemeData. Turn the knobs and watch every component follow.',
      note:
          'One base unit drives every gap, radius and control height on this page. The primary picker also '
          'derives the accent (the second gradient stop) so button sweeps stay a tight same-family pair. '
          'When something looks right, the block below is the exact code that reproduces it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Knobs(state: state),
          SizedBox(height: spacing.xl),
          _PasteBack(state: state),
        ],
      ),
    );
  }
}

class _Knobs extends StatelessWidget {
  final ThemeLabState state;

  const _Knobs({required this.state});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final captionStyle = context.textStyles.caption.copyWith(color: context.colors.hint);
    final baseUnit = _LabSlider(
      label: 'Base unit x',
      value: state.baseUnit.value,
      min: 3,
      max: 6,
      divisions: 6,
      format: (value) => '${value.toStringAsFixed(1)} px',
      onChanged: (value) => state.baseUnit.value = value,
    );
    final roundness = _LabSlider(
      label: 'Roundness',
      value: state.roundness.value,
      min: 0,
      max: 2,
      divisions: 8,
      format: (value) => '${value.toStringAsFixed(2)}x',
      onChanged: (value) => state.roundness.value = value,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Palette', style: captionStyle),
        SizedBox(height: spacing.sm),
        const ThemeModePicker(),
        SizedBox(height: spacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < context.tokens.breakpoints.tabletMin) {
              return Column(children: [baseUnit, roundness]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: baseUnit),
                SizedBox(width: spacing.xxl),
                Expanded(child: roundness),
              ],
            );
          },
        ),
        SizedBox(height: spacing.md),
        Text('Primary', style: captionStyle),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Expanded(child: _PrimaryRow(state: state)),
            if (state.isModified) ...[
              SizedBox(width: spacing.lg),
              _ResetPill(onTap: state.reset),
            ],
          ],
        ),
      ],
    );
  }
}

class _LabSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double value) format;
  final void Function(double value) onChanged;

  const _LabSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: textStyles.caption.copyWith(color: colors.hint)),
              Text(format(value), style: textStyles.caption.copyWith(color: colors.primary)),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          UtopiaSlider(
            key: ValueKey('labSlider_$label'),
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PrimaryRow extends StatelessWidget {
  static const _candidates = [
    Color(0xFF4A6FFF),
    Color(0xFF7C4DFF),
    Color(0xFFDB3E86),
    Color(0xFFE5484D),
    Color(0xFFE8890C),
    Color(0xFF2FA85C),
    Color(0xFF0FA3B1),
    Color(0xFF1C1C28),
  ];

  final ThemeLabState state;

  const _PrimaryRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final selected = state.primaryOverride.value;
    return Wrap(
      spacing: context.spacing.sm,
      runSpacing: context.spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Dot(
          color: state.preset.value.swatches.first,
          isSelected: selected == null,
          isStock: true,
          onTap: () => state.primaryOverride.value = null,
        ),
        for (final candidate in _candidates)
          _Dot(
            color: candidate,
            isSelected: selected == candidate,
            onTap: () => state.primaryOverride.value = candidate,
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final bool isStock;
  final VoidCallback onTap;

  const _Dot({required this.color, required this.isSelected, this.isStock = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    return Tooltip(
      message: isStock ? 'Preset primary' : '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: tokens.durations.sm,
            width: tokens.x * 8,
            height: tokens.x * 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colors.text : colors.border,
                width: isSelected ? tokens.borders.thick : tokens.borders.hairline,
              ),
            ),
            child: isStock
                ? Icon(Icons.refresh, size: tokens.x * 4, color: colors.onColoredContent)
                : (isSelected ? Icon(Icons.check, size: tokens.x * 4, color: colors.onColoredContent) : null),
          ),
        ),
      ),
    );
  }
}

class _PasteBack extends HookWidget {
  final ThemeLabState state;

  const _PasteBack({required this.state});

  @override
  Widget build(BuildContext context) {
    final copied = useState(false);
    final colors = context.colors;
    final tokens = context.tokens;
    final snippet = state.dartSnippet();

    Future<void> copy() async {
      await Clipboard.setData(ClipboardData(text: snippet));
      copied.value = true;
      await Future<void>.delayed(const Duration(seconds: 2));
      if (context.mounted) copied.value = false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paste it back',
          style: context.textStyles.caption.copyWith(color: colors.hint),
        ),
        SizedBox(height: context.spacing.sm),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: copy,
            child: AnimatedContainer(
              duration: tokens.durations.sm,
              width: double.infinity,
              padding: EdgeInsets.all(context.spacing.lg),
              decoration: BoxDecoration(
                color: colors.field,
                borderRadius: context.theme.cardRadius,
                border: Border.all(
                  color: copied.value ? colors.primary : colors.border,
                  width: tokens.borders.thin,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        copied.value ? Icons.done_all : Icons.copy,
                        size: tokens.x * 3.5,
                        color: copied.value ? colors.primary : colors.hint,
                      ),
                      SizedBox(width: context.spacing.sm),
                      Text(
                        copied.value ? 'Copied' : 'Tap to copy',
                        style: context.textStyles.caption.copyWith(
                          color: copied.value ? colors.primary : colors.hint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.md),
                  Text(
                    snippet,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.7,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetPill extends StatelessWidget {
  final VoidCallback onTap;

  const _ResetPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    return Material(
      color: colors.chipBackground,
      borderRadius: BorderRadius.circular(tokens.radius.full),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: colors.hover,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.md, vertical: context.spacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, size: tokens.x * 3.5, color: colors.chipForeground),
              SizedBox(width: context.spacing.xs),
              Text('Reset knobs', style: context.textStyles.caption.copyWith(color: colors.chipForeground)),
            ],
          ),
        ),
      ),
    );
  }
}
