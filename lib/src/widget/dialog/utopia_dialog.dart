import 'package:flutter/material.dart';
import 'package:utopia_ui/src/theme/utopia_theme.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/layout/utopia_form_layout.dart';
import 'package:utopia_ui/src/widget/layout/utopia_page_wrapper.dart';

/// Adaptive dialog chrome: a full-screen surface on [UtopiaPageType.mobile], a
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
  /// the dialog is always full-screen.
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
         return UtopiaFormLayout.raw(
           backgroundColor: Colors.transparent,
           content: CustomScrollView(slivers: [sliver]),
           bottom: SafeArea(top: false, child: bottom),
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
        final isMobile = pageType.isMobile;
        final body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TitleRow(title: title, isMobile: isMobile, dismissible: dismissible),
            Expanded(child: builder(context, pageType)),
          ],
        );

        if (isMobile) {
          return SizedBox.expand(
            child: Material(
              color: theme.colors.surface,
              child: SafeArea(child: body),
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

  /// Thin wrapper over vanilla [showDialog]. The only navigation opinion this
  /// takes is re-attaching the ambient `UtopiaThemeData` via [UtopiaTheme.captured]
  /// - `showDialog` roots at the app `Navigator`, outside of any `UtopiaTheme`
  /// ancestor, so without this the dialog subtree would fall back to
  /// `UtopiaThemeData.defaultTheme`.
  ///
  /// [dismissible] maps to `showDialog`'s `barrierDismissible`. A [UtopiaDialog]
  /// built with `dismissible: false` additionally blocks pops itself (see
  /// [UtopiaDialog.dismissible]), so forgetting to mirror the flag here cannot
  /// make a non-dismissible dialog dismissible.
  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) => UtopiaTheme.captured(context, child: builder(dialogContext)),
    );
  }
}

/// Title row: a leading back icon on mobile (when dismissible), a trailing
/// close icon on tablet/web (when dismissible), and [title] in between.
class _TitleRow extends StatelessWidget {
  final Widget title;
  final bool isMobile;
  final bool dismissible;

  const _TitleRow({required this.title, required this.isMobile, required this.dismissible});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final showBack = isMobile && dismissible;
    final showClose = !isMobile && dismissible;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colors.text),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: DefaultTextStyle.merge(
              style: isMobile ? theme.textStyles.title : theme.textStyles.header,
              child: title,
            ),
          ),
          if (showClose)
            IconButton(
              icon: Icon(Icons.close, color: theme.colors.text),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
    );
  }
}
