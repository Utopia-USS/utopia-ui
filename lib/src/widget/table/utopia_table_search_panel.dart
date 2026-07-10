import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/theme/utopia_tokens.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

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
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Web (wide content) lays search, filters and actions out in a
        // single row; tablet / mobile stacks the filters under the
        // search + actions row.
        final inline = constraints.maxWidth >= context.tokens.breakpoints.webMin;
        return Padding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, spacing.md),
          child: inline ? _buildInlineRow(spacing) : _buildStacked(spacing),
        );
      },
    );
  }

  Widget _buildInlineRow(UtopiaSpacingTokens spacing) {
    return Row(
      children: [
        Expanded(child: searchField ?? const SizedBox.shrink()),
        for (final filter in filters) ...[SizedBox(width: spacing.md), filter],
        for (final action in actions) ...[SizedBox(width: spacing.md), action],
      ],
    );
  }

  Widget _buildStacked(UtopiaSpacingTokens spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: searchField ?? const SizedBox.shrink()),
            for (final action in actions) ...[SizedBox(width: spacing.md), action],
          ],
        ),
        if (filters.isNotEmpty) ...[
          SizedBox(height: spacing.md),
          Wrap(spacing: spacing.md, runSpacing: spacing.md, children: filters),
        ],
      ],
    );
  }
}
