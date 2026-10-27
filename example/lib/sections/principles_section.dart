import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

class PrinciplesSection extends StatelessWidget {
  const PrinciplesSection({super.key});

  static const _rules = <(String, String)>[
    (
      'No hardcoded values',
      'Components never inline a color, gap, radius or duration. Everything reads the ambient theme, '
          'which is why one knob repaints this whole page.',
    ),
    (
      'One base unit',
      'Spacing and radii are multiples of x. Off-scale values (a 10px gap, a 14px inset) are bugs, '
          'not fine-tuning.',
    ),
    (
      'One accent family',
      'Primary and accent are a tight same-hue pair - the button gradient, chips and selection states all '
          'draw from it, so an app never fights itself for attention.',
    ),
    (
      'Semantic slots over raw tokens',
      'A component asks for cardRadius or fieldContentPadding, not "16". The decision of which token a role '
          'sits on lives in the theme, in one place.',
    ),
    (
      'Controlled components',
      'Tables, fields and dialogs render state and report interaction - they never own app state. '
          'Your models, your data layer, your navigation.',
    ),
    (
      'Slivers compose',
      'The table is a sliver, not a widget with its own scroll view - it shares the page scroll with '
          'everything around it.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SheetSection(
      title: 'Principles',
      subtitle: 'The rules the components hold themselves to.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= context.tokens.breakpoints.webMin ? 3 : 1;
          final gap = context.spacing.lg;
          return Column(
            children: [
              for (var row = 0; row < _rules.length; row += columns)
                Padding(
                  padding: EdgeInsets.only(bottom: row + columns < _rules.length ? gap : 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = row; i < row + columns; i++) ...[
                          if (i > row) SizedBox(width: gap),
                          Expanded(
                            child: i < _rules.length
                                ? _RuleCard(index: i + 1, title: _rules[i].$1, body: _rules[i].$2)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final int index;
  final String title;
  final String body;

  const _RuleCard({required this.index, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.theme.cardRadius,
        border: Border.all(color: colors.border, width: context.theme.cardBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: tokens.x * 6,
                height: tokens.x * 6,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.chipBackground, shape: BoxShape.circle),
                child: Text('$index', style: textStyles.caption.copyWith(color: colors.chipForeground)),
              ),
              SizedBox(width: context.spacing.md),
              Expanded(child: Text(title, style: textStyles.label)),
            ],
          ),
          SizedBox(height: context.spacing.md),
          Text(
            body,
            style: textStyles.caption.copyWith(
              color: colors.hint,
              fontWeight: tokens.fontWeights.regular,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
