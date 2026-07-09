import 'package:flutter/widgets.dart';

/// Sort state of a `UtopiaTable`: which column (by [UtopiaTableEntry.effectiveId])
/// and which direction.
typedef UtopiaTableSort = ({String columnId, bool descending});

/// A named sort option for a column that exposes multiple orderings through
/// a dropdown instead of the plain toggle.
class UtopiaTableSortOption<T> {
  /// Identifier reported back through `UtopiaTableSort.columnId`.
  final String id;

  /// Human-readable label shown in the sort dropdown.
  final String label;

  /// Client-side comparator selector; `null` when sorting is handled
  /// externally (e.g. by a backend query).
  final Comparable<Object?>? Function(T row)? sortBy;

  const UtopiaTableSortOption({required this.id, required this.label, this.sortBy});
}

/// Declarative column of a `UtopiaTable`: header, cell renderer and optional
/// sort/search behavior, generic over the row type [T].
///
/// A column either flexes ([flex], the default constructor) or has a fixed
/// [width] ([UtopiaTableEntry.fixed]). The cell content is fully caller-defined
/// via [cellBuilder]; sorting and searching are opt-in per column.
class UtopiaTableEntry<T> {
  /// Stable identifier used in [UtopiaTableSort]; falls back to [title] via
  /// [effectiveId].
  final String? id;

  /// Column header text; `null` renders a blank header cell.
  final String? title;

  /// Optional info tooltip shown next to the header title.
  final String? tooltip;

  /// The column's share of the row width, like `Expanded.flex`.
  /// `null` makes this a fixed-width column sized by [width].
  final int? flex;

  /// Width of a fixed (non-flexing) column; ignored while [flex] is non-null.
  final double? width;

  /// Builds the cell content for a row. Keep it cheap - it runs per visible row.
  final Widget Function(BuildContext context, T row) cellBuilder;

  /// Client-side comparator selector enabling toggle-sort on this column.
  final Comparable<Object?>? Function(T row)? sortBy;

  /// Client-side text selector enabling search matching against this column.
  final String? Function(T row)? searchBy;

  /// When non-empty, the header shows a dropdown of named orderings instead
  /// of the plain asc/desc toggle.
  final List<UtopiaTableSortOption<T>>? sortOptions;

  /// Overrides sortability detection - set `true` for columns whose sorting
  /// is executed externally (backend queries) and thus have no [sortBy].
  final bool? sortable;

  const UtopiaTableEntry({
    required this.cellBuilder,
    this.id,
    this.title,
    this.tooltip,
    this.flex = 2,
    this.sortBy,
    this.searchBy,
    this.sortOptions,
    this.sortable,
  }) : width = null;

  /// A fixed-width, non-flexing column - for icons, avatars or badges that
  /// should not stretch.
  const UtopiaTableEntry.fixed({
    required this.cellBuilder,
    required this.width,
    this.id,
    this.title,
    this.tooltip,
    this.sortBy,
    this.searchBy,
    this.sortOptions,
    this.sortable,
  }) : flex = null;

  /// The identifier used in [UtopiaTableSort]: [id], falling back to [title].
  String? get effectiveId => id ?? title;

  /// Whether the header offers sorting - explicit [sortable] override, else
  /// derived from [sortBy]/[sortOptions] presence.
  bool get isSortable => sortable ?? (sortBy != null || (sortOptions?.isNotEmpty ?? false));

  /// Whether this column participates in client-side search.
  bool get isSearchable => searchBy != null;
}
