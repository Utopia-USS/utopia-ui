import 'package:flutter/material.dart';
import 'package:utopia_ui/src/theme/utopia_theme.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/button/utopia_button.dart';
import 'package:utopia_ui/src/widget/button/utopia_ghost_button.dart';

/// A themed confirm/cancel prompt drawn with the utopia card chrome - the
/// same surface, border and radius as every other card, lifted to the overlay
/// elevation a modal above a barrier takes - rather than a Material
/// [AlertDialog].
///
/// A neutral confirm/cancel prefab: no default title/subtitle strings are
/// baked in here - callers own their own copy. Title renders in
/// `textStyles.header`, body copy in `textStyles.text`, and the card is
/// capped at 400 logical pixels wide. The confirming action is a dense
/// [UtopiaButton]; the cancelling action is a quiet text button, so the
/// primary action carries the visual weight.
class UtopiaConfirmDialog extends StatelessWidget {
  /// Dialog title, shown in `textStyles.header`.
  final String title;

  /// Optional body copy, shown in `textStyles.text` below the title.
  /// When null, the dialog renders with no content section.
  final String? subtitle;

  /// Label of the confirming action button.
  final String confirmLabel;

  /// Label of the cancelling action button.
  final String cancelLabel;

  /// Whether the confirming action button is shown.
  final bool hasConfirm;

  /// Whether the cancelling action button is shown.
  final bool hasCancel;

  /// Renders the confirming action in the theme's error colour, for
  /// destructive confirmations (delete, sign out, ...).
  final bool danger;

  /// Creates a confirm dialog. Use [show] to present it as a route.
  const UtopiaConfirmDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.confirmLabel = 'Proceed',
    this.cancelLabel = 'Cancel',
    this.hasConfirm = true,
    this.hasCancel = true,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final texts = context.textStyles;
    final spacing = context.spacing;
    final subtitle = this.subtitle;

    return Center(
      child: Padding(
        // Keeps the card off the screen edges on narrow windows.
        padding: EdgeInsets.symmetric(horizontal: spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: Colors.transparent,
            child: Container(
              // dialogDecoration, not cardDecoration: this prompt floats over a
              // barrier like every other modal, so it carries the overlay
              // elevation rather than the resting elevation of a card sitting
              // in the page underneath it.
              decoration: theme.dialogDecoration,
              foregroundDecoration: theme.cardBorderDecoration,
              clipBehavior: Clip.antiAlias,
              padding: EdgeInsets.all(spacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: texts.header),
                  if (subtitle != null) ...[SizedBox(height: spacing.md), Text(subtitle, style: texts.text)],
                  SizedBox(height: spacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasCancel)
                        UtopiaGhostButton(label: cancelLabel, onTap: () => Navigator.of(context).pop(false)),
                      if (hasCancel && hasConfirm) SizedBox(width: spacing.md),
                      if (hasConfirm)
                        IntrinsicWidth(
                          child: UtopiaButton(
                            dense: true,
                            colors: danger ? [context.colors.error, context.colors.error] : null,
                            onTap: () => Navigator.of(context).pop(true),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: spacing.xl),
                              child: Text(confirmLabel),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Thin wrapper over vanilla [showDialog]: captures [UtopiaTheme.of] from
  /// [context] and re-attaches it inside the route (the dialog Navigator sits
  /// outside any `UtopiaTheme` ancestor), then builds a [UtopiaConfirmDialog] with
  /// the given parameters. Resolves to `true`/`false` depending on which
  /// action was pressed, or `null` if the dialog was dismissed unanswered.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String confirmLabel = 'Proceed',
    String cancelLabel = 'Cancel',
    bool hasConfirm = true,
    bool hasCancel = true,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => UtopiaTheme.captured(
        context,
        child: UtopiaConfirmDialog(
          title: title,
          subtitle: subtitle,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          hasConfirm: hasConfirm,
          hasCancel: hasCancel,
          danger: danger,
        ),
      ),
    );
  }
}
