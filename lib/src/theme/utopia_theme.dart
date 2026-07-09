import 'package:flutter/widgets.dart';
import 'package:utopia_ui/src/theme/utopia_theme_data.dart';

/// Applies a [UtopiaThemeData] to its subtree.
///
/// Descendants read the ambient theme with [UtopiaTheme.of] (or the
/// `context.theme` extension), which falls back to [UtopiaThemeData.defaultTheme]
/// when no [UtopiaTheme] is found - components work zero-config, with or without
/// an ancestor [UtopiaTheme].
class UtopiaTheme extends InheritedWidget {
  /// The theme data made available to descendants.
  final UtopiaThemeData data;

  const UtopiaTheme({super.key, required this.data, required super.child});

  /// The [UtopiaThemeData] from the closest [UtopiaTheme] ancestor, or
  /// [UtopiaThemeData.defaultTheme] if there is none.
  static UtopiaThemeData of(BuildContext context) => maybeOf(context) ?? UtopiaThemeData.defaultTheme;

  /// The [UtopiaThemeData] from the closest [UtopiaTheme] ancestor, or `null` if
  /// there is none.
  static UtopiaThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UtopiaTheme>()?.data;

  /// Like [of], but WITHOUT registering a rebuild dependency - for one-shot
  /// reads outside `build` (event handlers, route builders), where
  /// subscribing the calling element to theme changes would cause needless
  /// rebuilds.
  static UtopiaThemeData read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<UtopiaTheme>()?.data ?? UtopiaThemeData.defaultTheme;

  /// Re-attaches the ambient theme across a route boundary: captures the
  /// theme resolved at [from] and wraps [child] in a [UtopiaTheme] carrying it.
  ///
  /// Routes (`showDialog`, `Navigator.push`) root at the app `Navigator`,
  /// outside any subtree-scoped [UtopiaTheme] - wrap the route's child in this
  /// so the pushed screen keeps the caller's theme instead of falling back
  /// to [UtopiaThemeData.defaultTheme].
  static Widget captured(BuildContext from, {required Widget child}) => UtopiaTheme(data: read(from), child: child);

  @override
  bool updateShouldNotify(UtopiaTheme oldWidget) => data != oldWidget.data;
}
