// Emitter tests: golden byte-compare against test/goldens/default_theme.g.dart
// (regenerated with `dart run utopia_design_tools:generate_theme
// ../../tokens/utopia.tokens.json -o test/goldens/default_theme.g.dart`, run
// from tool/utopia_design_tools - the CLI normalizes the identity header path
// to the repo-root-relative `tokens/utopia.tokens.json`, which is what the
// golden test passes as inputPath, and keeps the as-invoked
// `../../tokens/utopia.tokens.json` for the runnable `Regenerate:` command
// line, which is what it passes as regeneratePath), plus focused cases for
// copyWith minimization,
// optional-color minimization, fontFamily fallback emission, inner-alias
// resolution, hostile font-name escaping, fontPackage omission and emitter
// idempotence. See ledger/checkpoints/A6-spec.md.
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
      final generated = emitDart(
        spec,
        inputPath: 'tokens/utopia.tokens.json',
        regeneratePath: '../../tokens/utopia.tokens.json',
      );

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

    test('font family, package and fallback names are escaped as Dart string literals', () {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;
      final header = (raw['textStyle'] as Map<String, dynamic>)['header'] as Map<String, dynamic>;
      // A hostile family name: a single quote ends the literal, a backslash
      // escapes the next character and a $ starts an interpolation - all
      // three produce invalid or mis-parsed Dart when interpolated raw.
      (header[r'$value'] as Map<String, dynamic>)['fontFamily'] = [
        r"O'Hara $ans\Bold",
        'Fall\nback',
      ];
      final extensions = (header[r'$extensions'] as Map<String, dynamic>)['io.utopiasoft.design']
          as Map<String, dynamic>;
      extensions['fontPackage'] = "it's_a_package";

      final document = TokenDocument.parse(raw);
      final spec = ThemeSpec.fromDocument(document);

      // emitDart runs the output through dart_style, which throws on source
      // it cannot parse - so "does not throw" is also a syntax assertion.
      final generated = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');

      expect(generated, contains(r"fontFamily: 'O\'Hara \$ans\\Bold'"));
      expect(generated, contains(r"package: 'it\'s_a_package'"));
      expect(generated, contains(r"fontFamilyFallback: ['Fall\nback']"));
    });

    test('an aliased fontSize/fontWeight/letterSpacing resolves to its target token value', () {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;
      final header = (raw['textStyle'] as Map<String, dynamic>)['header'] as Map<String, dynamic>;
      final headerValue = header[r'$value'] as Map<String, dynamic>;
      // Each typography sub-property is `oneOf {value, alias}` in the schema
      // (protocol SPEC 2.4), so the resolver must follow inner aliases.
      headerValue['fontSize'] = '{spacing.xxl}';
      headerValue['fontWeight'] = '{fontWeight.bold}';
      headerValue['letterSpacing'] = '{spacing.xxs}';

      final document = TokenDocument.parse(raw);
      final spec = ThemeSpec.fromDocument(document);

      expect(spec.textStyles.header.fontSize, 32);
      expect(spec.textStyles.header.fontWeight, 700);
      expect(spec.textStyles.header.letterSpacing, 2);

      final generated = emitDart(spec, inputPath: 'tokens/utopia.tokens.json');
      expect(generated, contains('fontSize: 32'));
    });

    test('an aliased fontFamily that resolves to a non-name token fails loudly', () {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;
      final header = (raw['textStyle'] as Map<String, dynamic>)['header'] as Map<String, dynamic>;
      (header[r'$value'] as Map<String, dynamic>)['fontFamily'] = '{spacing.md}';

      final document = TokenDocument.parse(raw);

      // Before inner aliases were resolved this silently emitted
      // "fontFamily: '{spacing.md}'" - a font named after the alias text.
      expect(
        () => ThemeSpec.fromDocument(document),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('"textStyle.header.fontFamily" must be a string or array of strings'),
          ),
        ),
      );
    });

    test('a fontFamily array with a non-string element raises the same named error', () {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;
      final header = (raw['textStyle'] as Map<String, dynamic>)['header'] as Map<String, dynamic>;
      (header[r'$value'] as Map<String, dynamic>)['fontFamily'] = ['Sora', 42];

      final document = TokenDocument.parse(raw);

      // `.cast<String>()` is lazy, so this used to surface as a raw TypeError
      // on the first read instead of the sibling branch's named StateError.
      expect(
        () => ThemeSpec.fromDocument(document),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('"textStyle.header.fontFamily" must be a string or array of strings'),
          ),
        ),
      );
    });
  });

  group('CLI header path (real bin/generate_theme.dart via Process.run)', () {
    test('the same in-repo input produces the same header from any working directory', () async {
      final scratchDir = Directory.systemTemp.createTempSync('generate_theme_header_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      final entrypoint = p.join(Directory.current.path, 'bin', 'generate_theme.dart');

      Future<String> headerFrom({required String workingDirectory, required String inputPath}) async {
        final outputFile = File(p.join(scratchDir.path, 'theme_${workingDirectory.hashCode}.g.dart'));
        final result = await Process.run('dart', [
          'run',
          entrypoint,
          inputPath,
          '-o',
          outputFile.path,
        ], workingDirectory: workingDirectory);
        expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
        return outputFile.readAsLinesSync().first;
      }

      final fromToolPackage = await headerFrom(
        workingDirectory: Directory.current.path,
        inputPath: p.join('..', '..', 'tokens', 'utopia.tokens.json'),
      );
      final fromRepoRoot = await headerFrom(
        workingDirectory: repoRoot.path,
        inputPath: p.join('tokens', 'utopia.tokens.json'),
      );

      expect(
        fromToolPackage,
        '// GENERATED by utopia_design_tools:generate_theme from tokens/utopia.tokens.json - do not edit.',
      );
      expect(fromRepoRoot, fromToolPackage);
    });

    test('the Regenerate: line keeps the path as invoked, so the printed command resolves', () async {
      final scratchDir = Directory.systemTemp.createTempSync('generate_theme_regenerate_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      final entrypoint = p.join(Directory.current.path, 'bin', 'generate_theme.dart');
      final outputFile = File(p.join(scratchDir.path, 'theme.g.dart'));
      final invokedPath = p.join('..', '..', 'tokens', 'utopia.tokens.json');

      final result = await Process.run('dart', [
        'run',
        entrypoint,
        invokedPath,
        '-o',
        outputFile.path,
      ], workingDirectory: Directory.current.path);
      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');

      final lines = outputFile.readAsLinesSync();
      // The identity line stays normalized (stable across invocation dirs)...
      expect(lines.first, contains('from tokens/utopia.tokens.json'));
      // ...while the command line keeps the path as invoked, which is the
      // only form that resolves from the directory the command was run in -
      // the normalized one is relative to the utopia_ui root and resolves
      // from neither the repo root nor here.
      expect(lines[1], '// Regenerate: dart run utopia_design_tools:generate_theme $invokedPath');
      expect(File(p.join(Directory.current.path, invokedPath)).existsSync(), isTrue);
    });
  });

  group('CLI --check freshness gate (real bin/generate_theme.dart via Process.run)', () {
    final entrypoint = p.join(Directory.current.path, 'bin', 'generate_theme.dart');

    Future<ProcessResult> runCheck({required String tokensPath, required String outputPath}) => Process.run('dart', [
      'run',
      entrypoint,
      tokensPath,
      '-o',
      outputPath,
      '--check',
    ], workingDirectory: Directory.current.path);

    test('the committed golden is up to date: exit 0, nothing written', () async {
      final goldenPath = p.join('test', 'goldens', 'default_theme.g.dart');
      final before = goldenFile.readAsBytesSync();

      // The exact pair the golden was generated from (see this file's header),
      // run from the same working directory - --check is byte-exact, and the
      // emitted `Regenerate:` line keeps the token path as invoked.
      final result = await runCheck(
        tokensPath: p.join('..', '..', 'tokens', 'utopia.tokens.json'),
        outputPath: goldenPath,
      );

      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      expect(result.stdout, contains('up to date'));
      expect(goldenFile.readAsBytesSync(), before);
    });

    test('a changed token makes the generated file stale: exit 1, file left untouched', () async {
      final scratchDir = Directory.systemTemp.createTempSync('generate_theme_check_stale_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      final tokensFile = File(p.join(scratchDir.path, 'tokens.json'));
      tokensFile.writeAsStringSync(canonicalTokensFile.readAsStringSync());
      final outputFile = File(p.join(scratchDir.path, 'theme.g.dart'));

      final generate = await Process.run('dart', [
        'run',
        entrypoint,
        tokensFile.path,
        '-o',
        outputFile.path,
      ], workingDirectory: Directory.current.path);
      expect(generate.exitCode, 0, reason: 'stdout: ${generate.stdout}\nstderr: ${generate.stderr}');

      // Freshly generated: the gate is quiet.
      final fresh = await runCheck(tokensPath: tokensFile.path, outputPath: outputFile.path);
      expect(fresh.exitCode, 0, reason: 'stdout: ${fresh.stdout}\nstderr: ${fresh.stderr}');

      // tileHeight is a plain design decision (no derivation gate to trip), so
      // moving it off the Dart default changes the emitted output and nothing
      // else - exactly the drift a consumer's edited token document produces.
      final raw = jsonDecode(tokensFile.readAsStringSync()) as Map<String, dynamic>;
      ((raw['theme'] as Map<String, dynamic>)['tileHeight'] as Map<String, dynamic>)[r'$value'] = {
        'value': 64,
        'unit': 'px',
      };
      tokensFile.writeAsStringSync(jsonEncode(raw));
      final beforeCheck = outputFile.readAsBytesSync();

      final stale = await runCheck(tokensPath: tokensFile.path, outputPath: outputFile.path);

      expect(stale.exitCode, 1, reason: 'stdout: ${stale.stdout}\nstderr: ${stale.stderr}');
      expect(stale.stderr, contains('is stale - regenerate via:'));
      expect(stale.stderr, contains('dart run utopia_design_tools:generate_theme ${tokensFile.path}'));
      expect(stale.stderr, contains('-o ${outputFile.path}'));
      // --check never writes: the stale file is reported, not repaired.
      expect(outputFile.readAsBytesSync(), beforeCheck);
    });

    test('a path holding a space comes back quoted, so the printed command is runnable', () async {
      final scratchDir = Directory.systemTemp.createTempSync('generate_theme_check_spaced_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      final spacedDir = Directory(p.join(scratchDir.path, 'My Projects'))..createSync(recursive: true);
      final tokensFile = File(p.join(spacedDir.path, 'tokens.json'))
        ..writeAsStringSync(canonicalTokensFile.readAsStringSync());
      final outputFile = File(p.join(spacedDir.path, 'theme.g.dart'));

      final result = await runCheck(tokensPath: tokensFile.path, outputPath: outputFile.path);

      expect(result.exitCode, 1, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      // Unquoted, the shell would split "My Projects" into two arguments and
      // the suggested command would fail on a path that does not exist.
      expect(result.stderr, contains("'${tokensFile.path}'"));
      expect(result.stderr, contains("-o '${outputFile.path}'"));
    });

    test('a missing output file is a failure, and --check does not create it', () async {
      final scratchDir = Directory.systemTemp.createTempSync('generate_theme_check_missing_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      // Nested under a directory that does not exist either: the writing path
      // would create it (createSync(recursive: true)), --check must not.
      final missingParent = Directory(p.join(scratchDir.path, 'lib', 'theme'));
      final outputFile = File(p.join(missingParent.path, 'utopia_theme.g.dart'));

      final result = await runCheck(
        tokensPath: p.join('..', '..', 'tokens', 'utopia.tokens.json'),
        outputPath: outputFile.path,
      );

      expect(result.exitCode, 1, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      expect(result.stderr, contains('does not exist'));
      expect(result.stderr, contains('dart run utopia_design_tools:generate_theme'));
      expect(outputFile.existsSync(), isFalse);
      expect(missingParent.existsSync(), isFalse);
    });

    test('--json reports the same verdicts machine-readably', () async {
      final scratchDir = Directory.systemTemp.createTempSync('generate_theme_check_json_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      final outputFile = File(p.join(scratchDir.path, 'theme.g.dart'));
      final tokensPath = p.join('..', '..', 'tokens', 'utopia.tokens.json');

      Future<Map<String, dynamic>> checkJson() async {
        final result = await Process.run('dart', [
          'run',
          entrypoint,
          tokensPath,
          '-o',
          outputFile.path,
          '--check',
          '--json',
        ], workingDirectory: Directory.current.path);
        return {
          'exitCode': result.exitCode,
          ...jsonDecode(result.stdout as String) as Map<String, dynamic>,
        };
      }

      final missing = await checkJson();
      expect(missing['exitCode'], 1);
      expect(missing['status'], 'missing');

      outputFile.writeAsStringSync(goldenFile.readAsStringSync());
      final ok = await checkJson();
      expect(ok['exitCode'], 0);
      expect(ok['status'], 'ok');

      outputFile.writeAsStringSync('// hand-edited\n${goldenFile.readAsStringSync()}');
      final stale = await checkJson();
      expect(stale['exitCode'], 1);
      expect(stale['status'], 'stale');
      expect(stale['regenerate'], contains('-o ${outputFile.path}'));
    });
  });

  group('shadow layer aliases', () {
    /// Returns the canonical document with `shadow.lg` doctored to
    /// [layerCount] identical layers and `shadow.md` replaced by a single
    /// per-layer alias to `shadow.lg`.
    Map<String, dynamic> documentAliasingShadowLg({required int layerCount}) {
      final raw = deepClone(loadCanonical()) as Map<String, dynamic>;
      final shadowGroup = raw['shadow'] as Map<String, dynamic>;
      final lg = shadowGroup['lg'] as Map<String, dynamic>;
      final firstLayer = (lg[r'$value'] as List).first;
      lg[r'$value'] = [for (var i = 0; i < layerCount; i++) deepClone(firstLayer)];
      (shadowGroup['md'] as Map<String, dynamic>)[r'$value'] = ['{shadow.lg}'];
      return raw;
    }

    test('a per-layer alias to a single-layer shadow resolves that layer', () {
      final spec = ThemeSpec.fromDocument(TokenDocument.parse(documentAliasingShadowLg(layerCount: 1)));

      expect(spec.shadowMd, hasLength(1));
      expect(spec.shadowMd.single.blur, spec.shadowLg.single.blur);
    });

    test('a per-layer alias to a multi-layer shadow is a hard error naming both token paths', () {
      final document = TokenDocument.parse(documentAliasingShadowLg(layerCount: 2));

      expect(
        () => ThemeSpec.fromDocument(document),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('"shadow.md"'),
              contains('{shadow.lg}'),
              contains('has 2 layers'),
            ),
          ),
        ),
      );
    });
  });
}
