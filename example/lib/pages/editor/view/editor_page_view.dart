import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../../../widgets/content_card.dart';
import '../../../widgets/page_scaffold.dart';
import '../state/editor_page_state.dart';

/// The editor's View: the article form in [ContentCard]s. Stateless - every
/// value and callback comes off [state].
class EditorPageView extends StatelessWidget {
  /// The page state, built by `useEditorPageState`.
  final EditorPageState state;

  /// Creates the editor view.
  const EditorPageView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Editor',
      subtitle: 'Fields, pickers, switches and the Publish action inside the publishing card.',
      child: PageBody(
        slivers: [
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Desktop pairs the two cards side by side so neither
                // stretches across the whole reading width; narrow layouts
                // stack them.
                final inline = constraints.maxWidth >= context.tokens.breakpoints.webMin;
                final articleCard = _ArticleCard(state: state);
                if (inline) {
                  // IntrinsicHeight + stretch: both cards render at the taller
                  // card's height, and the publishing card's footer (Publish)
                  // pins to the shared bottom edge.
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: articleCard),
                        const SizedBox(width: 24),
                        Expanded(child: _PublishingCard(state: state, pinFooter: true)),
                      ],
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    articleCard,
                    const SizedBox(height: 24),
                    _PublishingCard(state: state, pinFooter: false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Text fields, the category dropdown and the date picker on one card.
class _ArticleCard extends StatelessWidget {
  final EditorPageState state;

  const _ArticleCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final fieldGap = SizedBox(height: context.spacing.lg);
    return ContentCard(
      title: 'Article',
      subtitle: 'Text fields, a dropdown and the date picker on one card.',
      children: [
        UtopiaTextField(
          value: state.title,
          label: const Text('Title'),
          error: state.canPublish ? null : const Text('Required field'),
          onChanged: state.onTitleChanged,
        ),
        fieldGap,
        UtopiaTextField(
          value: state.body,
          lines: 6,
          label: const Text('Body'),
          hint: const Text('Write something worth publishing...'),
          onChanged: state.onBodyChanged,
        ),
        fieldGap,
        UtopiaDropdownField<String>(
          label: 'Category',
          value: state.category,
          values: const ['Engineering', 'Design', 'Product', 'Announcements'],
          valueLabelBuilder: (value) => value,
          onChanged: state.onCategoryChanged,
        ),
        fieldGap,
        UtopiaDatePicker(
          label: 'Publish date',
          date: state.publishDate,
          onDateChanged: state.onPublishDateChanged,
        ),
      ],
    );
  }
}

/// Chips, the check row, the advanced block and the Publish action.
class _PublishingCard extends StatelessWidget {
  final EditorPageState state;
  final bool pinFooter;

  const _PublishingCard({required this.state, required this.pinFooter});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fieldGap = SizedBox(height: context.spacing.lg);
    return ContentCard(
      title: 'Publishing',
      subtitle: 'Chips, a check row, the advanced block and the Publish action.',
      pinFooter: pinFooter,
      // Sized to its label (the confirm dialog's primary-action pattern), not
      // stretched across the card; pinned to the card's bottom edge when the
      // two cards render at equal heights.
      footer: IntrinsicWidth(
        child: UtopiaButton(
          dense: true,
          loading: state.isPublishing,
          isEnabled: state.canPublish,
          onTap: state.publish,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.xl),
            child: const Text('Publish'),
          ),
        ),
      ),
      children: [
        Text('Tags', style: context.textStyles.caption.copyWith(color: colors.hint)),
        SizedBox(height: context.spacing.sm),
        UtopiaChipList(
          labels: const ['flutter', 'design-system', 'theming', 'tables'].toIList(),
          maxLength: 3,
        ),
        fieldGap,
        UtopiaCheckRow(
          label: 'Show advanced options',
          selected: state.showAdvanced,
          onTap: state.toggleAdvanced,
        ),
        // Plain conditional, no reveal animation: the card grows and the
        // fields appear in the created space.
        if (state.showAdvanced) ...[
          fieldGap,
          UtopiaTextField(
            value: state.slug,
            label: const Text('Slug'),
            suffix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.link, size: 18),
            ),
            onChanged: state.onSlugChanged,
          ),
          fieldGap,
          UtopiaSwitchField(
            value: state.featured,
            title: 'Feature on the home page',
            onChanged: state.onFeaturedChanged,
          ),
          fieldGap,
          UtopiaSwitchField(
            value: state.comments,
            title: 'Allow comments',
            onChanged: state.onCommentsChanged,
          ),
        ],
      ],
    );
  }
}
