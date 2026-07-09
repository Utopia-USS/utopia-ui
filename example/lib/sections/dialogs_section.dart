import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// Sheet section demoing the two dialog prefabs: [UtopiaDialog.form] (a
/// scrollable field sliver with a pinned action bar) and [UtopiaConfirmDialog]
/// (the confirm/cancel prefab). Both are launched through their own `show`
/// helpers, so this section only needs two buttons.
class DialogsSection extends StatelessWidget {
  /// Creates the dialogs sheet section.
  const DialogsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetSection(
      title: 'Dialogs',
      subtitle:
          'UtopiaDialog.form composes a scrollable field sliver with a pinned action bar; '
          'UtopiaConfirmDialog is the confirm/cancel prefab. Full-screen on mobile, card on desktop.',
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        children: [
          UtopiaButton(
            dense: true,
            maxWidth: 220,
            onTap: () => UtopiaDialog.show<void>(context, builder: (_) => const _SettingsDialog()),
            child: const Text('Open form dialog'),
          ),
          UtopiaButton(
            dense: true,
            maxWidth: 220,
            onTap: () => UtopiaConfirmDialog.show(
              context,
              title: 'Delete workspace?',
              subtitle: 'This is a sheet demo - nothing is deleted.',
              confirmLabel: 'Delete',
            ),
            child: const Text('Open confirm dialog'),
          ),
        ],
      ),
    );
  }
}

/// The `UtopiaDialog.form` demo: a workspace name field, a role dropdown, a date
/// picker and a switch in the scrollable sliver, one `UtopiaButton` in the
/// pinned bottom bar that just pops - a mock form has nothing to submit to.
/// (Lightweight-tier HookWidget: the dropdown/date/switch values are this
/// dialog's only state.)
class _SettingsDialog extends HookWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    final roleState = useState('Viewer');
    final publishedState = useState<DateTime?>(null);
    final publicSignUpState = useState(true);

    return UtopiaDialog.form(
      title: const Text('Workspace settings'),
      sliver: SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        sliver: SliverList.list(
          children: [
            UtopiaTextField(value: 'Acme Inc.', label: const Text('Workspace name'), onChanged: (_) {}),
            const SizedBox(height: 14),
            UtopiaDropdownField<String>(
              label: 'Default role',
              value: roleState.value,
              values: const ['Admin', 'Editor', 'Viewer'],
              valueLabelBuilder: (value) => value,
              onChanged: (value) => roleState.value = value,
            ),
            const SizedBox(height: 14),
            UtopiaDatePicker(
              date: publishedState.value,
              label: 'Published',
              onDateChanged: (date) => publishedState.value = date,
            ),
            const SizedBox(height: 14),
            UtopiaSwitchField(
              value: publicSignUpState.value,
              title: 'Public sign-up',
              onChanged: (value) => publicSignUpState.value = value,
            ),
          ],
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: UtopiaButton(onTap: () => Navigator.of(context).maybePop(), child: const Text('Done')),
      ),
    );
  }
}
