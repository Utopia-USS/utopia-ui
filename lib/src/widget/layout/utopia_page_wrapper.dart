import 'package:flutter/material.dart';
import 'package:utopia_ui/src/theme/utopia_tokens.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/layout/utopia_breakpoints.dart';

/// Responsive size class derived from the available width, not the screen size.
///
/// Because [UtopiaPageWrapper] resolves the type from local [BoxConstraints], it
/// composes inside sub-regions (the management overlay, a dialog, a column)
/// and not only at the top of the screen.
enum UtopiaPageType {
  /// Narrowest size class - below [UtopiaBreakpoints.tabletMin].
  mobile,

  /// Mid-width size class - between [UtopiaBreakpoints.tabletMin] and
  /// [UtopiaBreakpoints.webMin].
  tablet,

  /// Widest size class - at or above [UtopiaBreakpoints.webMin].
  web,
}

extension UtopiaPageTypeX on UtopiaPageType {
  /// Column count for a chunked/grid layout: one more column per size class,
  /// starting from [base] on mobile.
  int chunkedSize(int base) => switch (this) {
    UtopiaPageType.mobile => base,
    UtopiaPageType.tablet => base + 1,
    UtopiaPageType.web => base + 2,
  };

  /// Whether this is [UtopiaPageType.mobile].
  bool get isMobile => this == UtopiaPageType.mobile;

  /// Whether this is [UtopiaPageType.tablet].
  bool get isTablet => this == UtopiaPageType.tablet;

  /// Whether this is [UtopiaPageType.web].
  bool get isWeb => this == UtopiaPageType.web;
}

/// Resolves a [UtopiaPageType] from the available width and exposes it to the
/// subtree both through the [builder] callback and through `context.pageType`.
///
/// A responsive page wrapper: a plain [LayoutBuilder] resolves the size class
/// and a private [InheritedWidget] exposes it to the subtree, so the wrapper
/// carries no extra dependency.
class UtopiaPageWrapper extends StatelessWidget {
  /// Builds the subtree, receiving the [UtopiaPageType] resolved from the
  /// available width.
  final Widget Function(BuildContext context, UtopiaPageType pageType) builder;

  /// When true, caps the content width and centers it at the top - matching the
  /// shell's constrained reading width.
  final bool isConstrained;

  /// Creates a responsive page wrapper.
  const UtopiaPageWrapper({super.key, required this.builder, this.isConstrained = false});

  /// The width applied to the content area when [isConstrained] is `true`.
  static const double maxConstrainedWidth = 1340;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageType = resolveType(constraints.maxWidth, context.tokens.breakpoints);
        final child = _UtopiaPageScope(
          pageType: pageType,
          child: Builder(builder: (context) => builder(context, pageType)),
        );
        if (!isConstrained) return child;
        return Container(
          constraints: const BoxConstraints(maxWidth: maxConstrainedWidth),
          alignment: Alignment.topCenter,
          child: child,
        );
      },
    );
  }

  /// Maps a raw width to a [UtopiaPageType] using [breakpoints] - the ambient
  /// theme's `context.tokens.breakpoints` inside the wrapper, or the
  /// [UtopiaBreakpoints]-matching defaults when called without one.
  static UtopiaPageType resolveType(double width, [UtopiaBreakpointTokens breakpoints = const UtopiaBreakpointTokens()]) {
    if (width < breakpoints.tabletMin) return UtopiaPageType.mobile;
    if (width < breakpoints.webMin) return UtopiaPageType.tablet;
    return UtopiaPageType.web;
  }
}

/// Distributes the [UtopiaPageType] resolved by the nearest [UtopiaPageWrapper] to
/// its subtree, mirroring the `UtopiaTheme` `InheritedWidget` pattern.
class _UtopiaPageScope extends InheritedWidget {
  final UtopiaPageType pageType;

  const _UtopiaPageScope({required this.pageType, required super.child});

  @override
  bool updateShouldNotify(_UtopiaPageScope oldWidget) => pageType != oldWidget.pageType;
}

extension UtopiaPageTypeContextX on BuildContext {
  /// The [UtopiaPageType] provided by the nearest [UtopiaPageWrapper] ancestor.
  ///
  /// Throws a [FlutterError] if no [UtopiaPageWrapper] ancestor exists - matching
  /// the previous `package:provider`-based behavior, which threw a
  /// `ProviderNotFoundException` in the same situation.
  UtopiaPageType get pageType {
    final scope = dependOnInheritedWidgetOfExactType<_UtopiaPageScope>();
    if (scope == null) {
      throw FlutterError(
        'context.pageType was called with a context that does not contain a UtopiaPageWrapper.\n'
        'No UtopiaPageWrapper ancestor could be found starting from the context that was passed to '
        'context.pageType. This can happen if the context you used comes from a widget above the '
        'UtopiaPageWrapper.',
      );
    }
    return scope.pageType;
  }
}
