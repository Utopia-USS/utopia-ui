import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../widgets/section.dart';

/// Sheet section demoing [UtopiaTable]: a sliver table with client-side search
/// and sort via [useUtopiaTableState], driven by ten typed mock invoice rows.
class TableSection extends HookWidget {
  /// Creates the table sheet section.
  const TableSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tableState = useUtopiaTableState<_Invoice>(rows: _invoices, entries: _invoiceEntries);

    return SheetSection(
      title: 'Table',
      subtitle:
          'The flagship component: a sliver table with client-side search, sort and themed cells via '
          'useUtopiaTableState.',
      child: SizedBox(
        height: 460,
        child: CustomScrollView(
          slivers: [
            UtopiaTable<_Invoice>(
              rows: tableState.visibleRows,
              entries: _invoiceEntries,
              rowKey: (row) => row.id,
              currentSort: tableState.currentSort,
              onSortPressed: tableState.onSortPressed,
              searchPanel: UtopiaTableSearchPanel(
                searchField: UtopiaSearchField(
                  value: tableState.searchState.value,
                  hint: 'Search by customer',
                  onChanged: (value) => tableState.searchState.value = value ?? '',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status of a mock [_Invoice], with the label and chip colors shown in the
/// table's status column.
enum _InvoiceStatus {
  /// Fully paid.
  paid('Paid'),

  /// Awaiting payment, not yet overdue.
  pending('Pending'),

  /// Past its due date.
  overdue('Overdue');

  /// Display label shown in the status chip.
  final String label;

  const _InvoiceStatus(this.label);
}

/// A mock invoice row for the [TableSection] demo table.
class _Invoice {
  /// Invoice identifier, e.g. `'INV-1042'`.
  final String id;

  /// Customer display name.
  final String customer;

  /// Invoice total.
  final double amount;

  /// Current payment status.
  final _InvoiceStatus status;

  const _Invoice({required this.id, required this.customer, required this.amount, required this.status});
}

/// Renders [status] as a [UtopiaChip] with paid/pending/overdue coloring drawn
/// from the active theme's tokens.
Widget _statusChip(BuildContext context, _InvoiceStatus status) {
  final colors = context.colors;
  return switch (status) {
    _InvoiceStatus.paid => UtopiaChip(
      color: colors.primary.withValues(alpha: 0.12),
      contentColor: colors.primary,
      child: Text(status.label),
    ),
    _InvoiceStatus.pending => UtopiaChip(child: Text(status.label)),
    _InvoiceStatus.overdue => UtopiaChip(
      color: colors.error.withValues(alpha: 0.12),
      contentColor: colors.error,
      child: Text(status.label),
    ),
  };
}

final IList<_Invoice> _invoices = IList(const [
  _Invoice(id: 'INV-1042', customer: 'Northwind Traders', amount: 1280.00, status: _InvoiceStatus.paid),
  _Invoice(id: 'INV-1043', customer: 'Blue Harbor Studio', amount: 640.50, status: _InvoiceStatus.pending),
  _Invoice(id: 'INV-1044', customer: 'Cedar & Finch', amount: 2310.00, status: _InvoiceStatus.overdue),
  _Invoice(id: 'INV-1045', customer: 'Lighthouse Media', amount: 480.00, status: _InvoiceStatus.paid),
  _Invoice(id: 'INV-1046', customer: 'Granite Peak Co.', amount: 95.20, status: _InvoiceStatus.pending),
  _Invoice(id: 'INV-1047', customer: 'Salt & Pepper Kitchens', amount: 1560.75, status: _InvoiceStatus.paid),
  _Invoice(id: 'INV-1048', customer: 'Riverstone Analytics', amount: 3020.00, status: _InvoiceStatus.overdue),
  _Invoice(id: 'INV-1049', customer: 'Amber Fields Farm', amount: 210.00, status: _InvoiceStatus.pending),
  _Invoice(id: 'INV-1050', customer: 'Northwind Traders', amount: 875.40, status: _InvoiceStatus.paid),
  _Invoice(id: 'INV-1051', customer: 'Cobalt Works', amount: 1420.00, status: _InvoiceStatus.overdue),
]);

final IList<UtopiaTableEntry<_Invoice>> _invoiceEntries = IList([
  UtopiaTableEntry<_Invoice>.fixed(
    id: 'id',
    title: 'Id',
    width: 110,
    cellBuilder: (context, row) => UtopiaCopyableText(row.id),
  ),
  UtopiaTableEntry<_Invoice>(
    id: 'customer',
    title: 'Customer',
    flex: 3,
    sortBy: (row) => row.customer,
    searchBy: (row) => row.customer,
    cellBuilder: (context, row) => Text(row.customer, style: context.textStyles.text),
  ),
  UtopiaTableEntry<_Invoice>.fixed(
    id: 'amount',
    title: 'Amount',
    width: 130,
    sortBy: (row) => row.amount,
    cellBuilder: (context, row) => Text('\$${row.amount.toStringAsFixed(2)}', style: context.textStyles.text),
  ),
  UtopiaTableEntry<_Invoice>.fixed(
    id: 'status',
    title: 'Status',
    width: 120,
    sortBy: (row) => row.status.label,
    cellBuilder: (context, row) => _statusChip(context, row.status),
  ),
]);
