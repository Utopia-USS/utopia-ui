import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/widget/layout/utopia_breakpoints.dart';

/// The panel pinned above a `UtopiaTable`'s column headers: a search field slot,
/// a row of filter widgets, and trailing actions (refresh, create, ...).
///
/// Purely a layout shell - the caller supplies fully-built widgets for
/// [searchField], [filters] and [actions]; this widget only owns the
/// responsive inline/stacked arrangement and spacing between them.
class UtopiaTableSearchPanel extends StatelessWidget {
  /// The search input slot, if any - typically a `UtopiaSearchField` wired to
  /// the caller's own search state.
  final Widget? searchField;

  /// Additional filter controls: laid out inline next to the search field on
  /// wide layouts, wrapped beneath the search row on narrow ones.
  final List<Widget> filters;

  /// Trailing actions (e.g. refresh, create) that stay next to the search
  /// field regardless of layout.
  final List<Widget> actions;

  const UtopiaTableSearchPanel({super.key, this.searchField, this.filters = const [], this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Web (wide content) lays search, filters and actions out in a
        // single row; tablet / mobile stacks the filters under the
        // search + actions row.
        final inline = constraints.maxWidth >= UtopiaBreakpoints.webMin;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: inline ? _buildInlineRow() : _buildStacked(),
        );
      },
    );
  }

  Widget _buildInlineRow() {
    return Row(
      children: [
        Expanded(child: searchField ?? const SizedBox.shrink()),
        for (final filter in filters) ...[const SizedBox(width: 12), filter],
        for (final action in actions) ...[const SizedBox(width: 12), action],
      ],
    );
  }

  Widget _buildStacked() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: searchField ?? const SizedBox.shrink()),
            for (final action in actions) ...[const SizedBox(width: 12), action],
          ],
        ),
        if (filters.isNotEmpty) ...[const SizedBox(height: 12), Wrap(spacing: 12, runSpacing: 12, children: filters)],
      ],
    );
  }
}
