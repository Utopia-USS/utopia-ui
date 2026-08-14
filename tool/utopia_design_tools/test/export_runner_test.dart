// The bridge between the pure-Dart `export_tokens` CLI and the Flutter-only
// `UtopiaThemeData.defaultTheme`. `bin/export_tokens.dart` shells out to
// `flutter test --no-pub test/export_runner_test.dart` with the env var
// `UTOPIA_EXPORT_OUT` set to an absolute output path; this test captures the
// default theme and writes the DTCG token document JSON there.
//
// When `UTOPIA_EXPORT_OUT` is unset, the test skips (passes trivially) so a
// plain `flutter test` run in this package stays green.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:utopia_design_tools/src/dtcg/theme_capture.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  test('exports UtopiaThemeData.defaultTheme to UTOPIA_EXPORT_OUT', () {
    final outPath = Platform.environment['UTOPIA_EXPORT_OUT'];
    if (outPath == null || outPath.isEmpty) {
      return;
    }

    final document = ThemeCapture.capture(UtopiaThemeData.defaultTheme);
    final encoder = const JsonEncoder.withIndent('  ');
    final jsonText = '${encoder.convert(document)}\n';

    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(jsonText);
  }, skip: Platform.environment['UTOPIA_EXPORT_OUT'] == null || Platform.environment['UTOPIA_EXPORT_OUT']!.isEmpty);
}
