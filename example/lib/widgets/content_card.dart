import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// A titled [UtopiaCard] content block: heading, muted description, controls.
///
/// [footer] renders after [children]; with [pinFooter] it pins to the card's
/// bottom edge instead of following the content at a fixed gap.
class ContentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;

  /// Set when the card is stretched (equal-height card rows). Uses a [Spacer],
  /// so the card's height must be bounded - and the caller stating it (rather
  /// than a LayoutBuilder checking) keeps IntrinsicHeight ancestors legal.
  final bool pinFooter;

  const ContentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.pinFooter = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = context.colors;
    return UtopiaCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UtopiaTitle(title: title),
            const SizedBox(height: 4),
            Text(subtitle, style: context.textStyles.text.copyWith(color: colors.hint)),
            const SizedBox(height: 20),
            // canvas/field remap so borderless field chrome stays visible on the card.
            UtopiaTheme(
              data: theme.copyWith(
                colors: colors.copyWith(canvas: colors.surface, field: colors.canvas),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
            ),
            if (footer != null) ...[
              SizedBox(height: context.spacing.xl),
              if (pinFooter) const Spacer(),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
