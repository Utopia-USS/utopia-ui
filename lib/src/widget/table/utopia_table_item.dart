import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/table/utopia_table.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_cell.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_entry.dart';

/// A single table row. Alternating tint and hover colour come from the theme;
/// the row grows to fit its content instead of clipping it - it uses
/// `BoxConstraints(minHeight: ...)` rather than a fixed height, so a cell
/// with taller content simply pushes the row taller. The last row rounds its
/// own bottom corners (cell content is inset, so a rounded fill matches the
/// card without an extra `ClipRRect` layer).
class UtopiaTableItem<T> extends HookWidget {
  /// The row's data.
  final T row;

  /// The row's position in the (already sorted/filtered) visible list -
  /// forwarded to [onRowPressed] and [actionsBuilder].
  final int index;

  /// The columns to render, in display order - must match the header's.
  final IList<UtopiaTableEntry<T>> entries;

  /// Builds a trailing actions cell for this row. `null` omits the column.
  final Widget Function(BuildContext context, T row, int index)? actionsBuilder;

  /// Whether this is an odd-indexed row, for the alternating tint.
  final bool isOdd;

  /// Whether this is the last row, so its bottom corners round with the card.
  final bool isLast;

  /// Called when the row is tapped. `null` makes the row non-interactive.
  final void Function(T row, int index)? onRowPressed;

  const UtopiaTableItem({
    super.key,
    required this.row,
    required this.index,
    required this.entries,
    required this.isOdd,
    required this.isLast,
    required this.onRowPressed,
    this.actionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final hovering = useState<bool>(false);
    final pressable = onRowPressed != null;

    return MouseRegion(
      onEnter: (_) => hovering.value = true,
      onExit: (_) => hovering.value = false,
      cursor: pressable ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: pressable ? () => onRowPressed!(row, index) : null,
        child: utopiaTableRowShell(
          context,
          isOdd: isOdd,
          isLast: isLast,
          color: hovering.value ? context.colors.hover : null,
          child: Row(
            children: [
              for (final entry in entries)
                entry.wrapTableCell(
                  Padding(
                    padding: UtopiaTable.itemPadding,
                    // Cell text that doesn't set its own overflow ellipsizes instead of wrapping.
                    // A numeric column additionally gets tabular figures and trailing
                    // alignment here rather than in every cellBuilder: a cell style set by
                    // the caller still inherits both (TextStyle.merge keeps the ambient
                    // fontFeatures a Text's own style leaves unset).
                    child: DefaultTextStyle.merge(
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textAlign: entry.numeric ? TextAlign.right : null,
                      style: entry.numeric ? _numericCellStyle : null,
                      child: Align(alignment: entry.cellAlignment, child: entry.cellBuilder(context, row)),
                    ),
                  ),
                ),
              if (actionsBuilder != null)
                Padding(
                  padding: UtopiaTable.itemPadding,
                  child: SizedBox(width: UtopiaTable.actionsWidth, child: actionsBuilder!(context, row, index)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figure style for a [UtopiaTableEntry.numeric] column: tabular (fixed-advance)
/// digits, so every row's digits sit in the same vertical tracks and a column of
/// amounts can be compared by shape alone. Carries nothing else, so it merges
/// onto whatever style the cell's own text brings.
const TextStyle _numericCellStyle = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

/// The one place the row chrome is defined - alternating tint, min-height
/// (rows grow with content), row content padding and last-row corner rounding
/// - shared by the real [UtopiaTableItem] and `UtopiaTable`'s loading skeleton so
/// the two cannot drift apart. [color] overrides the tint (e.g. hover).
Widget utopiaTableRowShell(
  BuildContext context, {
  required bool isOdd,
  required bool isLast,
  Color? color,
  required Widget child,
}) {
  final theme = context.theme;
  return Container(
    constraints: BoxConstraints(minHeight: theme.tileHeight),
    padding: UtopiaTable.contentPadding,
    decoration: BoxDecoration(
      color: color ?? (isOdd ? context.colors.rowAlt : context.colors.surface),
      borderRadius: isLast
          ? BorderRadius.only(bottomLeft: theme.cardRadius.bottomLeft, bottomRight: theme.cardRadius.bottomRight)
          : null,
    ),
    child: child,
  );
}
