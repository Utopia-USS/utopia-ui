import 'package:utopia_hooks/utopia_hooks.dart';

import '../theme.dart';

/// App-wide selected theme mode. A UI-only selection, so the value is exposed as
/// a `MutableValue` the picker writes directly (see the utopia_hooks global-state
/// MutableValue idiom); the sheet reads `.value` and re-themes every section.
class ThemeModeState {
  final MutableValue<ExampleThemeMode> mode;

  const ThemeModeState({required this.mode});
}

/// Global state hook. Registered in main.dart's `_providers` under
/// [ThemeModeState]; consumed anywhere with `useProvided<ThemeModeState>()`.
///
/// The initial mode honours a `?theme=<mode name>` query parameter (e.g.
/// `?theme=dracula`), so a specific look can be deep-linked and screenshotted
/// headlessly; unknown or absent values fall back to [ExampleThemeMode.light].
ThemeModeState useThemeModeState() {
  final mode = useState(_initialMode());
  return ThemeModeState(mode: mode);
}

ExampleThemeMode _initialMode() {
  final requested = Uri.base.queryParameters['theme'];
  return ExampleThemeMode.values.where((it) => it.name == requested).firstOrNull ?? ExampleThemeMode.light;
}
