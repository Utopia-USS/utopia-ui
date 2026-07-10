// Emitter tests: golden byte-compare against test/goldens/default_theme.g.dart
// (regenerated with `dart run utopia_design_tools:generate_theme
// ../../tokens/utopia.tokens.json -o test/goldens/default_theme.g.dart`, run
// from tool/utopia_design_tools), plus focused cases for copyWith
// minimization, optional-color minimization, fontFamily fallback emission,
// fontPackage omission and emitter idempotence. See
// ledger/checkpoints/A6-spec.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/dtcg/token_document.dart';
import 'package:utopia_design_tools/src/theme_gen/dart_emitter.dart';
import 'package:utopia_design_tools/src/theme_gen/theme_spec.dart';

void main() {
  final repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  final canonicalTokensFile = File(p.join(repoRoot.path, 'tokens', 'utopia.tokens.json'));
  final goldenFile = File(p.join(Directory.current.path, 'test', 'goldens', 'default_theme.g.dart'));

  Map<String, dynamic> loadCanonical() =>
      jsonDecode(canonicalTokensFile.readAsStringSync()) as Map<String, dynamic>;

  /// Deep-clones a decoded JSON value so a test can mutate its own copy
  /// without disturbing [loadCanonical]'s result for other tests.
  dynamic deepClone(dynamic value) {
    if (value is Map) {
      return {for (final entry in value.entries) entry.key as String: deepClone(entry.value)};
    }
    if (value is List) {
      return value.map(deepClone).toList();
    }
    return value;
  }

  group('emitDart golden', () {
    test('matches the committed golden byte-for-byte', () {
      final document = TokenDocument.parse(loadCanonical());
      final spec = ThemeSpec.fromDocument(document);
      final generated = emitDart(spec, inputPath: '../../tokens/utopia.tokens.json');

      expect(goldenFile.existsSync(), isTrue, reason: 'test/goldens/default_theme.g.dart is missing');
      final golden = goldenFile.readAsStringSync();

      expect(generated, equals(golden));
    });

    test('the canonical export needs zero copyWith args', () {
      final document = TokenDocument.parse(loadCanonical());
      final spec = ThemeSpec.fromDocument(document);
      final generated = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');

      expect(generated, contains('return theme;'));
      expect(generated, isNot(contains('.copyWith(')));
    });

    test('the canonical export omits every optional-color and divider arg', () {
      final document = TokenDocument.parse(loadCanonical());
      final spec = ThemeSpec.fromDocument(document);
      final generated = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');

      for (final field in dartDefaultOptionalColorArgb32.keys) {
        expect(generated, isNot(contains('$field:')), reason: '"$field:" should be omitted (matches Dart default)');
      }
      expect(generated, isNot(contains('divider:')));
    });

    test('is idempotent: emitting twice from the same input produces identical output', () {
      final document = TokenDocument.parse(loadCanonical());
      final spec = ThemeSpec.fromDocument(document);
      final first = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');
      final second = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');

      expect(first, equals(second));
    });
  });

  group('copyWith minimization', () {
    test('a doctored tileHeight and literal borderRadius each produce exactly one copyWith arg', () {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;

      // tileHeight is a plain design decision (not base-derived, no
      // fromTokens arithmetic to match) - any value other than the Dart
      // default 58 must surface as a copyWith arg.
      (raw['theme'] as Map<String, dynamic>)['tileHeight'] = {
        r'$type': 'dimension',
        r'$value': {'value': 64, 'unit': 'px'},
      };

      // theme.borderRadius normally aliases radius.sm (6); replace it with a
      // literal 10 so it no longer matches the fromTokens-derived value.
      (raw['theme'] as Map<String, dynamic>)['borderRadius'] = {
        r'$type': 'dimension',
        r'$value': {'value': 10, 'unit': 'px'},
      };

      final document = TokenDocument.parse(raw);
      final spec = ThemeSpec.fromDocument(document);
      final generated = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');

      expect(generated, contains('tileHeight: 64'));
      expect(generated, contains('borderRadius: BorderRadius.all(Radius.circular(10))'));
      // Only these two slots were doctored; every other copyWith-eligible
      // slot must still match fromTokens' derivation and stay absent.
      expect(generated, isNot(contains('cardRadius:')));
      expect(generated, isNot(contains('fieldContentPadding:')));
      expect(generated, isNot(contains('fieldMinHeight:')));
      expect(generated, isNot(contains('pageTopPadding:')));
    });
  });

  group('optional-color minimization', () {
    test('a surface color that differs from the Dart default is emitted explicitly', () {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;
      (raw['color'] as Map<String, dynamic>)['surface'] = {
        r'$type': 'color',
        r'$value': {
          'colorSpace': 'srgb',
          'components': [0.1, 0.2, 0.3],
          'alpha': 1,
          'hex': '#1a334d',
        },
      };

      final document = TokenDocument.parse(raw);
      final spec = ThemeSpec.fromDocument(document);
      final generated = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');

      expect(generated, contains('surface: Color(0xFF1A334D)'));
    });

    test('a document with color.divider present emits an explicit divider arg', () {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;
      (raw['color'] as Map<String, dynamic>)['divider'] = {
        r'$type': 'color',
        r'$value': {
          'colorSpace': 'srgb',
          'components': [0.5, 0.5, 0.5],
          'alpha': 1,
          'hex': '#808080',
        },
      };

      final document = TokenDocument.parse(raw);
      final spec = ThemeSpec.fromDocument(document);
      final generated = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');

      expect(generated, contains('divider: Color(0xFF808080)'));
    });
  });

  group('typography emission', () {
    test('a fontFamily array emits fontFamilyFallback for the trailing entries', () {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;
      final header = (raw['textStyle'] as Map<String, dynamic>)['header'] as Map<String, dynamic>;
      (header[r'$value'] as Map<String, dynamic>)['fontFamily'] = ['Sora', 'Roboto', 'Arial'];

      final document = TokenDocument.parse(raw);
      final spec = ThemeSpec.fromDocument(document);
      final generated = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');

      expect(generated, contains("fontFamily: 'Sora'"));
      expect(generated, contains("fontFamilyFallback: ['Roboto', 'Arial']"));
    });

    test('a typography token without the fontPackage extension omits package:', () {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;
      final header = (raw['textStyle'] as Map<String, dynamic>)['header'] as Map<String, dynamic>;
      final extensions = (header[r'$extensions'] as Map<String, dynamic>)['io.utopiasoft.design']
          as Map<String, dynamic>;
      extensions.remove('fontPackage');

      final document = TokenDocument.parse(raw);
      final spec = ThemeSpec.fromDocument(document);
      final generated = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');

      // Every other role still carries package: 'utopia_ui'; only header's
      // TextStyle should lack it. Isolate header's block by its unique
      // fontSize (24, present only on header) to avoid matching a sibling.
      final headerBlockStart = generated.indexOf('fontSize: 24');
      final headerBlockEnd = generated.indexOf(')', headerBlockStart);
      final headerBlock = generated.substring(generated.lastIndexOf('TextStyle(', headerBlockStart), headerBlockEnd);
      expect(headerBlock, isNot(contains('package:')));
    });
  });
}
