import 'package:utopia_hooks/utopia_hooks.dart';

/// All editor page state and behaviour: the article form's field values, the
/// advanced-block toggle, and the publish action. No widget imports - the
/// published-confirmation dialog is context work and arrives as a callback
/// from the Screen.
class EditorPageState {
  /// Article title; publishing is gated on it being non-blank.
  final String title;

  /// Updates [title] (`null` means the field was cleared).
  final void Function(String? value) onTitleChanged;

  /// Article body.
  final String body;

  /// Updates [body].
  final void Function(String? value) onBodyChanged;

  /// Selected category, if any.
  final String? category;

  /// Updates [category].
  final void Function(String? value) onCategoryChanged;

  /// Scheduled publish date, if any.
  final DateTime? publishDate;

  /// Updates [publishDate].
  final void Function(DateTime? value) onPublishDateChanged;

  /// URL slug (advanced block).
  final String slug;

  /// Updates [slug].
  final void Function(String? value) onSlugChanged;

  /// Whether the article is featured on the home page (advanced block).
  final bool featured;

  /// Updates [featured]. Positional bool: mirrors `UtopiaSwitchField.onChanged`.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool value) onFeaturedChanged;

  /// Whether comments are allowed (advanced block).
  final bool comments;

  /// Updates [comments]. Positional bool: mirrors `UtopiaSwitchField.onChanged`.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool value) onCommentsChanged;

  /// Whether the advanced block is revealed.
  final bool showAdvanced;

  /// Toggles [showAdvanced].
  final void Function() toggleAdvanced;

  /// Whether the publish submission is in flight - drives the button's
  /// loading indicator.
  final bool isPublishing;

  /// Whether publishing is currently allowed ([title] non-blank).
  final bool canPublish;

  /// Runs the (mock) publish submission, then shows the confirmation dialog.
  final void Function() publish;

  const EditorPageState({
    required this.title,
    required this.onTitleChanged,
    required this.body,
    required this.onBodyChanged,
    required this.category,
    required this.onCategoryChanged,
    required this.publishDate,
    required this.onPublishDateChanged,
    required this.slug,
    required this.onSlugChanged,
    required this.featured,
    required this.onFeaturedChanged,
    required this.comments,
    required this.onCommentsChanged,
    required this.showAdvanced,
    required this.toggleAdvanced,
    required this.isPublishing,
    required this.canPublish,
    required this.publish,
  });
}

/// Editor page state hook. [showPublishedDialog] is the Screen-built
/// confirmation dialog callback, invoked after a successful publish.
///
/// Publishing runs through [useSubmitState] - in-flight tracking and
/// duplicate-tap blocking come from the hook instead of a hand-rolled
/// boolean.
EditorPageState useEditorPageState({required Future<void> Function() showPublishedDialog}) {
  final title = useState('Designing with utopia_ui');
  final body = useState('');
  final category = useState<String?>('Engineering');
  final publishDate = useState<DateTime?>(DateTime(2026, 7, 14));
  final slug = useState('designing-with-utopia-ui');
  final featured = useState(true);
  final comments = useState(false);
  final showAdvanced = useState(false);
  final submitState = useSubmitState();

  Future<void> publish() async {
    if (submitState.inProgress) return;
    await submitState.run(() => Future<void>.delayed(const Duration(milliseconds: 900)));
    await showPublishedDialog();
  }

  return EditorPageState(
    title: title.value,
    onTitleChanged: (value) => title.value = value ?? '',
    body: body.value,
    onBodyChanged: (value) => body.value = value ?? '',
    category: category.value,
    onCategoryChanged: (value) => category.value = value,
    publishDate: publishDate.value,
    onPublishDateChanged: (value) => publishDate.value = value,
    slug: slug.value,
    onSlugChanged: (value) => slug.value = value ?? '',
    featured: featured.value,
    onFeaturedChanged: (value) => featured.value = value,
    comments: comments.value,
    onCommentsChanged: (value) => comments.value = value,
    showAdvanced: showAdvanced.value,
    toggleAdvanced: () => showAdvanced.value = !showAdvanced.value,
    isPublishing: submitState.inProgress,
    canPublish: title.value.trim().isNotEmpty,
    publish: publish,
  );
}
