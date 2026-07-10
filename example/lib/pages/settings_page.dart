import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/content_card.dart';
import '../widgets/page_scaffold.dart';

/// Workspace settings cards: profile fields, notification switches, danger zone.
class SettingsPage extends HookWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nameState = useState('Acme Inc.');
    final emailState = useState('billing@acme.dev');
    final weeklyDigestState = useState(true);
    final invoiceAlertsState = useState(true);
    final productNewsState = useState(false);

    final colors = context.colors;
    final fieldGap = SizedBox(height: context.spacing.lg);

    final workspaceCard = ContentCard(
      title: 'Workspace',
      subtitle: 'Profile fields plus a read-only, copyable API key.',
      children: [
        UtopiaTextField(
          value: nameState.value,
          label: const Text('Workspace name'),
          onChanged: (value) => nameState.value = value ?? '',
        ),
        fieldGap,
        UtopiaTextField(
          value: emailState.value,
          label: const Text('Billing email'),
          suffix: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.mail_outline, size: 18),
          ),
          onChanged: (value) => emailState.value = value ?? '',
        ),
        fieldGap,
        const UtopiaLabeledField(label: 'Plan', value: 'Scale (annual)'),
        fieldGap,
        Text('API key', style: context.textStyles.caption.copyWith(color: colors.hint)),
        SizedBox(height: context.spacing.sm),
        const UtopiaCopyableText('utp_live_4f9c2b7d81aa43ce'),
      ],
    );

    final notificationsCard = ContentCard(
      title: 'Notifications',
      subtitle: 'Switch fields share the same wrapper chrome as text fields.',
      children: [
        UtopiaSwitchField(
          value: weeklyDigestState.value,
          title: 'Weekly digest',
          onChanged: (value) => weeklyDigestState.value = value,
        ),
        fieldGap,
        UtopiaSwitchField(
          value: invoiceAlertsState.value,
          title: 'Overdue invoice alerts',
          onChanged: (value) => invoiceAlertsState.value = value,
        ),
        fieldGap,
        UtopiaSwitchField(
          value: productNewsState.value,
          title: 'Product news',
          onChanged: (value) => productNewsState.value = value,
        ),
      ],
    );

    final dangerCard = ContentCard(
      title: 'Danger zone',
      subtitle: 'The same button, re-colored through its gradient override.',
      children: [
        UtopiaButton(
          dense: true,
          maxWidth: 220,
          colors: [colors.error, colors.error],
          onTap: () => UtopiaConfirmDialog.show(
            context,
            title: 'Delete workspace?',
            subtitle: 'This is a showcase - nothing is deleted.',
            confirmLabel: 'Delete',
            danger: true,
          ),
          child: const Text('Delete workspace'),
        ),
      ],
    );

    return PageScaffold(
      title: 'Settings',
      subtitle: 'Cards, labeled fields, switches and the destructive-action pattern.',
      child: PageBody(
        slivers: [
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inline = constraints.maxWidth >= context.tokens.breakpoints.webMin;
                if (inline) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: workspaceCard),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              notificationsCard,
                              const SizedBox(height: 24),
                              Expanded(child: dangerCard),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    workspaceCard,
                    const SizedBox(height: 24),
                    notificationsCard,
                    const SizedBox(height: 24),
                    dangerCard,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
