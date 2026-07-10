import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../../../widgets/page_scaffold.dart';
import '../invoice.dart';
import '../state/dashboard_page_state.dart';

/// The dashboard's View: stat cards over the live sliver table. Stateless -
/// everything it renders and every callback it wires comes off [state].
class DashboardPageView extends StatelessWidget {
  /// The page state, built by `useDashboardPageState`.
  final DashboardPageState state;

  /// Creates the dashboard view.
  const DashboardPageView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Dashboard',
      subtitle: 'Cards, chips and the sliver table on one live page - add and delete rows to see it react.',
      child: PageBody(
        slivers: [
          SliverToBoxAdapter(child: _StatCards(invoices: state.invoices)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          UtopiaTable<Invoice>(
            rows: state.visibleRows,
            entries: dashboardInvoiceEntries,
            rowKey: (row) => row.id,
            currentSort: state.currentSort,
            onSortPressed: state.onSortPressed,
            onSortSelected: state.onSortSelected,
            actionsBuilder: (context, row, index) => UtopiaRemoveIconButton(onPressed: () => state.removeInvoice(row)),
            searchPanel: UtopiaTableSearchPanel(
              searchField: UtopiaSearchField(
                value: state.searchState.value,
                hint: 'Search by customer',
                // Dense: matches the dense "New invoice" button beside it.
                dense: true,
                onChanged: (value) => state.searchState.value = value ?? '',
              ),
              actions: [
                UtopiaButton(dense: true, maxWidth: 160, onTap: state.addInvoice, child: const Text('New invoice')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashboard table's column configuration. View-owned (cell builders
/// return widgets); the Screen passes it into the state hook for the
/// search/sort predicates it also carries. Top-level so its identity is
/// stable across builds - `useUtopiaTableState` memoizes on it.
final IList<UtopiaTableEntry<Invoice>> dashboardInvoiceEntries = IList([
  UtopiaTableEntry<Invoice>.fixed(
    id: 'id',
    title: 'Id',
    width: 110,
    cellBuilder: (context, row) => UtopiaCopyableText(row.id),
  ),
  UtopiaTableEntry<Invoice>(
    id: 'customer',
    title: 'Customer',
    flex: 3,
    sortBy: (row) => row.customer,
    searchBy: (row) => row.customer,
    cellBuilder: (context, row) => Text(row.customer, style: context.textStyles.text),
  ),
  UtopiaTableEntry<Invoice>.fixed(
    id: 'issued',
    title: 'Issued',
    width: 130,
    sortBy: (row) => row.issued,
    cellBuilder: (context, row) => Text(row.issued.toDisplayStringWithoutHours(), style: context.textStyles.text),
  ),
  UtopiaTableEntry<Invoice>.fixed(
    id: 'amount',
    title: 'Amount',
    width: 130,
    sortBy: (row) => row.amount,
    cellBuilder: (context, row) => Text('\$${row.amount.toStringAsFixed(2)}', style: context.textStyles.text),
  ),
  UtopiaTableEntry<Invoice>.fixed(
    id: 'status',
    title: 'Status',
    width: 120,
    sortBy: (row) => row.status.label,
    cellBuilder: (context, row) => _StatusChip(status: row.status),
  ),
]);

/// The four headline cards above the table, each a [UtopiaCard] holding a
/// caption, a large value and a [UtopiaChip] annotation - all recomputed from
/// the live invoice list.
class _StatCards extends StatelessWidget {
  final IList<Invoice> invoices;

  const _StatCards({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final openCount = invoices.where((it) => it.status != InvoiceStatus.paid).length;
    final outstanding = invoices
        .where((it) => it.status != InvoiceStatus.paid)
        .fold(0.0, (sum, it) => sum + it.amount);
    final paid = invoices.where((it) => it.status == InvoiceStatus.paid).fold(0.0, (sum, it) => sum + it.amount);
    final overdueCount = invoices.where((it) => it.status == InvoiceStatus.overdue).length;

    final cards = [
      _StatCard(
        label: 'Outstanding',
        value: '\$${outstanding.toStringAsFixed(2)}',
        chip: UtopiaChip(child: Text('$openCount open')),
      ),
      _StatCard(
        label: 'Collected',
        value: '\$${paid.toStringAsFixed(2)}',
        chip: UtopiaChip(
          color: colors.primary.withValues(alpha: 0.12),
          contentColor: colors.primary,
          child: const Text('+12% this month'),
        ),
      ),
      _StatCard(
        label: 'Overdue',
        value: '$overdueCount',
        chip: overdueCount == 0
            ? UtopiaChip(
                color: colors.primary.withValues(alpha: 0.12),
                contentColor: colors.primary,
                child: const Text('All clear'),
              )
            : UtopiaChip(
                color: colors.error.withValues(alpha: 0.12),
                contentColor: colors.error,
                child: const Text('Needs attention'),
              ),
      ),
      _StatCard(label: 'Invoices', value: '${invoices.length}', chip: const UtopiaChip(child: Text('This quarter'))),
    ];

    // A nested UtopiaPageWrapper resolves the size class from THIS region's
    // width (not the window's), so the grid reacts to the space the cards
    // actually get: 4-up on web, 2x2 on tablet, stacked on mobile. Every card
    // is Expanded, so each row always fills the full content width.
    return UtopiaPageWrapper(
      builder: (context, pageType) {
        final columns = pageType.isWeb ? 4 : (pageType.isTablet ? 2 : 1);
        return Column(
          spacing: 16,
          children: [
            for (var i = 0; i < cards.length; i += columns)
              // IntrinsicHeight + stretch keeps the cards in a row equally
              // tall even when a chip label wraps in one of them.
              IntrinsicHeight(
                child: Row(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = i; j < i + columns && j < cards.length; j++) Expanded(child: cards[j]),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One headline card: caption, big value, then an annotation chip.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget chip;

  const _StatCard({required this.label, required this.value, required this.chip});

  @override
  Widget build(BuildContext context) {
    return UtopiaCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textStyles.caption.copyWith(color: context.colors.hint)),
            const SizedBox(height: 8),
            Text(value, style: context.textStyles.header),
            const SizedBox(height: 10),
            chip,
          ],
        ),
      ),
    );
  }
}

/// Renders an [InvoiceStatus] as a [UtopiaChip] with paid/pending/overdue
/// coloring drawn from the active theme.
class _StatusChip extends StatelessWidget {
  final InvoiceStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return switch (status) {
      InvoiceStatus.paid => UtopiaChip(
        color: colors.primary.withValues(alpha: 0.12),
        contentColor: colors.primary,
        child: Text(status.label),
      ),
      InvoiceStatus.pending => UtopiaChip(child: Text(status.label)),
      InvoiceStatus.overdue => UtopiaChip(
        color: colors.error.withValues(alpha: 0.12),
        contentColor: colors.error,
        child: Text(status.label),
      ),
    };
  }
}
