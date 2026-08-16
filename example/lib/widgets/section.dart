import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// One titled block of the design-system sheet: a hairline divider, a
/// [UtopiaTitle] heading, a muted subtitle, then [child] - the specimens the
/// section is demonstrating. The leading divider gives every section a clear
/// top edge, so the sheet reads as a sequence of distinct blocks rather than
/// specimens floating loose on the canvas.
class SheetSection extends StatelessWidget {
  /// The section heading, shown via [UtopiaTitle].
  final String title;

  /// A short muted description shown below the heading.
  final String subtitle;

  /// Optional longer rationale shown under [child] - the why behind the
  /// section's design decisions.
  final String? note;

  /// The section's content - typically a `Wrap` of [SpecimenTile]s.
  final Widget child;

  /// Creates a titled sheet section.
  const SheetSection({super.key, required this.title, required this.subtitle, this.note, required this.child});

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    final index = SectionScope.of(context);
    final textStyles = context.textStyles;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          children: [
            if (index != null) ...[
              Text(
                index.toString().padLeft(2, '0'),
                style: textStyles.title.copyWith(
                  color: colors.hint,
                  fontWeight: context.tokens.fontWeights.semiBold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(width: context.spacing.md),
            ],
            Text(title, style: textStyles.header),
            SizedBox(width: context.spacing.md),
            Expanded(child: Container(height: context.tokens.borders.hairline, color: colors.border)),
          ],
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(subtitle, style: textStyles.text.copyWith(color: colors.hint)),
        ),
        const SizedBox(height: 24),
        child,
        if (note != null) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              note,
              style: textStyles.caption.copyWith(
                color: colors.hint,
                fontWeight: context.tokens.fontWeights.regular,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SectionScope extends InheritedWidget {
  final int index;

  const SectionScope({super.key, required this.index, required super.child});

  static int? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SectionScope>()?.index;

  @override
  bool updateShouldNotify(SectionScope oldWidget) => index != oldWidget.index;
}

/// A labeled specimen. By default the specimen sits on a raised surface panel
/// (surface fill, hairline border, cardRadius) with a side-panel
/// color remap (canvas -> surface, field -> canvas) so field chrome stays
/// visible; set [panel] to false for specimens that are themselves large
/// surfaces (tables, sidebars, cards).
class SpecimenTile extends StatelessWidget {
  /// The caption shown above [child].
  final String label;

  /// When set, the tile is wrapped in a `SizedBox` of this width.
  final double? width;

  /// Whether to render [child] on a raised surface panel with the field
  /// color remap. Defaults to `true`.
  final bool panel;

  /// The widget under test.
  final Widget child;

  /// Creates a labeled specimen tile.
  const SpecimenTile({super.key, required this.label, this.width, this.panel = true, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final caption = Text(label, style: context.textStyles.caption.copyWith(color: colors.hint));

    if (!panel) {
      final specimen = width == null ? child : SizedBox(width: width, child: child);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [caption, const SizedBox(height: 10), specimen],
      );
    }

    final theme = context.theme;
    // Side-panel color remap: the panel takes the surface colour and field
    // chrome takes the canvas tint, so field specimens stay visible instead
    // of blending into an identically-tinted backdrop.
    final remappedChild = UtopiaTheme(
      data: theme.copyWith(
        colors: colors.copyWith(canvas: colors.surface, field: colors.canvas),
      ),
      child: child,
    );
    final panelBody = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: theme.cardRadius,
        border: Border.all(color: colors.border, width: theme.cardBorderWidth),
        boxShadow: theme.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [caption, const SizedBox(height: 14), remappedChild],
      ),
    );
    return width == null ? panelBody : SizedBox(width: width, child: panelBody);
  }
}
