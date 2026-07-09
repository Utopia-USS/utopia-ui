import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/overlay/utopia_overlay_anchor.dart';
import 'package:utopia_ui/src/widget/table/utopia_table.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_cell.dart';
import 'package:utopia_ui/src/widget/table/utopia_table_entry.dart';

/// The column-header row that sits inside the table card's pinned header,
/// above the divider and the rows. Columns line up with `UtopiaTableItem`'s
/// cells via the shared [UtopiaTableEntryCellExtension.wrapTableCell] sizing.
///
/// Sortable columns without [UtopiaTableEntry.sortOptions] show a plain toggle
/// indicator and report taps via [onSortPressed]; columns with
/// [UtopiaTableEntry.sortOptions] show a dropdown (built on [UtopiaOverlayAnchor])
/// listing each option ascending/descending and report the pick via
/// [onSortSelected]. [UtopiaTableEntry.tooltip] renders as an info icon next to
/// the title.
class UtopiaTableHeader<T> extends StatelessWidget {
  /// The columns to render, in display order.
  final IList<UtopiaTableEntry<T>> entries;

  /// The column currently driving sort order, if any.
  final UtopiaTableSort? currentSort;

  /// Called when a sortable column without [UtopiaTableEntry.sortOptions] is
  /// pressed.
  final void Function(UtopiaTableEntry<T> entry)? onSortPressed;

  /// Called when an entry is picked from a [UtopiaTableEntry.sortOptions]
  /// dropdown.
  final void Function(UtopiaTableSort sort)? onSortSelected;

  /// Whether the row reserves trailing space for an actions cell, matching
  /// `UtopiaTableItem`'s actions column.
  final bool hasActions;

  const UtopiaTableHeader({
    super.key,
    required this.entries,
    required this.currentSort,
    required this.onSortPressed,
    required this.onSortSelected,
    required this.hasActions,
  });

  @override
  Widget build(BuildContext context) {
    // Column headers are a restrained take on the row data: same medium weight
    // (capped at w500 - any heavier reads as too bold here), only a hair larger,
    // not the full section/page title size which renders too big and too heavy.
    final body = context.textStyles.text;
    final style = body.copyWith(
      color: context.colors.text,
      fontWeight: FontWeight.w500,
      fontSize: (body.fontSize ?? 14) + 1,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          for (final entry in entries) entry.wrapTableCell(_buildHeaderItem(context, entry, style)),
          if (hasActions)
            const Padding(
              padding: UtopiaTable.itemPadding,
              child: SizedBox(width: UtopiaTable.actionsWidth),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(BuildContext context, UtopiaTableEntry<T> entry, TextStyle style) {
    final hasOptions = entry.sortOptions?.isNotEmpty ?? false;
    final isActiveColumn = entry.effectiveId != null && entry.effectiveId == currentSort?.columnId;
    final titleStyle = isActiveColumn ? style.copyWith(color: context.colors.accent) : style;

    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry.isSortable && !hasOptions) _buildSortIndicator(context, entry),
        Flexible(
          child: Text(entry.title ?? '', style: titleStyle, overflow: TextOverflow.ellipsis),
        ),
        if (hasOptions) _buildDropdownIndicator(context, active: isActiveColumn),
        if (entry.tooltip != null) _buildTooltip(context, entry.tooltip!),
      ],
    );
    final content = Padding(padding: UtopiaTable.itemPadding, child: titleRow);

    if (hasOptions) {
      return UtopiaOverlayAnchor(
        matchTriggerWidth: false,
        triggerBuilder: (context, open) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(onTap: open, child: content),
        ),
        overlayBuilder: (context, close) => _buildSortOptionsMenu(context, entry, close),
      );
    }
    if (!entry.isSortable) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: () => onSortPressed?.call(entry), child: content),
    );
  }

  Widget _buildSortIndicator(BuildContext context, UtopiaTableEntry<T> entry) {
    final isCurrent = entry.effectiveId != null && entry.effectiveId == currentSort?.columnId;
    final activeColor = context.colors.text;
    final inactiveColor = context.colors.hint;
    final upActive = isCurrent && currentSort!.descending;
    final downActive = isCurrent && !currentSort!.descending;

    Widget arrow(IconData icon, Alignment alignment, {required bool active}) => Align(
      alignment: alignment,
      child: Icon(icon, size: 16, color: active ? activeColor : inactiveColor),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 16,
        height: 22,
        child: Stack(
          children: [
            arrow(Icons.keyboard_arrow_up_rounded, const Alignment(0, -0.6), active: upActive),
            arrow(Icons.keyboard_arrow_down_rounded, const Alignment(0, 0.6), active: downActive),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownIndicator(BuildContext context, {required bool active}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Icon(Icons.arrow_drop_down, size: 18, color: active ? context.colors.accent : context.colors.hint),
    );
  }

  Widget _buildTooltip(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: message,
        child: Icon(Icons.info_outline, size: 14, color: context.colors.hint),
      ),
    );
  }

  /// The dropdown popup for a [UtopiaTableEntry.sortOptions] column: each option
  /// listed once ascending and once descending.
  Widget _buildSortOptionsMenu(BuildContext context, UtopiaTableEntry<T> entry, VoidCallback close) {
    final options = entry.sortOptions!;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        for (final option in options) ...[
          _buildSortOption(context, option, descending: false, close: close),
          _buildSortOption(context, option, descending: true, close: close),
        ],
      ],
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    UtopiaTableSortOption<T> option, {
    required bool descending,
    required VoidCallback close,
  }) {
    final isActive = currentSort?.columnId == option.id && currentSort?.descending == descending;
    final style = context.textStyles.text.copyWith(
      color: isActive ? context.colors.text : context.colors.hint,
      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          onSortSelected?.call((columnId: option.id, descending: descending));
          close();
        },
        child: Container(
          color: isActive ? context.colors.hover : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text('${option.label} ${descending ? 'descending' : 'ascending'}', style: style),
        ),
      ),
    );
  }
}
