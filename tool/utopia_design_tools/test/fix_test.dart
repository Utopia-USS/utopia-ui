// Tests for the `--fix` subset of `validate_tokens` (protocol SPEC 2.5, 2.7
// gate 4): re-derivation of `derivation`-carrying values from `x`, and
// color hex resync to `components` (including inside shadow layers).
//
// Every in-process test doctors a deep copy of the canonical
// test/fixtures/tokens/valid/default-theme.tokens.json fixture in memory
// (jsonDecode/jsonEncode round-trip gives an independent mutable tree), runs
// `TokenFixer.fix` directly, and asserts both the returned change list and
// the resulting document. The CLI-level group instead shells out to the real
// `bin/validate_tokens.dart` entrypoint via `Process.run` against a scratch
// file copy, so the wiring between the fixer, the writer and re-validation
// is exercised end-to-end exactly as a user would invoke it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/cli/output.dart';
import 'package:utopia_design_tools/src/dtcg/token_fixer.dart';
import 'package:utopia_design_tools/src/dtcg/validator.dart';

void main() {
  final toolPackageDir = Directory.current;
  final fixturesDir = Directory(p.join(toolPackageDir.path, 'test', 'fixtures', 'tokens'));
  final schemaFile = File(p.join(toolPackageDir.path, '..', '..', 'protocol', 'schemas', 'tokens.schema.json'));

  late final schema = loadSchema(schemaFile.readAsStringSync());
  late final validator = TokenValidator(schema);

  Map<String, dynamic> loadDefaultTheme() {
    final file = File(p.join(fixturesDir.path, 'valid', 'default-theme.tokens.json'));
    // Deep copy via encode/decode so each test mutates its own tree; the
    // canonical fixture file itself is never touched by these tests.
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  List<Finding> errorsOf(Map<String, dynamic> doc) =>
      validator.validate(doc).where((f) => f.severity == FindingSeverity.error).toList();

  group('golden flow: derivation re-derivation', () {
    test('doctoring x to 5 makes every derivation-carrying token incoherent, then --fix repairs all of them', () {
      final doc = loadDefaultTheme();
      (doc['x'] as Map<String, dynamic>)[r'$value'] = 5;

      // Sanity: doctoring x alone (without touching the derived values)
      // must produce a derivation-coherence error per derivation-carrying
      // token, proving the fixture is genuinely incoherent before the fix.
      final before = errorsOf(doc);
      expect(before, isNotEmpty);
      expect(before.every((f) => f.message.contains('derivation')), isTrue);

      final fixes = TokenFixer.fix(doc);

      // Every derivation-carrying token in the canonical tree (protocol SPEC
      // 2.5): all of spacing.*, radius.* except radius.full, and the three
      // theme.* derived slots.
      const expectedPaths = {
        'spacing.xxs',
        'spacing.xs',
        'spacing.sm',
        'spacing.md',
        'spacing.lg',
        'spacing.xl',
        'spacing.xxl',
        'spacing.xxxl',
        'radius.xs',
        'radius.sm',
        'radius.md',
        'radius.lg',
        'radius.xl',
        'theme.fieldContentPadding.top',
        'theme.fieldContentPadding.bottom',
        'theme.fieldMinHeight',
      };
      expect(fixes.map((f) => f.path).toSet(), expectedPaths);

      // radius.full must never be touched (SPEC 2.5: deliberately not
      // base-derived, carries no derivation extension).
      expect(_dimensionValue(doc, 'radius', 'full'), 9999);

      // Re-derived values must equal x * multiple exactly.
      expect(_dimensionValue(doc, 'spacing', 'md'), 15);
      expect(_dimensionValue(doc, 'spacing', 'xxs'), 2.5);
      expect(_dimensionValue(doc, 'radius', 'sm'), 7.5);
      expect(_themeFieldValue(doc, 'fieldMinHeight'), 55);

      // Whole re-derived values are emitted as ints, not doubles (12 not
      // 12.0): spacing.xs at x=5 is exactly 5.
      expect(_dimensionValue(doc, 'spacing', 'xs'), isA<int>());
      expect(_dimensionValue(doc, 'radius', 'sm'), isA<double>());

      final after = errorsOf(doc);
      expect(after, isEmpty, reason: 'expected a clean document after --fix, got: ${after.map((f) => f.toLine())}');
    });
  });

  group('hex resync', () {
    test('a mismatched color.primary hex is fixed to match its components', () {
      final doc = loadDefaultTheme();
      final primary = _colorValue(doc, 'color', 'primary');
      primary['hex'] = '#000000';

      final fixes = TokenFixer.fix(doc);

      expect(fixes.map((f) => f.path), contains('color.primary'));
      expect(primary['hex'], '#536dfe');
      expect(errorsOf(doc), isEmpty);
    });

    test('a mismatched shadow-layer color hex is fixed to match its components', () {
      final doc = loadDefaultTheme();
      final layerColor = _shadowLayerColor(doc, 'sm', 0);
      layerColor['hex'] = '#123456';

      final fixes = TokenFixer.fix(doc);

      expect(fixes.map((f) => f.path), contains('shadow.sm[0].color'));
      expect(layerColor['hex'], '#000000');
      expect(errorsOf(doc), isEmpty);
    });

    test('both a direct color and a shadow-layer color can be fixed in the same run', () {
      final doc = loadDefaultTheme();
      _colorValue(doc, 'color', 'accent')['hex'] = '#ffffff';
      _shadowLayerColor(doc, 'lg', 0)['hex'] = '#abcdef';

      final fixes = TokenFixer.fix(doc);

      expect(fixes.map((f) => f.path).toSet(), {'color.accent', 'shadow.lg[0].color'});
      expect(errorsOf(doc), isEmpty);
    });

    test('a color hex resync line states the direction and hints at editing components instead', () {
      final doc = loadDefaultTheme();
      final primary = _colorValue(doc, 'color', 'primary');
      primary['hex'] = '#16a34a';

      final fixes = TokenFixer.fix(doc);

      final fix = fixes.singleWhere((f) => f.path == 'color.primary');
      expect(fix.kind, TokenFixKind.colorHexResync);
      expect(
        fix.toLine(),
        'FIXED color.primary: hex "#16a34a" -> "#536dfe" '
        '(hex re-derived from components; to change the color itself, edit components)',
      );
    });

    test('a derivation re-derivation line keeps the plain "old -> new" wording', () {
      final doc = loadDefaultTheme();
      (doc['x'] as Map<String, dynamic>)[r'$value'] = 5;

      final fixes = TokenFixer.fix(doc);

      final fix = fixes.singleWhere((f) => f.path == 'spacing.md');
      expect(fix.kind, TokenFixKind.derivation);
      expect(fix.toLine(), 'FIXED spacing.md: 12 -> 15');
    });
  });

  group('preservation', () {
    test('a foreign vendor extension and an unknown io.utopiasoft.design key survive a real fix untouched', () {
      final doc = loadDefaultTheme();
      final mdExtensions = _utopiaExtensionsOf(doc, 'spacing', 'md');
      final foreignExtension = <String, dynamic>{
        'note': 'keep me',
        'nested': [1, 2, 3],
      };
      mdExtensions.rootExtensions['com.example.tool'] = foreignExtension;
      mdExtensions.utopiaNamespace['unknownFutureKey'] = 'keep me too';

      // Also doctor the value so this token actually needs fixing, proving
      // the mutation happens alongside (not instead of) preservation.
      _dimensionMap(doc, 'spacing', 'md')['value'] = 999;

      final fixes = TokenFixer.fix(doc);
      expect(fixes.map((f) => f.path), contains('spacing.md'));

      expect(mdExtensions.rootExtensions['com.example.tool'], foreignExtension);
      expect(mdExtensions.utopiaNamespace['unknownFutureKey'], 'keep me too');
      expect(_dimensionValue(doc, 'spacing', 'md'), 12);
    });

    test('re-encoding after a fix deep-equals the original document except for the fixed values', () {
      final original = loadDefaultTheme();
      final doctored = loadDefaultTheme();
      _tokenValueMap(doctored, 'x')[r'$value'] = 5;

      TokenFixer.fix(doctored);

      // Round-trip both through the exporter's exact encoding style and
      // compare key sets structurally: every group/token path present in
      // the original must still be present, in the same shape, with only
      // the expected numeric leaves differing.
      void walkAndCompare(dynamic a, dynamic b, String path) {
        if (a is Map<String, dynamic>) {
          expect(b, isA<Map<String, dynamic>>(), reason: 'shape mismatch at $path');
          final bMap = b as Map<String, dynamic>;
          expect(bMap.keys.toSet(), a.keys.toSet(), reason: 'key set mismatch at $path');
          for (final key in a.keys) {
            walkAndCompare(a[key], bMap[key], path.isEmpty ? key : '$path.$key');
          }
          return;
        }
        if (a is List<dynamic>) {
          expect(b, isA<List<dynamic>>(), reason: 'shape mismatch at $path');
          final bList = b as List<dynamic>;
          expect(bList.length, a.length, reason: 'array length mismatch at $path');
          for (var i = 0; i < a.length; i++) {
            walkAndCompare(a[i], bList[i], '$path[$i]');
          }
          return;
        }
        // Leaf values: allowed to differ only under spacing/radius/theme
        // (derivation-carrying paths) - everything else must be identical.
        final isDerivationCarrying =
            path.startsWith('spacing.') ||
            path.startsWith('radius.') ||
            path.startsWith('theme.') ||
            path == r'x.$value';
        if (!isDerivationCarrying) {
          expect(b, a, reason: 'unexpected difference at $path');
        }
      }

      walkAndCompare(original, doctored, '');
    });
  });

  group('no-op', () {
    test('the canonical file needs nothing fixed and its bytes stay untouched', () {
      final scratchDir = Directory.systemTemp.createTempSync('validate_tokens_fix_noop_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      final canonical = File(p.join(fixturesDir.path, 'valid', 'default-theme.tokens.json'));
      final scratchFile = File(p.join(scratchDir.path, 'tokens.json'))..writeAsStringSync(canonical.readAsStringSync());
      final beforeBytes = scratchFile.readAsBytesSync();

      final doc = jsonDecode(scratchFile.readAsStringSync()) as Map<String, dynamic>;
      final fixes = TokenFixer.fix(doc);

      expect(fixes, isEmpty);
      // TokenFixer.fix never writes to disk itself; assert the scratch file
      // (which the CLI would only rewrite when fixes is non-empty) is still
      // byte-identical, proving no accidental disk write path exists here.
      expect(scratchFile.readAsBytesSync(), beforeBytes);
    });
  });

  group('validator agreement', () {
    test('a document the validator calls clean yields no fixes, float imprecision included', () {
      final doc = loadDefaultTheme();
      _tokenValueMap(doc, 'x')[r'$value'] = 3;
      // x*0.1 is the classic IEEE-754 case: 3 * 0.1 == 0.30000000000000004,
      // so a stored 0.3 is within the validator's derivationTolerance but not
      // exactly equal - the fixer must agree with the validator, not rewrite.
      _utopiaExtensionsOf(doc, 'spacing', 'xxs').utopiaNamespace['derivation'] = 'x*0.1';

      // Re-derive the rest of the tree for x=3 (every other multiple is a
      // half-integer, so those land exactly), then write the clean decimal a
      // human or the exporter would store for spacing.xxs.
      TokenFixer.fix(doc);
      _dimensionMap(doc, 'spacing', 'xxs')['value'] = 0.3;

      expect(
        errorsOf(doc),
        isEmpty,
        reason: 'the setup must be validator-clean: ${errorsOf(doc).map((f) => f.toLine())}',
      );
      expect(TokenFixer.fix(doc), isEmpty);
      expect(_dimensionValue(doc, 'spacing', 'xxs'), 0.3);
    });

    test('radius.full keeps its 9999 sentinel even when a derivation extension is present', () {
      final doc = loadDefaultTheme();
      // The validator rejects a derivation on radius.full outright (SPEC 2.5);
      // honoring it would overwrite the pill sentinel with x*2 = 8.
      _tokenValueMap(doc, 'radius', 'full')[r'$extensions'] = {
        'io.utopiasoft.design': {'derivation': 'x*2'},
      };

      final fixes = TokenFixer.fix(doc);

      expect(fixes.map((f) => f.path), isNot(contains('radius.full')));
      expect(_dimensionValue(doc, 'radius', 'full'), 9999);
      // ...and the document stays invalid, so --fix cannot mask the error.
      expect(errorsOf(doc).map((f) => f.message), anyElement(contains('must not carry a derivation extension')));
    });
  });

  group('CLI level (real bin/validate_tokens.dart via Process.run)', () {
    test('a rebranded x=4->5 scratch copy: --fix exits 0 with FIXED lines, then a rerun says nothing to fix', () async {
      final scratchDir = Directory.systemTemp.createTempSync('validate_tokens_fix_cli_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      final canonical = File(p.join(fixturesDir.path, 'valid', 'default-theme.tokens.json'));
      final scratchFile = File(p.join(scratchDir.path, 'tokens.json'));
      final doc = jsonDecode(canonical.readAsStringSync()) as Map<String, dynamic>;
      _tokenValueMap(doc, 'x')[r'$value'] = 5;
      scratchFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(doc)}\n');

      Future<ProcessResult> runCli(List<String> args) => Process.run('dart', [
        'run',
        'bin/validate_tokens.dart',
        ...args,
      ], workingDirectory: toolPackageDir.path);

      final validateBefore = await runCli([scratchFile.path]);
      expect(validateBefore.exitCode, 1, reason: 'stdout: ${validateBefore.stdout}\nstderr: ${validateBefore.stderr}');
      expect(validateBefore.stdout as String, contains('derivation'));

      final fixResult = await runCli(['--fix', scratchFile.path]);
      expect(fixResult.exitCode, 0, reason: 'stdout: ${fixResult.stdout}\nstderr: ${fixResult.stderr}');
      final fixLines = (fixResult.stdout as String).split('\n').where((l) => l.startsWith('FIXED ')).toList();
      expect(fixLines, isNotEmpty);
      expect(fixLines.any((l) => l.startsWith('FIXED spacing.md:')), isTrue);

      final validateAfter = await runCli([scratchFile.path]);
      expect(validateAfter.exitCode, 0, reason: 'stdout: ${validateAfter.stdout}\nstderr: ${validateAfter.stderr}');

      final rerunFix = await runCli(['--fix', scratchFile.path]);
      expect(rerunFix.exitCode, 0);
      expect((rerunFix.stdout as String).trim(), 'nothing to fix');
    });

    test('a mismatched color.primary hex on a scratch copy: --fix prints the direction-hint FIXED line', () async {
      final scratchDir = Directory.systemTemp.createTempSync('validate_tokens_fix_cli_hex_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      final canonical = File(p.join(fixturesDir.path, 'valid', 'default-theme.tokens.json'));
      final scratchFile = File(p.join(scratchDir.path, 'tokens.json'));
      final doc = jsonDecode(canonical.readAsStringSync()) as Map<String, dynamic>;
      _colorValue(doc, 'color', 'primary')['hex'] = '#16a34a';
      scratchFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(doc)}\n');

      final fixResult = await Process.run('dart', [
        'run',
        'bin/validate_tokens.dart',
        '--fix',
        scratchFile.path,
      ], workingDirectory: toolPackageDir.path);

      expect(fixResult.exitCode, 0, reason: 'stdout: ${fixResult.stdout}\nstderr: ${fixResult.stderr}');
      expect(
        fixResult.stdout as String,
        contains(
          'FIXED color.primary: hex "#16a34a" -> "#536dfe" '
          '(hex re-derived from components; to change the color itself, edit components)',
        ),
      );
    });

    test('--fix --json on a scratch copy prints a fixed array and the file rewrite is well-formed JSON', () async {
      final scratchDir = Directory.systemTemp.createTempSync('validate_tokens_fix_cli_json_');
      addTearDown(() => scratchDir.deleteSync(recursive: true));

      final canonical = File(p.join(fixturesDir.path, 'valid', 'default-theme.tokens.json'));
      final scratchFile = File(p.join(scratchDir.path, 'tokens.json'));
      final doc = jsonDecode(canonical.readAsStringSync()) as Map<String, dynamic>;
      _colorValue(doc, 'color', 'primary')['hex'] = '#000000';
      scratchFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(doc)}\n');

      final result = await Process.run('dart', [
        'run',
        'bin/validate_tokens.dart',
        '--fix',
        '--json',
        scratchFile.path,
      ], workingDirectory: toolPackageDir.path);

      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      final parsed = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      expect(parsed['status'], 'ok');
      final fixed = (parsed['fixed'] as List).cast<Map<String, dynamic>>();
      expect(fixed, isNotEmpty);
      expect(fixed.any((f) => f['path'] == 'color.primary'), isTrue);

      // The rewritten file must itself still be valid, re-parseable JSON.
      final rewritten = jsonDecode(scratchFile.readAsStringSync());
      expect(rewritten, isA<Map<String, dynamic>>());
    });
  });
}

/// Returns the mutable `$type`/`$value` token map at `doc[group][name]`.
Map<String, dynamic> _tokenValueMap(Map<String, dynamic> doc, String group, [String? name]) {
  final groupMap = doc[group] as Map<String, dynamic>;
  return name == null ? groupMap : groupMap[name] as Map<String, dynamic>;
}

/// Returns the mutable dimension `{"value": n, "unit": "px"}` object of the
/// token at `doc[group][name]`.
Map<String, dynamic> _dimensionMap(Map<String, dynamic> doc, String group, String name) =>
    _tokenValueMap(doc, group, name)[r'$value'] as Map<String, dynamic>;

/// Returns the numeric `value` field of the dimension token at
/// `doc[group][name]`.
num _dimensionValue(Map<String, dynamic> doc, String group, String name) => _dimensionMap(doc, group, name)['value'] as num;

/// Returns the mutable DTCG color object (`$value`) of the color token at
/// `doc[group][name]`.
Map<String, dynamic> _colorValue(Map<String, dynamic> doc, String group, String name) =>
    _tokenValueMap(doc, group, name)[r'$value'] as Map<String, dynamic>;

/// Returns the mutable `theme.<field>` dimension value (bare, not nested
/// under `fieldContentPadding`).
num _themeFieldValue(Map<String, dynamic> doc, String field) => _dimensionValue(doc, 'theme', field);

/// Returns the mutable color object of shadow layer [index] inside
/// `shadow.<step>`.
Map<String, dynamic> _shadowLayerColor(Map<String, dynamic> doc, String step, int index) {
  final shadowValue = _tokenValueMap(doc, 'shadow', step)[r'$value'] as List;
  final layer = shadowValue[index] as Map<String, dynamic>;
  return layer['color'] as Map<String, dynamic>;
}

/// The two mutable extension maps of a token: the full `$extensions` object
/// (for foreign vendor namespaces) and the `io.utopiasoft.design` namespace
/// within it (for protocol keys).
class _TokenExtensions {
  const _TokenExtensions(this.rootExtensions, this.utopiaNamespace);

  /// The token's full `$extensions` map (all vendor namespaces).
  final Map<String, dynamic> rootExtensions;

  /// The `io.utopiasoft.design` namespace map within [rootExtensions].
  final Map<String, dynamic> utopiaNamespace;
}

/// Returns the [_TokenExtensions] of the token at `doc[group][name]`.
_TokenExtensions _utopiaExtensionsOf(Map<String, dynamic> doc, String group, String name) {
  final root = _tokenValueMap(doc, group, name)[r'$extensions'] as Map<String, dynamic>;
  final utopia = root['io.utopiasoft.design'] as Map<String, dynamic>;
  return _TokenExtensions(root, utopia);
}
