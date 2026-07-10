import 'package:utopia_hooks/utopia_hooks.dart';
// Type-only import: UtopiaTableEntry / UtopiaTableSort / useUtopiaTableState.
// The hook never constructs widgets - the entries (which carry cell builders)
// are view configuration, passed in by the Screen from the View's constant.
import 'package:utopia_ui/utopia_ui.dart';

import '../invoice.dart';

/// All dashboard page state and behaviour, per the Screen/State/View pattern:
/// the live invoice list, the table's client-side search/sort projections,
/// and the add/remove actions. Dialogs are context work, so they arrive as
/// callbacks from the Screen.
class DashboardPageState {
  /// The full invoice list - the stat cards derive from this.
  final IList<Invoice> invoices;

  /// Search-filtered, sorted rows for the table.
  final IList<Invoice>? visibleRows;

  /// The current table sort, if any.
  final UtopiaTableSort? currentSort;

  /// Live search-field state, fed to the table's search input.
  final FieldState searchState;

  /// Toggles a sortable column - pass to `UtopiaTable.onSortPressed`.
  final void Function(UtopiaTableEntry<Invoice> entry) onSortPressed;

  /// Applies an explicit sort pick - pass to `UtopiaTable.onSortSelected`.
  final void Function(UtopiaTableSort sort) onSortSelected;

  /// Opens the new-invoice dialog and appends the created row.
  final void Function() addInvoice;

  /// Confirms and removes [Invoice] from the list.
  final void Function(Invoice invoice) removeInvoice;

  const DashboardPageState({
    required this.invoices,
    required this.visibleRows,
    required this.currentSort,
    required this.searchState,
    required this.onSortPressed,
    required this.onSortSelected,
    required this.addInvoice,
    required this.removeInvoice,
  });
}

/// Dashboard page state hook. [entries] is the table's column configuration
/// (search/sort predicates live on it); [showNewInvoiceDialog] and
/// [confirmRemove] are the Screen-built dialog callbacks.
DashboardPageState useDashboardPageState({
  required IList<UtopiaTableEntry<Invoice>> entries,
  required Future<Invoice?> Function(String nextId) showNewInvoiceDialog,
  required Future<bool> Function(Invoice invoice) confirmRemove,
}) {
  final invoices = useState(seedInvoices);
  final tableState = useUtopiaTableState<Invoice>(rows: invoices.value, entries: entries);

  Future<void> addInvoice() async {
    final created = await showNewInvoiceDialog('INV-${1042 + invoices.value.length}');
    if (created != null) invoices.value = invoices.value.add(created);
  }

  Future<void> removeInvoice(Invoice invoice) async {
    if (await confirmRemove(invoice)) invoices.value = invoices.value.remove(invoice);
  }

  return DashboardPageState(
    invoices: invoices.value,
    visibleRows: tableState.visibleRows,
    currentSort: tableState.currentSort,
    searchState: tableState.searchState,
    onSortPressed: tableState.onSortPressed,
    onSortSelected: tableState.onSortSelected,
    addInvoice: addInvoice,
    removeInvoice: removeInvoice,
  );
}
