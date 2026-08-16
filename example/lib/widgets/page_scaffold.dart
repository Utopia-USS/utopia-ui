import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';


/// Shared chrome for every page of the showcase shell: a header band with the
/// page title, a muted subtitle, a
/// hairline divider constrained to the same content gutters as everything
/// else (not full-bleed), then [child] filling the remaining height. Pages
/// own their own scrolling (most through [PageBody]), so full-height layouts
/// stay possible.
class PageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? eyebrow;
  final String? badge;

  /// Keep equal to the body's cap so the header's edges line up with the content.
  final double maxWidth;

  final Widget child;

  const PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.badge,
    this.maxWidth = UtopiaPageWrapper.maxConstrainedWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hasRail = MediaQuery.sizeOf(context).width >= context.tokens.breakpoints.sidebarMin;
    if (!hasRail) {
      return NestedScrollView(
        headerSliverBuilder: (context, _) => [SliverToBoxAdapter(child: _buildBand(context))],
        body: child,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBand(context),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildBand(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = PageBody.gutterFor(constraints.maxWidth, maxWidth);
        return Padding(
          padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              const UtopiaDivider(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textStyles = context.textStyles;
    final colors = context.colors;
    final eyebrow = this.eyebrow;
    final badge = this.badge;
    final caption = textStyles.caption;
    final wordmark = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow.toUpperCase(),
            style: caption.copyWith(
              color: colors.hint,
              fontWeight: context.tokens.fontWeights.semiBold,
              letterSpacing: (caption.fontSize ?? 13) * 0.14,
            ),
          ),
          SizedBox(height: context.spacing.sm),
        ],
        Text(
          title,
          style: textStyles.header.copyWith(fontSize: (textStyles.header.fontSize ?? 24) * 1.5, height: 1.1),
        ),
        SizedBox(height: context.spacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(subtitle, style: textStyles.text.copyWith(color: colors.hint)),
        ),
      ],
    );
    if (badge == null) return wordmark;
    return Wrap(
      spacing: context.spacing.lg,
      runSpacing: context.spacing.lg,
      alignment: WrapAlignment.spaceBetween,
      children: [
        wordmark,
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.md, vertical: context.spacing.xs),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.radius.full),
            border: Border.all(color: colors.border, width: context.tokens.borders.hairline),
          ),
          child: Text(
            badge,
            style: caption.copyWith(color: colors.hint, fontWeight: context.tokens.fontWeights.medium),
          ),
        ),
      ],
    );
  }
}

/// The standard page body: a full-width `CustomScrollView` (so the wheel works
/// from the gutters too) with the slivers centered and width-capped via padding.
class PageBody extends StatelessWidget {
  final List<Widget> slivers;
  final double maxWidth;

  static const double _minGutter = 24;

  const PageBody({super.key, required this.slivers, this.maxWidth = UtopiaPageWrapper.maxConstrainedWidth});

  /// The gutter that centers [maxWidth]-capped content in [available] width -
  /// shared by the header and the editor's form so all edges line up.
  static double gutterFor(double available, [double maxWidth = UtopiaPageWrapper.maxConstrainedWidth]) =>
      ((available - maxWidth) / 2).clamp(_minGutter, double.infinity);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = gutterFor(constraints.maxWidth, maxWidth);
        final padding = EdgeInsets.symmetric(horizontal: gutter);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: context.spacing.lg)),
            for (final sliver in slivers) SliverPadding(padding: padding, sliver: sliver),
            const SliverToBoxAdapter(child: SizedBox(height: 64)),
          ],
        );
      },
    );
  }
}
