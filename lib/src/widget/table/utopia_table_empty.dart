import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// The default empty state rendered by `UtopiaTable` when `rows` is an empty
/// list and no `emptyWidget` override is passed: a centered message,
/// optionally preceded by an [icon] and followed by a [subtitle] and
/// [actions].
///
/// The minimal configuration (`title` only, as `UtopiaTable` uses it) is a
/// centered, themed "No items" message; [icon], [subtitle] and [actions] are
/// opt-in for richer empty states (e.g. "No results - clear filters").
class UtopiaTableEmpty extends StatelessWidget {
  /// Optional illustration/icon shown above [title].
  final Widget? icon;

  /// The primary empty-state message.
  final String title;

  /// Optional secondary line shown below [title].
  final String? subtitle;

  /// Optional actions (e.g. "Clear filters", "Create") wrapped in a row
  /// below the text.
  final List<Widget> actions;

  const UtopiaTableEmpty({super.key, this.icon, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(height: 12)],
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textStyles.text.copyWith(color: context.colors.hint),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: context.textStyles.caption.copyWith(color: context.colors.hint),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
