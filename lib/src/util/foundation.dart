/// Internal foundation barrel for utopia_ui.
///
/// Re-exports the web-safe pieces this package actually uses (hooks,
/// collections). Deliberately excludes `package:utopia_arch/utopia_arch.dart`,
/// which transitively pulls `logger` (and its `dart:io` file output), breaking
/// web platform support - see the charter's dependency policy. Deliberately
/// excludes `package:utopia_widgets` too: utopia_widgets is expected to depend
/// on this package in the future, so the few primitives this package needs
/// from it are vendored under `src/widget/` instead.
library;

export 'package:fast_immutable_collections/fast_immutable_collections.dart';
export 'package:utopia_collections/utopia_collections.dart';
export 'package:utopia_hooks/utopia_hooks.dart';
