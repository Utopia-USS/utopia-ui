// Golden test: `ThemeCapture.capture(UtopiaThemeData.defaultTheme)` must
// deep-equal the parsed canonical `tokens/utopia.tokens.json` at the repo
// root. This fails whenever the canonical file drifts from the runtime
// default theme - regenerate it with `dart run bin/export_tokens.dart`
// (from the repo root) whenever `UtopiaThemeData.defaultTheme` changes.
//
// Plus the derivation-stamp guard: a captured document must survive
// `export_tokens`' own self-validation, so a stamp is only emitted when the
// validator's value-space derivation gate accepts it (protocol SPEC 2.5).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/theme_capture.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() {
  // This test file lives at tool/utopia_design_tools/test/; the canonical
  // token file and the protocol schema live under the utopia_ui repo root.
  final repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));

  test('capture(defaultTheme) deep-equals the canonical tokens/utopia.tokens.json', () {
    final captured = ThemeCapture.capture(UtopiaThemeData.defaultTheme);

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

  group('derivation stamping', () {
    /// The same validator `bin/export_tokens.dart` runs on a captured
    /// document before writing it (its self-validation gate).
    TokenValidator selfValidator() {
      final schemaFile = File(p.join(repoRoot.path, 'protocol', 'schemas', 'tokens.schema.json'));
      return TokenValidator(loadSchema(schemaFile.readAsStringSync()));
    }

    /// A theme rescaled to base [x] whose `fieldMinHeight` is overridden to a
    /// value that is not a clean multiple of [x].
    UtopiaThemeData rescaledTheme(double x, double fieldMinHeight) => UtopiaThemeData.fromTokens(
      tokens: UtopiaTokens.fromBase(x),
      colors: UtopiaThemeColors.defaultTheme,
      textStyles: UtopiaThemeTextStyles.defaultTheme,
    ).copyWith(fieldMinHeight: fieldMinHeight);

    Map<String, dynamic>? utopiaExtensionsOf(Map<String, dynamic> token) {
      final extensions = token[r'$extensions'];
      if (extensions is Map<String, dynamic>) {
        return extensions['io.utopiasoft.design'] as Map<String, dynamic>?;
      }
      return null;
    }

    test('x=6 with fieldMinHeight=47 gets no derivation stamp (x*7.833 would re-derive to 46.998)', () {
      final captured = ThemeCapture.capture(rescaledTheme(6, 47));

      final fieldMinHeight = (captured['theme'] as Map<String, dynamic>)['fieldMinHeight'] as Map<String, dynamic>;
      expect((fieldMinHeight[r'$value'] as Map<String, dynamic>)['value'], 47);
      expect(
        utopiaExtensionsOf(fieldMinHeight)?['derivation'],
        isNull,
        reason: 'a 3-decimal multiple cannot reproduce 47 from x=6 within the derivation tolerance',
      );
    });

    test('a capture whose slots are not clean multiples of x still passes export self-validation', () {
      final captured = ThemeCapture.capture(rescaledTheme(6, 47));

      final errors = selfValidator().validate(captured).where((f) => f.severity == FindingSeverity.error).toList();
      expect(
        errors,
        isEmpty,
        reason:
            'export_tokens aborts with exit 1 when the captured document fails self-validation; got: '
            '${errors.map((f) => f.toLine()).join('; ')}',
      );
    });

    test('slots that are clean multiples of x keep their stamp', () {
      // fieldMinHeight = 6 * 11 = 66 is exact, so the stamp survives.
      final captured = ThemeCapture.capture(rescaledTheme(6, 66));

      final fieldMinHeight = (captured['theme'] as Map<String, dynamic>)['fieldMinHeight'] as Map<String, dynamic>;
      expect(utopiaExtensionsOf(fieldMinHeight)?['derivation'], 'x*11');
    });
  });
}
