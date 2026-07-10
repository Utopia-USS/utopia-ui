import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import 'invoice.dart';
import 'state/dashboard_page_state.dart';
import 'view/dashboard_page_view.dart';
import 'view/new_invoice_dialog.dart';

/// The showcase's landing page: a live invoices dashboard.
///
/// Screen per the Screen/State/View pattern - pure wiring: builds the two
/// dialog callbacks from [BuildContext], calls the one state hook, hands the
/// state to the View.
class DashboardPage extends HookWidget {
  /// Creates the dashboard page.
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useDashboardPageState(
      entries: dashboardInvoiceEntries,
      showNewInvoiceDialog: (nextId) =>
          UtopiaDialog.show<Invoice>(context, builder: (_) => NewInvoiceDialog(nextId: nextId)),
      confirmRemove: (invoice) async {
        final confirmed = await UtopiaConfirmDialog.show(
          context,
          title: 'Delete ${invoice.id}?',
          subtitle: 'Removes the invoice for ${invoice.customer} from the list.',
          confirmLabel: 'Delete',
        );
        return confirmed ?? false;
      },
    );
    return DashboardPageView(state: state);
  }
}
