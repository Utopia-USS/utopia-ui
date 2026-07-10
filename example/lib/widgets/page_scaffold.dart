import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import 'theme_mode_picker.dart';

/// Shared chrome for every page of the showcase shell: a header band with the
/// page title, a muted subtitle and the app-wide [ThemeModePicker], a
/// hairline divider constrained to the same content gutters as everything
/// else (not full-bleed), then [child] filling the remaining height. Pages
/// own their own scrolling (most through [PageBody]), so full-height layouts
/// stay possible.
class PageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Keep equal to the body's cap so the header's edges line up with the content.
  final double maxWidth;

  final Widget child;

  const PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    this.maxWidth = UtopiaPageWrapper.maxConstrainedWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final gutter = PageBody.gutterFor(constraints.maxWidth, maxWidth);
            // The divider sits inside the same gutters as the header and the
            // content below, so its edges line up with theirs instead of
            // running full-bleed across the window.
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
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: context.textStyles.header),
            const SizedBox(height: 4),
            Text(subtitle, style: context.textStyles.text.copyWith(color: context.colors.hint)),
          ],
        ),
        const ThemeModePicker(),
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
        // The top gap sits OUTSIDE the scroll viewport: pinned slivers (the
        // table's sticky header) pin to the viewport's top edge, so this is
        // the only way they keep breathing room from the page header while
        // scrolled. The leading in-viewport spacer makes up the difference so
        // the resting layout starts at the same 24px as before.
        return Padding(
          padding: EdgeInsets.only(top: context.spacing.lg),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: context.spacing.sm)),
              for (final sliver in slivers) SliverPadding(padding: padding, sliver: sliver),
              const SliverToBoxAdapter(child: SizedBox(height: 64)),
            ],
          ),
        );
      },
    );
  }
}
