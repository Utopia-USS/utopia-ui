// Golden test: `ThemeCapture.capture(UtopiaThemeData.defaultTheme)` must
// deep-equal the parsed canonical `tokens/utopia.tokens.json` at the repo
// root. This fails whenever the canonical file drifts from the runtime
// default theme - regenerate it with `dart run bin/export_tokens.dart`
// (from the repo root) whenever `UtopiaThemeData.defaultTheme` changes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/dtcg/theme_capture.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  test('capture(defaultTheme) deep-equals the canonical tokens/utopia.tokens.json', () {
    final captured = ThemeCapture.capture(UtopiaThemeData.defaultTheme);

    // This test file lives at tool/utopia_design_tools/test/; the canonical
    // file lives at the utopia_ui repo root's tokens/ directory.
    final repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
    final canonicalFile = File(p.join(repoRoot.path, 'tokens', 'utopia.tokens.json'));

    expect(
      canonicalFile.existsSync(),
      isTrue,
      reason:
          'tokens/utopia.tokens.json not found at ${canonicalFile.path}. Generate it with '
          '"dart run tool/utopia_design_tools/bin/export_tokens.dart" from the repo root.',
    );

    final canonical = jsonDecode(canonicalFile.readAsStringSync());

    expect(captured, equals(canonical));
  });
}
