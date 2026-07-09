import 'package:flutter/widgets.dart';

/// Scrollable layout with fixed content on the bottom.
///
/// Designed for long screens (usually forms with multiple fields) with some
/// always-visible, fixed content on the bottom (usually a submit button).
/// The [content] and [bottom] widgets are separated by a semi-transparent
/// fade bar, so [bottom] appears laid out "above" the [content]. When
/// [content] scrolls to its end, the fade bar disappears so the last part of
/// it is fully visible.
///
/// Two constructors: [UtopiaFormLayout.simple] wraps [content] in a
/// [SingleChildScrollView]; [UtopiaFormLayout.raw] takes [content] as-is, for
/// callers that bring their own scrollable (e.g. a [CustomScrollView]).
///
/// Vendored from `utopia_widgets`' `FormLayout` - `utopia_widgets` is
/// expected to depend on this package in the future, so the dependency cannot
/// point the other way.
class UtopiaFormLayout extends StatefulWidget {
  /// The fill behind [content] and the color the fade bar fades into.
  final Color backgroundColor;

  /// Height of the fade bar separating [content] from [bottom].
  final double fadeBarHeight;

  /// Duration of the fade bar's show/hide animation.
  final Duration fadeDuration;

  /// The scrollable body above [bottom].
  final Widget content;

  /// The fixed content pinned below [content].
  final Widget bottom;

  /// Simple variant - wraps [content] in a [SingleChildScrollView].
  UtopiaFormLayout.simple({
    super.key,
    required this.backgroundColor,
    this.fadeBarHeight = 16,
    this.fadeDuration = const Duration(milliseconds: 100),
    required Widget content,
    required this.bottom,
  }) : content = SingleChildScrollView(child: content);

  /// Raw variant - [content] is used as-is and must provide its own
  /// scrollable, whose notifications drive the fade bar.
  const UtopiaFormLayout.raw({
    super.key,
    required this.backgroundColor,
    this.fadeBarHeight = 16,
    this.fadeDuration = const Duration(milliseconds: 100),
    required this.content,
    required this.bottom,
  });

  @override
  State<UtopiaFormLayout> createState() => _UtopiaFormLayoutState();
}

class _UtopiaFormLayoutState extends State<UtopiaFormLayout> {
  bool isFadeBarVisible = true;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildContent(),
                Align(alignment: Alignment.bottomCenter, child: _buildFadeBar()),
              ],
            ),
          ),
          widget.bottom,
        ],
      ),
    );
  }

  Widget _buildFadeBar() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: isFadeBarVisible ? 1 : 0,
        duration: widget.fadeDuration,
        child: Container(
          height: widget.fadeBarHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [widget.backgroundColor.withValues(alpha: 0), widget.backgroundColor],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final current = notification.metrics.pixels;
        final max = notification.metrics.maxScrollExtent - widget.fadeBarHeight;
        if (!isFadeBarVisible && current < max) setState(() => isFadeBarVisible = true);
        if (isFadeBarVisible && current >= max) setState(() => isFadeBarVisible = false);
        return false;
      },
      child: widget.content,
    );
  }
}
