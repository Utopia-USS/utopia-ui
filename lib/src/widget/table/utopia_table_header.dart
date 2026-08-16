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
/// Sortable columns without [UtopiaTableEntry.sortOptions] carry a direction
/// caret - shown for the sorted column, faded in on hover for the rest - and
/// report taps via [onSortPressed]; columns with
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
    // (capped at medium - any heavier reads as too bold here), only a hair larger,
    // not the full section/page title size which renders too big and too heavy.
    // The style's own colour (the body tone) is kept on purpose - a column
    // label carrying the heading tone outweighs the data it labels.
    final body = context.textStyles.text;
    final style = body.copyWith(fontWeight: context.tokens.fontWeights.medium, fontSize: (body.fontSize ?? 14) + 1);
    return DecoratedBox(
      // The header owns the rule under itself, drawn in `colors.border` rather
      // than the lighter divider the rows separate with: search panel, headers
      // and data otherwise run together as one block, and the caesura between
      // labels and data has to outrank the lines inside the data.
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.border, width: context.theme.dividerThickness),
        ),
      ),
      child: Padding(
        // Full lg breathing room: rows scroll under this pinned row, so a tight
        // header reads as the table crowding itself.
        padding: EdgeInsets.symmetric(horizontal: context.spacing.lg, vertical: context.spacing.lg),
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
      ),
    );
  }

  Widget _buildHeaderItem(BuildContext context, UtopiaTableEntry<T> entry, TextStyle style) {
    final hasOptions = entry.sortOptions?.isNotEmpty ?? false;
    final isActiveColumn = entry.effectiveId != null && entry.effectiveId == currentSort?.columnId;
    final titleStyle = isActiveColumn ? style.copyWith(color: context.colors.accent) : style;

    // Built per pointer state: the sort caret of a column that is merely
    // sortable stays invisible until the pointer arrives (see [_buildSortCaret]).
    //
    // On a numeric column the caret leads instead of trails, so the label's own
    // trailing edge stays flush with the digits underneath it - the caret would
    // otherwise push the label a caret's width off its column.
    Widget buildTitleRow(BuildContext context, {required bool hovering}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry.isSortable && !hasOptions && entry.numeric)
          _buildSortCaret(context, active: isActiveColumn, hovering: hovering, leading: true),
        Flexible(
          child: Text(entry.title ?? '', style: titleStyle, overflow: TextOverflow.ellipsis),
        ),
        if (entry.isSortable && !hasOptions && !entry.numeric)
          _buildSortCaret(context, active: isActiveColumn, hovering: hovering, leading: false),
        if (hasOptions) _buildDropdownIndicator(context, active: isActiveColumn),
        if (entry.tooltip != null) _buildTooltip(context, entry.tooltip!),
      ],
    );

    if (hasOptions) {
      return UtopiaOverlayAnchor(
        matchTriggerWidth: false,
        triggerBuilder: (context, open) =>
            _buildHeaderTrigger(context, entry, onTap: open, childBuilder: buildTitleRow),
        overlayBuilder: (context, close) => _buildSortOptionsMenu(context, entry, close),
      );
    }
    if (!entry.isSortable) {
      return Padding(
        padding: UtopiaTable.itemPadding,
        child: Align(alignment: entry.cellAlignment, heightFactor: 1, child: buildTitleRow(context, hovering: false)),
      );
    }
    return _buildHeaderTrigger(context, entry, onTap: () => onSortPressed?.call(entry), childBuilder: buildTitleRow);
  }

  /// Wraps a sortable column title as a click target with a hover pill that
  /// hugs the title + indicator instead of stretching across the whole cell
  /// (the cell wrap hands the header a tight width, so the pill must be
  /// shrink-wrapped through an [Align]). The pill sits on the same side as the
  /// column's data ([UtopiaTableEntryCellExtension.cellAlignment]), and its own
  /// side padding is pulled out of the cell inset so the title keeps lining up
  /// with the row cells.
  Widget _buildHeaderTrigger(
    BuildContext context,
    UtopiaTableEntry<T> entry, {
    required VoidCallback onTap,
    required Widget Function(BuildContext context, {required bool hovering}) childBuilder,
  }) {
    final pillInset = context.spacing.sm;
    final sideInset = (UtopiaTable.itemPadding.left - pillInset).clamp(0.0, double.infinity);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sideInset),
      child: Align(
        alignment: entry.cellAlignment,
        heightFactor: 1,
        child: GestureDetector(
          onTap: onTap,
          child: _HoverHighlight(
            childBuilder: (context, {required hovering}) => Padding(
              padding: EdgeInsets.symmetric(horizontal: pillInset),
              child: childBuilder(context, hovering: hovering),
            ),
          ),
        ),
      ),
    );
  }

  /// Sort affordance for a plain toggle column: a single caret stating which
  /// way the column is ordered - up for ascending, down for descending.
  ///
  /// Only the sorted column speaks at rest, in the accent tone that already
  /// marks its label; a column that is merely sortable stays silent and fades a
  /// muted caret in under the pointer, so a table of sortable columns is a row
  /// of labels rather than a row of arrows. The slot keeps its width in every
  /// state, so nothing shifts when the caret appears.
  Widget _buildSortCaret(BuildContext context, {required bool active, required bool hovering, required bool leading}) {
    final tokens = context.tokens;
    // Off-scale on purpose: a caret at the next step up (x*4) outweighs the
    // 13px label it sits next to.
    final size = tokens.x * 3.5;
    final descending = active && (currentSort?.descending ?? false);
    return Padding(
      padding: leading ? EdgeInsets.only(right: context.spacing.xxs) : EdgeInsets.only(left: context.spacing.xxs),
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedOpacity(
          duration: tokens.durations.xs,
          opacity: active || hovering ? 1 : 0,
          child: Icon(
            descending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: size,
            color: active ? context.colors.accent : context.colors.hint,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownIndicator(BuildContext context, {required bool active}) {
    return Padding(
      padding: EdgeInsets.only(left: context.spacing.xxs),
      child: Icon(Icons.arrow_drop_down, size: 18, color: active ? context.colors.accent : context.colors.hint),
    );
  }

  Widget _buildTooltip(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.only(left: context.spacing.xs),
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
      padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
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
    final fontWeights = context.tokens.fontWeights;
    final style = context.textStyles.text.copyWith(
      color: isActive ? context.colors.text : context.colors.hint,
      fontWeight: isActive ? fontWeights.semiBold : fontWeights.regular,
    );
    // Same hover treatment as UtopiaDropdownField's options: a flat themed
    // hover fill, no ink splash. The Material carries the active fill so the
    // InkWell's hover highlight still paints on top of it.
    return Material(
      color: isActive ? context.colors.hover : Colors.transparent,
      child: InkWell(
        onTap: () {
          onSortSelected?.call((columnId: option.id, descending: descending));
          close();
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: context.colors.hover,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.lg, vertical: context.spacing.md),
          child: Text('${option.label} ${descending ? 'descending' : 'ascending'}', style: style),
        ),
      ),
    );
  }
}

/// Hover chrome for a sortable column-header trigger: a soft themed fill
/// (rounded like the sidebar's icon button) plus the click cursor.
///
/// The pointer state is handed back to [childBuilder] as well, so the column's
/// sort caret fades in with the same gesture that lights the pill instead of
/// needing a second [MouseRegion] of its own.
class _HoverHighlight extends HookWidget {
  final Widget Function(BuildContext context, {required bool hovering}) childBuilder;

  const _HoverHighlight({required this.childBuilder});

  @override
  Widget build(BuildContext context) {
    final hover = context.colors.hover;
    final hovering = useState<bool>(false);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => hovering.value = true,
      onExit: (_) => hovering.value = false,
      child: AnimatedContainer(
        duration: context.tokens.durations.xs,
        decoration: BoxDecoration(
          // Fade within the hover colour's own hue: animating from
          // Colors.transparent (black at zero alpha) flashes dark grey
          // mid-transition.
          color: hovering.value ? hover : hover.withValues(alpha: 0),
          borderRadius: context.radius.mdAll,
        ),
        child: childBuilder(context, hovering: hovering.value),
      ),
    );
  }
}
