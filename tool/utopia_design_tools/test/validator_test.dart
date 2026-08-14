// Table-driven tests over test/fixtures/tokens/{valid,invalid}: every valid
// fixture must produce zero errors; every invalid fixture must produce at
// least one error whose message contains the declared substring.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/dtcg/validator.dart';

void main() {
  final fixturesDir = Directory(p.join(Directory.current.path, 'test', 'fixtures', 'tokens'));
  final schemaFile = File(
    p.join(Directory.current.path, '..', '..', 'protocol', 'schemas', 'tokens.schema.json'),
  );

  late final schema = loadSchema(schemaFile.readAsStringSync());
  late final validator = TokenValidator(schema);

  Map<String, dynamic> loadFixture(String relativePath) {
    final file = File(p.join(fixturesDir.path, relativePath));
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  group('valid fixtures produce zero errors', () {
    const validFixtures = ['valid/default-theme.tokens.json', 'valid/rebrand-base5.tokens.json'];

    for (final fixture in validFixtures) {
      test(fixture, () {
        final doc = loadFixture(fixture);
        final findings = validator.validate(doc);
        final errors = findings.where((f) => f.severity.name == 'error').toList();
        expect(
          errors,
          isEmpty,
          reason: 'expected no errors, got: ${errors.map((f) => f.toLine()).join('; ')}',
        );
      });
    }
  });

  group('invalid fixtures produce an actionable error', () {
    // Each entry: fixture file name -> substring expected in at least one
    // ERROR-severity finding's message.
    const invalidFixtures = <String, String>{
      'invalid/missing-color-primary.tokens.json': "missing required token 'color.primary'",
      'invalid/rem-unit.tokens.json': 'dimension unit must be "px"',
      'invalid/negative-spacing.tokens.json': 'dimension "value" must be >= 0',
      'invalid/unknown-top-group.tokens.json': 'the utopia token tree is closed',
      'invalid/derivation-mismatch.tokens.json': 'derivation x*3 expects 12',
      'invalid/derivation-on-radius-full.tokens.json': 'must not carry a derivation extension',
      'invalid/circular-alias.tokens.json': 'circular alias',
      'invalid/dangling-alias.tokens.json': 'dangling alias',
      'invalid/uppercase-hex.tokens.json': 'hex must be lowercase',
      'invalid/hex-component-mismatch.tokens.json': 'does not match components',
      'invalid/missing-padding-side.tokens.json': "missing required token 'theme.fieldContentPadding.left'",
      'invalid/lineheight-in-typography.tokens.json': 'lineHeight is not part of the Utopia Design Protocol v0',
    };

    for (final entry in invalidFixtures.entries) {
      test(entry.key, () {
        final doc = loadFixture(entry.key);
        final findings = validator.validate(doc);
        final errors = findings.where((f) => f.severity.name == 'error').toList();
        expect(errors, isNotEmpty, reason: 'expected at least one error for ${entry.key}');
        final matching = errors.where((f) => f.message.contains(entry.value));
        expect(
          matching,
          isNotEmpty,
          reason:
              'expected an error containing "${entry.value}" for ${entry.key}, got: '
              '${errors.map((f) => f.toLine()).join('; ')}',
        );
      });
    }
  });

  group('gate 5: the colorToken target must be a color token', () {
    /// The canonical valid fixture with `textStyle.header`'s `colorToken`
    /// extension repointed at [target]. `loadFixture` re-reads the file, so
    /// each call gets its own mutable tree.
    Map<String, dynamic> docWithHeaderColorToken(String target) {
      final doc = loadFixture('valid/default-theme.tokens.json');
      final header = (doc['textStyle'] as Map<String, dynamic>)['header'] as Map<String, dynamic>;
      final extensions = (header[r'$extensions'] as Map<String, dynamic>)['io.utopiasoft.design']
          as Map<String, dynamic>;
      extensions['colorToken'] = target;
      return doc;
    }

    List<String> errorMessages(Map<String, dynamic> doc) =>
        validator.validate(doc).where((f) => f.severity.name == 'error').map((f) => f.message).toList();

    test('a colorToken pointing at a non-color token is an error', () {
      expect(
        errorMessages(docWithHeaderColorToken('spacing.md')),
        anyElement(contains('colorToken "spacing.md" resolves to a dimension token, not a color token')),
      );
    });

    test('a colorToken pointing at a real color token is accepted (only the convention warning fires)', () {
      final doc = docWithHeaderColorToken('color.primary');

      expect(errorMessages(doc), isEmpty);
      expect(
        validator.validate(doc).where((f) => f.severity.name == 'warning').map((f) => f.message),
        anyElement(contains('is not the conventional "textStyle-colors.header"')),
      );
    });
  });
}
