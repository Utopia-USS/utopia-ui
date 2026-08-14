// Golden-line and behavior tests for the generate_twin generators (protocol
// SPEC section 4; see ledger/checkpoints/A4-spec.md): spot-assert exact CSS
// lines for representative tokens rather than full-file byte compares (the
// canonical export can gain tokens over time), plus the DESIGN.md front
// matter splice contract and idempotence of every generator.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:utopia_design_tools/src/dtcg/token_document.dart';
import 'package:utopia_design_tools/src/twin/css_generator.dart';
import 'package:utopia_design_tools/src/twin/design_md_generator.dart';
import 'package:utopia_design_tools/src/twin/tailwind_generator.dart';

void main() {
  final repoRoot = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  final canonicalTokensFile = File(p.join(repoRoot.path, 'tokens', 'utopia.tokens.json'));

  Map<String, dynamic> loadCanonical() => jsonDecode(canonicalTokensFile.readAsStringSync()) as Map<String, dynamic>;

  TokenDocument canonicalDocument() => TokenDocument.parse(loadCanonical());

  /// The canonical document with one `textStyle.header` sub-property
  /// replaced by [value] (each is `oneOf {value, alias}` per protocol SPEC
  /// 2.4 / tokens.schema.json). `loadCanonical` re-reads the file, so the
  /// canonical tree used by the other tests is never mutated.
  TokenDocument documentWithHeaderProperty(String property, dynamic value) {
    final raw = loadCanonical();
    final header = (raw['textStyle'] as Map<String, dynamic>)['header'] as Map<String, dynamic>;
    (header[r'$value'] as Map<String, dynamic>)[property] = value;
    return TokenDocument.parse(raw);
  }

  group('cssVarName', () {
    test('kebab-cases camelCase path segments and joins with -', () {
      expect(cssVarName('spacing.md'), equals('--utopia-spacing-md'));
      expect(cssVarName('fontWeight.semiBold'), equals('--utopia-font-weight-semi-bold'));
      expect(
        cssVarName('theme.fieldContentPadding.top'),
        equals('--utopia-theme-field-content-padding-top'),
      );
      expect(cssVarName('breakpoint.tablet'), equals('--utopia-breakpoint-tablet'));
    });
  });

  group('generateCss golden lines', () {
    test('spacing.md', () {
      final css = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-spacing-md: 12px;'));
    });

    test('fontWeight.semiBold', () {
      final css = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-font-weight-semi-bold: 600;'));
    });

    test('theme.borderRadius emits a var() alias reference', () {
      final css = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-theme-border-radius: var(--utopia-radius-sm);'));
    });

    test('shadow.sm emits the full box-shadow value with unitless zero components', () {
      final css = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-shadow-sm: 0 1px 6px 0 rgb(0 0 0 / 0.051);'));
    });

    test('textStyle.header expands to per-property vars with the folded sibling color', () {
      final css = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-text-style-header-font-family: Sora;'));
      expect(css, contains('  --utopia-text-style-header-font-size: 24px;'));
      expect(css, contains('  --utopia-text-style-header-font-weight: 600;'));
      expect(css, contains('  --utopia-text-style-header-letter-spacing: 1px;'));
      // The fold rule: textStyle-colors.header -> ...-header-color, NOT
      // ...-text-style-colors-header.
      expect(css, contains('  --utopia-text-style-header-color: rgb(0 0 0 / 0.8667);'));
      expect(css, isNot(contains('text-style-colors')));
    });

    test('x is unitless', () {
      final css = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-x: 4;'));
    });

    test('an alpha color renders rgb() with 0-255 channels and trimmed alpha', () {
      final css = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      // color.text: components [0,0,0], alpha 0.866667 -> rgb(0 0 0 / 0.8667).
      expect(css, contains('  --utopia-color-text: rgb(0 0 0 / 0.8667);'));
    });

    test('an opaque color renders lowercase hex', () {
      final css = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-color-primary: #536dfe;'));
    });

    test('header comment carries the input path and regeneration command', () {
      final css = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(
        css,
        contains('/* GENERATED by utopia_design_tools:generate_twin from tokens/utopia.tokens.json - do not edit. */'),
      );
      expect(
        css,
        contains('/* Regenerate: dart run utopia_design_tools:generate_twin tokens/utopia.tokens.json */'),
      );
      expect(css, contains('/* profileVersion: 0.2.0 */'));
    });

    test('is idempotent: generating twice from the same input produces identical bytes', () {
      final first = generateCss(canonicalDocument(), inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      final second = generateCss(
        canonicalDocument(),
        inputPath: 'tokens/utopia.tokens.json',
        profileVersion: '0.2.0',
      );
      expect(first, equals(second));
    });
  });

  group('generateTailwind golden lines', () {
    test('maps color/spacing/radius/shadow/fontWeight/breakpoint families per the SPEC table', () {
      final tailwind = generateTailwind(
        canonicalDocument(),
        inputPath: 'tokens/utopia.tokens.json',
        profileVersion: '0.2.0',
      );
      expect(tailwind, contains('  --color-primary: #536dfe;'));
      expect(tailwind, contains('  --spacing-md: 12px;'));
      expect(tailwind, contains('  --radius-sm: 6px;'));
      expect(tailwind, contains('  --shadow-sm: 0 1px 6px 0 rgb(0 0 0 / 0.051);'));
      expect(tailwind, contains('  --font-weight-semi-bold: 600;'));
      expect(tailwind, contains('  --breakpoint-tablet: 600px;'));
      expect(tailwind, contains('  --font-header: Sora;'));
      expect(tailwind, contains('  --color-text-style-header: rgb(0 0 0 / 0.8667);'));
    });

    test('families with no stable namespace are kept as comments, not dropped', () {
      final tailwind = generateTailwind(
        canonicalDocument(),
        inputPath: 'tokens/utopia.tokens.json',
        profileVersion: '0.2.0',
      );
      expect(tailwind, contains('  /* --utopia-x: 4; */'));
      expect(tailwind, contains('  /* --utopia-border-hairline: 1px; */'));
      expect(tailwind, contains('  /* --utopia-duration-md: 200ms; */'));
      expect(tailwind, contains('  /* --utopia-theme-border-radius: 6px; */'));
    });

    test('is idempotent', () {
      final first = generateTailwind(
        canonicalDocument(),
        inputPath: 'tokens/utopia.tokens.json',
        profileVersion: '0.2.0',
      );
      final second = generateTailwind(
        canonicalDocument(),
        inputPath: 'tokens/utopia.tokens.json',
        profileVersion: '0.2.0',
      );
      expect(first, equals(second));
    });
  });

  group('typography inner aliases', () {
    test('an aliased fontSize/fontWeight/letterSpacing resolves to its target value in tokens.css', () {
      var document = documentWithHeaderProperty('fontSize', '{spacing.xxl}');
      var css = generateCss(document, inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-text-style-header-font-size: 32px;'));

      document = documentWithHeaderProperty('fontWeight', '{fontWeight.bold}');
      css = generateCss(document, inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-text-style-header-font-weight: 700;'));

      document = documentWithHeaderProperty('letterSpacing', '{spacing.xxs}');
      css = generateCss(document, inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  --utopia-text-style-header-letter-spacing: 2px;'));
    });

    test('an inner alias on a property tailwind does not map leaves the mapped lines intact', () {
      final tailwind = generateTailwind(
        documentWithHeaderProperty('fontSize', '{spacing.xxl}'),
        inputPath: 'tokens/utopia.tokens.json',
        profileVersion: '0.2.0',
      );
      expect(tailwind, contains('  --font-header: Sora;'));
    });

    test('an aliased fontFamily that resolves to a non-name token fails loudly in both stylesheets', () {
      // Before inner aliases were resolved, both generators emitted the raw
      // "{spacing.md}" text as if it were a font family name.
      final matcher = throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('"textStyle.header.fontFamily" did not resolve to a font family name'),
        ),
      );

      expect(
        () => generateCss(
          documentWithHeaderProperty('fontFamily', '{spacing.md}'),
          inputPath: 'tokens/utopia.tokens.json',
          profileVersion: '0.2.0',
        ),
        matcher,
      );
      expect(
        () => generateTailwind(
          documentWithHeaderProperty('fontFamily', '{spacing.md}'),
          inputPath: 'tokens/utopia.tokens.json',
          profileVersion: '0.2.0',
        ),
        matcher,
      );
    });

    test('an aliased fontWeight/fontSize that resolves to the wrong kind of token names the path', () {
      // A sub-value alias is only checked for resolvability by the token
      // gates, never for the kind of token it lands on, so these documents
      // are schema-valid: the generator has to reject them itself, with a
      // message naming the path, rather than failing on a raw cast.
      expect(
        () => generateCss(
          documentWithHeaderProperty('fontWeight', '{spacing.md}'),
          inputPath: 'tokens/utopia.tokens.json',
          profileVersion: '0.2.0',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('"textStyle.header.fontWeight" did not resolve to a number'),
          ),
        ),
      );
      expect(
        () => generateCss(
          documentWithHeaderProperty('fontSize', '{fontWeight.bold}'),
          inputPath: 'tokens/utopia.tokens.json',
          profileVersion: '0.2.0',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('"textStyle.header.fontSize" did not resolve to a dimension'),
          ),
        ),
      );
    });
  });

  group('font family serialization', () {
    test('a hostile family name is quoted and escaped instead of injecting into the stylesheet', () {
      // A raw `"` closes the quoted name and a raw `;`/`}` ends the
      // declaration and the :root block, so an unescaped name could append
      // arbitrary rules to the generated stylesheet.
      final document = documentWithHeaderProperty('fontFamily', <String>[
        'Ev"il; } body { color: red',
        r'Back\slash',
        'Sora Sans',
        'sans-serif',
      ]);

      const expected =
          r'--utopia-text-style-header-font-family: "Ev\"il; } body { color: red", "Back\\slash", "Sora Sans", sans-serif;';
      final css = generateCss(document, inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(css, contains('  $expected'));
      // The `}` inside the name never closes the :root block: exactly one
      // closing brace, the generator's own.
      expect(css.split('\n').where((line) => line == '}').length, 1);

      // The Tailwind variant shares serializeFontFamily, so it is hardened
      // by the same fix.
      final tailwind = generateTailwind(document, inputPath: 'tokens/utopia.tokens.json', profileVersion: '0.2.0');
      expect(
        tailwind,
        contains(r'--font-header: "Ev\"il; } body { color: red", "Back\\slash", "Sora Sans", sans-serif;'),
      );
    });

    test('a plain identifier family stays bare and a generic keyword is never quoted', () {
      final css = generateCss(
        documentWithHeaderProperty('fontFamily', <String>['Sora', 'ui-sans-serif']),
        inputPath: 'tokens/utopia.tokens.json',
        profileVersion: '0.2.0',
      );
      expect(css, contains('  --utopia-text-style-header-font-family: Sora, ui-sans-serif;'));
    });
  });

  group('shadow layer aliases', () {
    /// The canonical document with `shadow.lg` doctored to [layerCount]
    /// identical layers and `shadow.md` replaced by a single per-layer alias
    /// to `shadow.lg` - the same fixture shape theme_gen_test uses, so both
    /// generators are held to the same contract.
    TokenDocument documentAliasingShadowLg({required int layerCount}) {
      final raw = loadCanonical();
      final shadowGroup = raw['shadow'] as Map<String, dynamic>;
      final lg = shadowGroup['lg'] as Map<String, dynamic>;
      final firstLayer = (lg[r'$value'] as List).first;
      lg[r'$value'] = [for (var i = 0; i < layerCount; i++) firstLayer];
      (shadowGroup['md'] as Map<String, dynamic>)[r'$value'] = ['{shadow.lg}'];
      return TokenDocument.parse(raw);
    }

    /// The serialized value of custom property [name] in [css].
    String valueOf(String css, String name) {
      final line = const LineSplitter().convert(css).firstWhere((l) => l.trim().startsWith('$name:'));
      return line.substring(line.indexOf(':') + 1).trim();
    }

    test('a per-layer alias to a single-layer shadow resolves that layer', () {
      final css = generateCss(
        documentAliasingShadowLg(layerCount: 1),
        inputPath: 'tokens/utopia.tokens.json',
        profileVersion: '0.2.0',
      );
      expect(valueOf(css, '--utopia-shadow-md'), valueOf(css, '--utopia-shadow-lg'));
    });

    test('a per-layer alias to a multi-layer shadow is a hard error in both stylesheets', () {
      // generate_theme already refuses this; emitting only the first layer
      // here would drop the rest of the referenced shadow and let the twin
      // and the Dart theme disagree about the same document.
      final matcher = throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('"shadow.md"'), contains('{shadow.lg}'), contains('has 2 layers')),
        ),
      );

      expect(
        () => generateCss(
          documentAliasingShadowLg(layerCount: 2),
          inputPath: 'tokens/utopia.tokens.json',
          profileVersion: '0.2.0',
        ),
        matcher,
      );
      expect(
        () => generateTailwind(
          documentAliasingShadowLg(layerCount: 2),
          inputPath: 'tokens/utopia.tokens.json',
          profileVersion: '0.2.0',
        ),
        matcher,
      );
    });
  });

  group('CLI level: generation errors (real bin/generate_twin.dart)', () {
    test('an incoherent-but-schema-valid document exits 1 with the message and writes nothing', () async {
      final scratch = Directory.systemTemp.createTempSync('generate_twin_bad_alias_');
      addTearDown(() => scratch.deleteSync(recursive: true));

      final raw = loadCanonical();
      final header = (raw['textStyle'] as Map<String, dynamic>)['header'] as Map<String, dynamic>;
      (header[r'$value'] as Map<String, dynamic>)['fontWeight'] = '{spacing.md}';
      final tokensFile = File(p.join(scratch.path, 'tokens.json'))
        ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(raw));
      final outputDir = Directory(p.join(scratch.path, 'twin'));

      final result = await Process.run('dart', [
        'run',
        p.join(Directory.current.path, 'bin', 'generate_twin.dart'),
        tokensFile.path,
        '-o',
        outputDir.path,
      ], workingDirectory: Directory.current.path);

      expect(result.exitCode, 1, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      final errorText = result.stderr as String;
      expect(errorText, contains('generate_twin: "textStyle.header.fontWeight" did not resolve to a number'));
      expect(errorText, isNot(contains('Unhandled exception')));
      expect(errorText.split('generate_twin:').length, 2, reason: 'the tool-name prefix is not doubled');
      expect(outputDir.existsSync(), isFalse, reason: 'nothing is written when generation fails');
    });

    test('a malformed gallery marker exits 1 and leaves every existing twin file byte-identical', () async {
      // The gallery is composed LAST but must fail FIRST: composing it after
      // tokens.css / tokens.tailwind.css / DESIGN.md had already been written
      // is what used to leave a half-written twin behind on a bad marker.
      final scratch = Directory.systemTemp.createTempSync('generate_twin_bad_marker_');
      addTearDown(() => scratch.deleteSync(recursive: true));

      final tokensFile = File(p.join(scratch.path, 'tokens.json'))
        ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(loadCanonical()));

      // A twin whose generated surfaces are already on disk, all three
      // deliberately stale, so a write of any of them shows up as a diff.
      final outputDir = Directory(p.join(scratch.path, 'twin'))..createSync(recursive: true);
      const staleMarker = '/* stale */\n';
      final existing = <String, String>{
        'tokens.css': staleMarker,
        'tokens.tailwind.css': staleMarker,
        'DESIGN.md': '---\nname: Stale\n---\n\n## Overview\n\nStale.\n',
        'components.html': '<html><body>\n'
            '<section class="twin-section" data-utopia-id="button">\n'
            '  <button class="utopia-button" data-utopia-id="button">Go</button>\n'
            '</section>\n</body></html>\n',
        'gallery.html': '<html><body>previous gallery</body></html>\n',
        // A trailing marker on a line that does not START with `<!--`: the
        // shape that used to slip through as an ordinary comment.
        'gallery.src.html': '<main>\n  <div> <!-- utopia-specimen: button -->\n</main>\n',
      };
      for (final entry in existing.entries) {
        File(p.join(outputDir.path, entry.key)).writeAsStringSync(entry.value);
      }

      final result = await Process.run('dart', [
        'run',
        p.join(Directory.current.path, 'bin', 'generate_twin.dart'),
        tokensFile.path,
        '-o',
        outputDir.path,
      ], workingDirectory: Directory.current.path);

      expect(result.exitCode, 1, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      expect(result.stderr as String, contains('malformed specimen marker'));
      for (final entry in existing.entries) {
        expect(
          File(p.join(outputDir.path, entry.key)).readAsStringSync(),
          equals(entry.value),
          reason: '${entry.key} was rewritten before the gallery failed',
        );
      }
      expect(
        outputDir.listSync().map((e) => p.basename(e.path)).toSet(),
        equals(existing.keys.toSet()),
        reason: 'no new file is created either',
      );
    });
  });

  group('DESIGN.md front matter', () {
    test('emits name, colors, typography, rounded and spacing per SPEC 4.6', () {
      final frontMatter = buildFrontMatterBody(canonicalDocument());
      expect(frontMatter, contains('name: Utopia'));
      expect(frontMatter, contains('  primary: "#536dfe"'));
      expect(frontMatter, contains('    fontFamily: "Sora"'));
      expect(frontMatter, contains('    fontSize: "24px"'));
      expect(frontMatter, contains('    fontWeight: 600'));
      expect(frontMatter, contains('  sm: "6px"')); // rounded.sm
      expect(frontMatter, contains('  md: "12px"')); // spacing.md
    });

    test('is idempotent', () {
      final first = buildFrontMatterBody(canonicalDocument());
      final second = buildFrontMatterBody(canonicalDocument());
      expect(first, equals(second));
    });

    test('splice preserves a doctored body byte-for-byte', () {
      final frontMatter = buildFrontMatterBody(canonicalDocument());
      const doctoredBody = '''
## Overview

A hand-edited paragraph a maintainer wrote after the skeleton was generated,
with trailing whitespace and unusual   spacing preserved.

## Colors

Some more hand-written prose that must survive regeneration untouched.
''';
      final original = '---\nname: Utopia\ncolors:\n  primary: "#000000"\n---\n$doctoredBody';

      final spliced = spliceDesignMd(original, frontMatter).content;

      expect(spliced, contains(doctoredBody));
      expect(spliced, isNot(contains('primary: "#000000"')));
      expect(spliced, contains('primary: "#536dfe"'));

      // Regenerating again with an unrelated front matter body must not
      // disturb the body a second time.
      final splicedAgain = spliceDesignMd(spliced, frontMatter).content;
      expect(splicedAgain, equals(spliced));
    });

    test('missing closing marker preserves the hand-authored body and warns', () {
      final frontMatter = buildFrontMatterBody(canonicalDocument());
      const realBody = '## Overview\n\nHand-written prose whose closing marker got lost in a bad merge.\n';
      const malformed = '---\nname: Utopia\ncolors:\n  primary: "#000000"\n$realBody';

      final splice = spliceDesignMd(malformed, frontMatter);

      expect(splice.content, contains(realBody), reason: 'the body must never be discarded');
      expect(splice.warning, isNotNull);
      expect(splice.warning, contains('no closing'));
    });

    test('content without front matter is kept entirely as body, with a warning', () {
      final frontMatter = buildFrontMatterBody(canonicalDocument());
      const bareBody = '## Overview\n\nProse that never had front matter.\n';

      final splice = spliceDesignMd(bareBody, frontMatter);

      expect(splice.content, contains(bareBody));
      expect(splice.content, startsWith('---\nname: Utopia\n'));
      expect(splice.warning, isNotNull);
    });

    test('writes front matter plus the full skeleton body when the file is absent', () {
      final frontMatter = buildFrontMatterBody(canonicalDocument());
      final result = spliceDesignMd(null, frontMatter).content;

      expect(result, startsWith('---\nname: Utopia\n'));
      expect(result, contains(designMdSkeletonBody));
      expect(result, contains('## Overview'));
      expect(result, contains("## Do's and Don'ts"));
    });
  });
}
