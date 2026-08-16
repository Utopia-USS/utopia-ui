import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/layout/utopia_card.dart';
import 'package:utopia_ui/src/widget/layout/utopia_divider.dart';
import 'package:utopia_ui/src/widget/loading/utopia_loading_box.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_cell.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_empty.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_entry.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_header.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_item.dart';

/// A general-purpose, data-shape-agnostic data table, generic over the row
/// type [T]. Fully controlled: pass [rows], sort state and callbacks; the
/// widget renders and reports interaction, it never owns app state.
///
/// Rendered as a sliver so it composes into the page's [CustomScrollView]:
/// everything lives in one card ([utopiaCardSliver]) - a pinned header (the
/// optional [searchPanel] + the column headers + a divider) followed by a
/// divider-separated list of rows. [rows] being `null` renders a skeleton
/// loader that mirrors the real row layout; an empty (non-null) list renders
/// [emptyWidget].
///
/// Rows are matched across rebuilds by [rowKey] (keyed diffing), so reordering
/// or inserting rows does not tear down and rebuild unrelated row state (e.g.
/// hover) - see [_buildList].
///
/// Responsive: columns give way by [UtopiaTableEntry.hidePriority] when their
/// declared footprints no longer fit the table's width - see [_fitEntries].
class UtopiaTable<T> extends HookWidget {
  /// The rows to render. `null` renders the loading skeleton instead;
  /// an empty list renders [emptyWidget].
  final IList<T>? rows;

  /// The table's columns, in display order.
  final IList<UtopiaTableEntry<T>> entries;

  /// Stable identity extractor used for keyed diffing between rebuilds -
  /// backs each row's [ValueKey] and the list's `findItemIndexCallback`.
  final Object Function(T row) rowKey;

  /// Optional slot pinned above the column headers (e.g. a search field and
  /// filters). `null` skips the slot entirely - no reserved space.
  final Widget? searchPanel;

  /// The column currently driving sort order, if any.
  final UtopiaTableSort? currentSort;

  /// Called when a sortable column without [UtopiaTableEntry.sortOptions] is
  /// pressed - the caller toggles direction and re-sorts/re-fetches.
  final void Function(UtopiaTableEntry<T> entry)? onSortPressed;

  /// Called when an entry is picked from a [UtopiaTableEntry.sortOptions]
  /// dropdown.
  final void Function(UtopiaTableSort sort)? onSortSelected;

  /// Builds a trailing actions cell for a row, when the table needs one
  /// (e.g. a manage/delete menu). `null` omits the actions column entirely.
  final Widget Function(BuildContext context, T row, int index)? actionsBuilder;

  /// Called when a row is tapped. `null` makes rows non-interactive.
  final void Function(T row, int index)? onRowPressed;

  /// Shown instead of the row list when [rows] is an empty (non-null) list.
  /// Defaults to a plain [UtopiaTableEmpty] with a "No items" title.
  final Widget? emptyWidget;

  /// Number of placeholder rows rendered while [rows] is `null`.
  final int loaderRowCount;

  const UtopiaTable({
    super.key,
    required this.rows,
    required this.entries,
    required this.rowKey,
    this.searchPanel,
    this.currentSort,
    this.onSortPressed,
    this.onSortSelected,
    this.actionsBuilder,
    this.onRowPressed,
    this.emptyWidget,
    this.loaderRowCount = 12,
  });

  /// Width reserved for the trailing actions cell.
  static const double actionsWidth = 24;

  /// Horizontal inset applied to every cell's content.
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(horizontal: 16);

  /// Horizontal inset applied to a whole row/header ([itemPadding] sits
  /// inside it, once per cell).
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16);

  /// Width a flexing column is assumed to need when deciding which columns
  /// fit, unless the entry overrides it via [UtopiaTableEntry.minWidth].
  static const double flexColumnMinWidth = 120;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows;
    // Computed unconditionally (empty map when `rows` is `null`) so the hook
    // order stays stable across builds where `rows` flips between `null` and
    // a list - see the charter's hook-order rule.
    final indexByKey = useMemoized(
      () => visibleRows == null
          ? const <Object, int>{}
          : <Object, int>{for (var i = 0; i < visibleRows.length; i++) rowKey(visibleRows[i]): i},
      [visibleRows],
    );
    // The fitted column subset needs the real width, so the card builds inside
    // a SliverLayoutBuilder. No hooks below: the builder runs in its own scope.
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final visibleEntries = _fitEntries(constraints.crossAxisExtent);
        return utopiaCardSliver(
          context,
          sliver: SliverMainAxisGroup(
            slivers: [
              _buildHeader(context, visibleEntries),
              if (visibleRows == null)
                _buildLoader(context, visibleEntries)
              else if (visibleRows.isEmpty)
                _buildEmpty(context)
              else
                _buildList(context, visibleEntries, visibleRows, indexByKey),
            ],
          ),
        );
      },
    );
  }

  /// Hides the highest-[UtopiaTableEntry.hidePriority] column (rightmost first
  /// among equals) until the rest fit [width]; priority-0 columns never hide.
  IList<UtopiaTableEntry<T>> _fitEntries(double width) {
    final available =
        width - contentPadding.horizontal - (actionsBuilder == null ? 0 : actionsWidth + itemPadding.horizontal);
    double footprint(UtopiaTableEntry<T> entry) => entry.flex == null
        ? (entry.width ?? UtopiaTableEntryCellExtension.defaultFixedColumnWidth)
        : (entry.minWidth ?? flexColumnMinWidth);

    var visible = entries;
    var total = visible.fold(0.0, (sum, entry) => sum + footprint(entry));
    while (total > available) {
      UtopiaTableEntry<T>? giveWay;
      var giveWayIndex = -1;
      for (var i = 0; i < visible.length; i++) {
        final entry = visible[i];
        if (entry.hidePriority > 0 && (giveWay == null || entry.hidePriority >= giveWay.hidePriority)) {
          giveWay = entry;
          giveWayIndex = i;
        }
      }
      if (giveWay == null) break;
      total -= footprint(giveWay);
      visible = visible.removeAt(giveWayIndex);
    }
    return visible;
  }

  Widget _buildHeader(BuildContext context, IList<UtopiaTableEntry<T>> visibleEntries) {
    final cardRadius = context.theme.cardRadius;
    // Rounded opaque fill (no ClipRRect layer): the panel content is inset, so
    // rounding the background is enough to keep the card's top corners, and the
    // opaque surface hides rows scrolling under the pinned header.
    return PinnedHeaderSliver(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.only(topLeft: cardRadius.topLeft, topRight: cardRadius.topRight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?searchPanel,
            // No UtopiaDivider here: the header draws its own bottom rule in
            // `colors.border`, one step stronger than the divider that
            // separates rows, so the header/data caesura outranks the row
            // lines instead of doubling up with one.
            UtopiaTableHeader<T>(
              entries: visibleEntries,
              currentSort: currentSort,
              onSortPressed: onSortPressed,
              onSortSelected: onSortSelected,
              hasActions: actionsBuilder != null,
            ),
          ],
        ),
      ),
    );
  }

  /// Keyed row list: [rowKey] backs both each row's [ValueKey] and
  /// `findItemIndexCallback`, so Flutter matches existing row [Element]s
  /// (and their hover/animation state) to their new position instead of
  /// rebuilding from scratch when [rows] is reordered or spliced.
  ///
  /// [indexByKey] is a precomputed `rowKey(row) -> index` lookup (built once
  /// per [rows] identity in [build]), so resolving a key is O(1) instead of
  /// scanning [visibleRows] with `indexWhere` on every lookup.
  Widget _buildList(
    BuildContext context,
    IList<UtopiaTableEntry<T>> visibleEntries,
    IList<T> visibleRows,
    Map<Object, int> indexByKey,
  ) {
    return SliverList.separated(
      itemCount: visibleRows.length,
      separatorBuilder: (_, _) => const UtopiaDivider(),
      findItemIndexCallback: (key) => key is ValueKey<Object> ? indexByKey[key.value] : null,
      itemBuilder: (context, index) {
        final row = visibleRows[index];
        return KeyedSubtree(
          key: ValueKey(rowKey(row)),
          child: UtopiaTableItem<T>(
            row: row,
            index: index,
            entries: visibleEntries,
            isOdd: index.isOdd,
            isLast: index == visibleRows.length - 1,
            onRowPressed: onRowPressed,
            actionsBuilder: actionsBuilder,
          ),
        );
      },
    );
  }

  /// Loading placeholder. Mirrors [_buildList] / [UtopiaTableItem]'s layout -
  /// same row shell ([utopiaTableRowShell]: min height, padding, alternating
  /// tint), column widths and dividers - so the shimmer reads as real rows
  /// instead of floating boxes. Skeleton rows sit at the shell's *minimum*
  /// height; real rows may grow taller with wrapping cell content. Each cell
  /// holds a thin, left-aligned bar where the cell's preview content would sit.
  Widget _buildLoader(BuildContext context, IList<UtopiaTableEntry<T>> visibleEntries) {
    return SliverList.separated(
      itemCount: loaderRowCount,
      separatorBuilder: (_, _) => const UtopiaDivider(),
      itemBuilder: (context, index) =>
          _buildLoaderRow(context, visibleEntries, index, isLast: index == loaderRowCount - 1),
    );
  }

  Widget _buildLoaderRow(
    BuildContext context,
    IList<UtopiaTableEntry<T>> visibleEntries,
    int index, {
    required bool isLast,
  }) {
    return utopiaTableRowShell(
      context,
      isOdd: index.isOdd,
      isLast: isLast,
      child: Row(
        children: [
          for (final entry in visibleEntries)
            entry.wrapTableCell(
              Padding(
                padding: UtopiaTable.itemPadding,
                // Aligned like the real cell, so a numeric column's placeholder
                // sits under its own header instead of jumping sides on load.
                child: Align(
                  alignment: entry.cellAlignment,
                  child: const FractionallySizedBox(
                    widthFactor: 0.6,
                    child: UtopiaLoadingBox(width: double.infinity, height: 12),
                  ),
                ),
              ),
            ),
          if (actionsBuilder != null)
            const Padding(
              padding: UtopiaTable.itemPadding,
              child: SizedBox(
                width: UtopiaTable.actionsWidth,
                child: UtopiaLoadingBox(width: double.infinity, height: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return SliverToBoxAdapter(child: emptyWidget ?? const UtopiaTableEmpty(title: 'No items'));
  }
}
