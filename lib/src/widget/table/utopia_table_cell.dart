import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_entry.dart';

/// Lays out a single table cell so the column header and the row cells line up.
///
/// Both the table's internal header row and item rows wrap their content
/// through [wrapTableCell], so a column's sizing rule lives in one place.
extension UtopiaTableEntryCellExtension on UtopiaTableEntry<dynamic> {
  /// Width used for a fixed column ([UtopiaTableEntry.flex] == null) when no
  /// [UtopiaTableEntry.width] is provided. Keeps the header and rows aligned
  /// without forcing every caller to pick a width.
  static const double defaultFixedColumnWidth = 72;

  /// Wraps [child] for placement directly inside the table row's `Row`.
  ///
  /// Flexing columns ([UtopiaTableEntry.flex] != null) share the row width via
  /// [Expanded]; fixed columns ([UtopiaTableEntry.flex] == null) get a constant
  /// width ([UtopiaTableEntry.width] or [defaultFixedColumnWidth]) and never
  /// stretch.
  Widget wrapTableCell(Widget child) => flex == null
      ? SizedBox(width: width ?? defaultFixedColumnWidth, child: child)
      : Expanded(flex: flex!, child: child);

  /// Where the column's content sits inside its cell box: the trailing edge
  /// for a [UtopiaTableEntry.numeric] column (digits are read from their last
  /// place, so they line up on the right), the leading edge otherwise.
  ///
  /// Shared by the header and the row cells, so a numeric column's label
  /// stands over its own values instead of drifting to the other side.
  Alignment get cellAlignment => numeric ? Alignment.centerRight : Alignment.centerLeft;
}
