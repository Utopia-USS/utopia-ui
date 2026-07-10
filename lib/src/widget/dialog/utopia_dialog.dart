import 'package:flutter/material.dart';
import 'package:utopia_ui/src/theme/utopia_theme.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/layout/utopia_form_layout.dart';
import 'package:utopia_ui/src/widget/layout/utopia_page_wrapper.dart';

/// Adaptive dialog chrome: a bottom sheet on [UtopiaPageType.mobile], a
/// centered rounded card everywhere else.
///
/// Resolves its own [UtopiaPageType] through an internal [UtopiaPageWrapper], so it
/// works standalone regardless of where it is shown from - no ambient
/// `UtopiaPageWrapper` is required around the call site.
///
/// Two constructors share one `build` implementation: [UtopiaDialog.new] hands
/// the body to a caller-supplied [builder], while [UtopiaDialog.form] composes
/// that same builder internally from a scrollable sliver and a pinned bottom
/// bar via [UtopiaFormLayout.raw].
class UtopiaDialog extends StatelessWidget {
  /// The title shown in the header row, next to the back/close affordance.
  final Widget title;

  /// Builds the dialog body below the title row, given the [UtopiaPageType]
  /// resolved for the dialog's own available space.
  final Widget Function(BuildContext context, UtopiaPageType pageType) builder;

  /// Maximum width of the dialog card on tablet/web. Ignored on mobile, where
  /// the dialog is presented as a full-width bottom sheet.
  final double maxWidth;

  /// Whether the dialog can be dismissed at all. Controls the back (mobile) /
  /// close (desktop) affordance in the title row AND blocks route pops
  /// (barrier taps, Escape, system back) via a [PopScope] while `false` - so
  /// a `dismissible: false` dialog cannot be dismissed regardless of how it
  /// was shown.
  final bool dismissible;

  /// Raw variant - full control of the body below the title row via [builder].
  const UtopiaDialog({
    super.key,
    required this.title,
    required this.builder,
    this.maxWidth = 1000,
    this.dismissible = true,
  });

  /// Form variant - a sliver-scrollable [sliver] with a [bottom] bar pinned
  /// below it (typically the submit/cancel actions), built on top of
  /// [UtopiaFormLayout.raw].
  ///
  /// The dialog owns the form insets: [sliver] and [bottom] are padded with
  /// the token scale (`spacing.xl` on the outer edges - the dialog inset -
  /// and `spacing.md` gaps around the fade bar), so callers pass bare
  /// content and every form dialog lines up with the title row. For custom
  /// insets use the raw constructor instead.
  ///
  /// Internally this stores [sliver] and [bottom] as a closure over the same
  /// [builder] field the raw constructor takes, so `build` never needs to
  /// branch on which constructor was used.
  UtopiaDialog.form({
    super.key,
    required this.title,
    required Widget sliver,
    required Widget bottom,
    this.maxWidth = 600,
    this.dismissible = true,
  }) : builder = ((context, pageType) {
         final spacing = context.spacing;
         return UtopiaFormLayout.raw(
           backgroundColor: Colors.transparent,
           content: CustomScrollView(
             slivers: [
               SliverPadding(
                 padding: EdgeInsets.fromLTRB(spacing.xl, spacing.sm, spacing.xl, spacing.md),
                 sliver: sliver,
               ),
             ],
           ),
           bottom: SafeArea(
             top: false,
             child: Padding(
               padding: EdgeInsets.fromLTRB(spacing.xl, spacing.md, spacing.xl, spacing.xl),
               child: bottom,
             ),
           ),
         );
       });

  @override
  Widget build(BuildContext context) {
    // The widget-level dismissal contract is enforced here rather than at the
    // show() call site, so a `dismissible: false` dialog stays modal even
    // when shown through a helper that left the barrier dismissible.
    if (!dismissible) return PopScope(canPop: false, child: _buildContent(context));
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return UtopiaPageWrapper(
      builder: (context, pageType) {
        final theme = context.theme;
        final tokens = context.tokens;
        final isMobile = pageType.isMobile;
        final body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMobile && dismissible) const _DragHandle(),
            _TitleRow(title: title, isMobile: isMobile, dismissible: dismissible),
            Expanded(child: builder(context, pageType)),
          ],
        );

        if (isMobile) {
          // Bottom-sheet chrome: full width, anchored to the bottom, leaving a
          // top gap so the barrier stays visible behind the sheet. The
          // keyboard inset is applied here because [show] presents the sheet
          // with `isScrollControlled: true`, which opts out of the framework's
          // own inset handling.
          return Padding(
            padding: EdgeInsets.only(top: tokens.spacing.xxxl),
            child: Material(
              color: theme.colors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radius.xl)),
              ),
              child: AnimatedPadding(
                duration: tokens.durations.sm,
                padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: SafeArea(top: false, child: body),
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 800),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: theme.cardDecoration,
                foregroundDecoration: theme.cardBorderDecoration,
                clipBehavior: Clip.antiAlias,
                child: body,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Presents the dialog as a route: a modal bottom sheet on mobile-class
  /// window widths (resolved through `tokens.breakpoints`, the same scale
  /// [UtopiaPageWrapper] uses), a vanilla [showDialog] everywhere else. The sheet
  /// route brings the slide-up transition and drag-to-dismiss; the widget
  /// itself draws the sheet chrome, so `backgroundColor` is transparent here.
  ///
  /// Both routes re-attach the ambient `UtopiaThemeData` via
  /// [UtopiaTheme.captured] - they root at the app `Navigator`, outside of any
  /// `UtopiaTheme` ancestor, so without this the dialog subtree would fall
  /// back to `UtopiaThemeData.defaultTheme`.
  ///
  /// [dismissible] maps to `showDialog`'s `barrierDismissible` and the sheet's
  /// `isDismissible`/`enableDrag`. A [UtopiaDialog] built with
  /// `dismissible: false` additionally blocks pops itself (see
  /// [UtopiaDialog.dismissible]), so forgetting to mirror the flag here cannot
  /// make a non-dismissible dialog dismissible.
  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
    final windowWidth = MediaQuery.sizeOf(context).width;
    final isMobile = UtopiaPageWrapper.resolveType(windowWidth, context.tokens.breakpoints).isMobile;
    if (isMobile) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        isDismissible: dismissible,
        enableDrag: dismissible,
        builder: (sheetContext) => UtopiaTheme.captured(context, child: builder(sheetContext)),
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) => UtopiaTheme.captured(context, child: builder(dialogContext)),
    );
  }
}

/// Title row: [title] with a trailing close icon (when dismissible). On
/// mobile the dialog is a bottom sheet, so the affordance is a close icon
/// there too - a back arrow would suggest navigation, not dismissal.
class _TitleRow extends StatelessWidget {
  final Widget title;
  final bool isMobile;
  final bool dismissible;

  const _TitleRow({required this.title, required this.isMobile, required this.dismissible});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final spacing = context.spacing;
    return Padding(
      // Left inset matches the form content's `spacing.xl` dialog inset so
      // the title aligns with the fields below. The right inset is `lg`
      // (xl minus the IconButton's built-in 8px padding) so the close glyph
      // optically sits on the same xl inset; the top is `lg` for the same
      // reason - the 40px IconButton row adds ~8px of visual headroom above
      // the title text, landing the optical inset on xl.
      padding: EdgeInsets.fromLTRB(spacing.xl, spacing.lg, spacing.lg, spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: DefaultTextStyle.merge(
              style: isMobile ? theme.textStyles.title : theme.textStyles.header,
              child: title,
            ),
          ),
          if (dismissible)
            IconButton(
              icon: Icon(Icons.close, color: theme.colors.text),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
    );
  }
}

/// The bottom sheet's drag affordance: a pill-shaped bar centered at the top
/// of the sheet, sized off the token base unit and colored `colors.border`.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: tokens.spacing.sm),
      child: Center(
        child: Container(
          width: tokens.x * 9,
          height: tokens.x,
          decoration: BoxDecoration(color: context.colors.border, borderRadius: tokens.radius.fullAll),
        ),
      ),
    );
  }
}
