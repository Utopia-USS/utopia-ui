import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import 'state/editor_page_state.dart';
import 'view/editor_page_view.dart';

/// An article form in content cards with the Publish action.
///
/// Screen per the Screen/State/View pattern - pure wiring: builds the
/// published-confirmation dialog callback from [BuildContext], calls the one
/// state hook, hands the state to the View.
class EditorPage extends HookWidget {
  /// Creates the editor page.
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useEditorPageState(
      showPublishedDialog: () async {
        if (!context.mounted) return;
        await UtopiaConfirmDialog.show(
          context,
          title: 'Article published',
          subtitle: 'This is a showcase - nothing left this page.',
          confirmLabel: 'Done',
          hasCancel: false,
        );
      },
    );
    return EditorPageView(state: state);
  }
}
