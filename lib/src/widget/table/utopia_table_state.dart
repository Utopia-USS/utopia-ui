import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_entry.dart';

/// Client-side search/sort state for a `UtopiaTable`, produced by
/// [useUtopiaTableState].
///
/// The table itself stays fully controlled (charter rule); this is an
/// optional convenience for callers who don't need server-side filtering or
/// sorting.
class UtopiaTableState<T> {
  /// The rows to render: search-filtered then sorted. `null` iff the `rows`
  /// passed to [useUtopiaTableState] were `null` (still loading).
  final IList<T>? visibleRows;

  /// The current sort, if any.
  final UtopiaTableSort? currentSort;

  /// The live search text field state - feed it to a search input (e.g.
  /// `UtopiaSearchField`) or read/write `.value` directly.
  final FieldState searchState;

  /// Pass to `UtopiaTable.onSortPressed`: toggles a plain sortable column
  /// between ascending and descending, starting ascending.
  final void Function(UtopiaTableEntry<T> entry) onSortPressed;

  /// Pass to `UtopiaTable.onSortSelected`: applies an explicit sort picked from
  /// a column's `sortOptions` dropdown.
  final void Function(UtopiaTableSort sort) onSortSelected;

  const UtopiaTableState({
    required this.visibleRows,
    required this.currentSort,
    required this.searchState,
    required this.onSortPressed,
    required this.onSortSelected,
  });
}

/// Client-side search/sort convenience for a `UtopiaTable<T>`.
///
/// Search: multi-word AND match - the query is lower-cased and split on
/// whitespace, and a row matches when every word is a substring of at least
/// one `isSearchable` entry's [UtopiaTableEntry.searchBy] value for that row.
///
/// Sort: pressing a sortable column's header ([UtopiaTableState.onSortPressed])
/// starts ascending, then toggles ascending/descending on repeated presses of
/// the same column; picking a `sortOptions` entry
/// ([UtopiaTableState.onSortSelected]) applies that explicit ordering. The
/// comparator used is [UtopiaTableEntry.sortBy] when `UtopiaTableSort.columnId`
/// matches the entry's [UtopiaTableEntry.effectiveId], otherwise the
/// [UtopiaTableSortOption.sortBy] of the matching option. Rows whose comparator
/// value is `null` always sort last, regardless of direction. If neither
/// resolves to a comparator (e.g. a server-side-only sortable column), the
/// current row order is kept - callers driving server-side sorting should
/// use [UtopiaTableState.currentSort] to refetch instead.
///
/// [initialSortColumnId] applies an initial ascending sort matching either an
/// entry's [UtopiaTableEntry.effectiveId] or a [UtopiaTableSortOption.id].
///
/// Keep [entries] stable across builds (hoist it to a field or memoize it):
/// the filtered/sorted rows are memoized on the list's identity-based
/// equality, so an entries list rebuilt inline on every build silently
/// defeats that memoization and re-runs the full filter + sort each rebuild.
UtopiaTableState<T> useUtopiaTableState<T>({
  required IList<T>? rows,
  required IList<UtopiaTableEntry<T>> entries,
  String? initialSortColumnId,
}) {
  final searchState = useFieldState();
  final sortState = useStateLazy<UtopiaTableSort?>(() => _initialSort(entries, initialSortColumnId));

  void onSortPressed(UtopiaTableEntry<T> entry) {
    final columnId = entry.effectiveId;
    if (columnId == null) return;
    final current = sortState.value;
    final matchesCurrent = current?.columnId == columnId;
    sortState.value = (columnId: columnId, descending: matchesCurrent && !current!.descending);
  }

  void onSortSelected(UtopiaTableSort sort) => sortState.value = sort;

  final visibleRows = useMemoized(
    () => _visibleRows(rows: rows, entries: entries, query: searchState.value, sort: sortState.value),
    [rows, entries, searchState.value, sortState.value],
  );

  return UtopiaTableState(
    visibleRows: visibleRows,
    currentSort: sortState.value,
    searchState: searchState,
    onSortPressed: onSortPressed,
    onSortSelected: onSortSelected,
  );
}

UtopiaTableSort? _initialSort<T>(IList<UtopiaTableEntry<T>> entries, String? initialSortColumnId) {
  if (initialSortColumnId == null) return null;
  for (final entry in entries) {
    final matches =
        entry.effectiveId == initialSortColumnId ||
        (entry.sortOptions?.any((option) => option.id == initialSortColumnId) ?? false);
    if (matches) return (columnId: initialSortColumnId, descending: false);
  }
  return null;
}

IList<T>? _visibleRows<T>({
  required IList<T>? rows,
  required IList<UtopiaTableEntry<T>> entries,
  required String query,
  required UtopiaTableSort? sort,
}) {
  final source = rows;
  if (source == null) return null;

  final words = query.trim().toLowerCase().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  final searchable = entries.where((entry) => entry.isSearchable).toList();
  Iterable<T> filtered = source;
  if (words.isNotEmpty) {
    filtered = filtered.where((row) {
      if (searchable.isEmpty) return false;
      return words.every(
        (word) => searchable.any((entry) => (entry.searchBy!(row)?.toLowerCase() ?? '').contains(word)),
      );
    });
  }

  final result = filtered.toList();
  if (sort != null) {
    final comparator = _resolveComparator(entries, sort.columnId);
    if (comparator != null) {
      result.sort((a, b) {
        final valueA = comparator(a);
        final valueB = comparator(b);
        if (valueA == null && valueB == null) return 0;
        if (valueA == null) return 1;
        if (valueB == null) return -1;
        final comparison = valueA.compareTo(valueB);
        return sort.descending ? -comparison : comparison;
      });
    }
  }
  return IList(result);
}

Comparable<Object?>? Function(T row)? _resolveComparator<T>(IList<UtopiaTableEntry<T>> entries, String columnId) {
  for (final entry in entries) {
    if (entry.effectiveId == columnId) return entry.sortBy;
  }
  for (final entry in entries) {
    final options = entry.sortOptions;
    if (options == null) continue;
    for (final option in options) {
      if (option.id == columnId) return option.sortBy;
    }
  }
  return null;
}
