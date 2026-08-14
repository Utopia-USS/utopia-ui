/// Renders a parsed [TokenDocument] into `twin/tokens.tailwind.css` (protocol
/// SPEC section 4.3): a single Tailwind v4 `@theme { ... }` block mapping the
/// token families that have a stable Tailwind namespace, plus a comment line
/// for every token in a family that has none, so nothing is silently dropped.
///
/// Reuses the naming/serialization helpers from `css_generator.dart` so the
/// two twin stylesheets never disagree on how a value prints.
library;

import 'package:utopia_design_tools/src/dtcg/token_document.dart';
import 'package:utopia_design_tools/src/twin/css_generator.dart';

/// Kebab-cases a single path segment (camelCase split, e.g. `semiBold` ->
/// `semi-bold`, `chipBackground` -> `chip-background`) - the same
/// segment-casing rule [cssVarName] applies per path segment, exposed here
/// standalone for the Tailwind leaf-name mappings (`--color-<name-kebab>`,
/// `--font-weight-<name-kebab>`).
String _kebabSegment(String segment) => cssVarName(segment).substring('--utopia-'.length);

/// One line to print inside the `@theme { ... }` block: either a live
/// Tailwind variable declaration or a `/* ... */` comment for a family with no
/// stable namespace (protocol SPEC 4.3).
class TailwindLine {
  const TailwindLine._(this.text);

  /// A live `--namespace-name: value;` declaration.
  factory TailwindLine.declaration(String name, String value) => TailwindLine._('  $name: $value;');

  /// A `/* --utopia-path: value; */` comment for an unmapped family.
  factory TailwindLine.comment(String name, String value) => TailwindLine._('  /* $name: $value; */');

  /// The rendered line text, ready to print inside the `@theme` block.
  final String text;
}

/// Walks [document] in token-tree order and produces the full ordered list of
/// [TailwindLine]s for the `@theme` block.
List<TailwindLine> buildTailwindLines(TokenDocument document) {
  final lines = <TailwindLine>[];
  final root = document.root;

  String scalarValue(TokenNode node) {
    final aliasPath = aliasPathOf(node.value);
    final value = aliasPath != null ? resolveAlias(document, aliasPath).terminal!.value : node.value;
    return _serializeLiteral(node.type, value);
  }

  // x: no stable namespace -> comment.
  final xNode = root.children['x'];
  if (xNode != null) {
    lines.add(TailwindLine.comment(cssVarName('x'), scalarValue(xNode)));
  }

  // spacing.<step> -> --spacing-<step>
  final spacingGroup = root.children['spacing'];
  if (spacingGroup != null) {
    for (final entry in spacingGroup.children.entries) {
      lines.add(TailwindLine.declaration('--spacing-${entry.key}', scalarValue(entry.value)));
    }
  }

  // radius.<step> -> --radius-<step>
  final radiusGroup = root.children['radius'];
  if (radiusGroup != null) {
    for (final entry in radiusGroup.children.entries) {
      lines.add(TailwindLine.declaration('--radius-${entry.key}', scalarValue(entry.value)));
    }
  }

  // border.*: no stable namespace -> comment.
  final borderGroup = root.children['border'];
  if (borderGroup != null) {
    for (final entry in borderGroup.children.entries) {
      lines.add(TailwindLine.comment(cssVarName(entry.value.path), scalarValue(entry.value)));
    }
  }

  // shadow.<step> -> --shadow-<step> (full box-shadow value list).
  final shadowGroup = root.children['shadow'];
  if (shadowGroup != null) {
    for (final entry in shadowGroup.children.entries) {
      lines.add(TailwindLine.declaration('--shadow-${entry.key}', serializeShadowValue(document, entry.value)));
    }
  }

  // fontWeight.<name> -> --font-weight-<name-kebab>
  final fontWeightGroup = root.children['fontWeight'];
  if (fontWeightGroup != null) {
    for (final entry in fontWeightGroup.children.entries) {
      lines.add(TailwindLine.declaration('--font-weight-${_kebabSegment(entry.key)}', scalarValue(entry.value)));
    }
  }

  // duration.*: no stable namespace -> comment.
  final durationGroup = root.children['duration'];
  if (durationGroup != null) {
    for (final entry in durationGroup.children.entries) {
      lines.add(TailwindLine.comment(cssVarName(entry.value.path), scalarValue(entry.value)));
    }
  }

  // breakpoint.<name> -> --breakpoint-<name>
  final breakpointGroup = root.children['breakpoint'];
  if (breakpointGroup != null) {
    for (final entry in breakpointGroup.children.entries) {
      lines.add(TailwindLine.declaration('--breakpoint-${entry.key}', scalarValue(entry.value)));
    }
  }

  // color.<name> -> --color-<name-kebab>
  final colorGroup = root.children['color'];
  if (colorGroup != null) {
    for (final entry in colorGroup.children.entries) {
      lines.add(TailwindLine.declaration('--color-${_kebabSegment(entry.key)}', scalarValue(entry.value)));
    }
  }

  // textStyle.<role>: fontFamily -> --font-<role>; the composite's other
  // properties have no stable Tailwind namespace of their own beyond
  // font-family, so only fontFamily is mapped live (per the SPEC 4.3 table).
  final textStyleGroup = root.children['textStyle'];
  final textStyleColorsGroup = root.children['textStyle-colors'];
  if (textStyleGroup != null) {
    for (final entry in textStyleGroup.children.entries) {
      final role = entry.key;
      final node = entry.value;
      final aliasPath = aliasPathOf(node.value);
      final value = aliasPath != null ? resolveAlias(document, aliasPath).terminal!.value as Map : node.value as Map;
      final fontFamilyCss = serializeFontFamily(document, 'textStyle.$role.fontFamily', value['fontFamily']);
      lines.add(TailwindLine.declaration('--font-${_kebabSegment(role)}', fontFamilyCss));
    }

    // textStyle-colors.<role> -> --color-text-style-<role>
    if (textStyleColorsGroup != null) {
      for (final entry in textStyleColorsGroup.children.entries) {
        final role = entry.key;
        final node = entry.value;
        final aliasPath = aliasPathOf(node.value);
        final value = aliasPath != null ? resolveAlias(document, aliasPath).terminal!.value : node.value;
        lines.add(
          TailwindLine.declaration(
            '--color-text-style-${_kebabSegment(role)}',
            serializeColor((value as Map).cast<String, dynamic>()),
          ),
        );
      }
    }
  }

  // theme.*: no stable namespace -> comment (dimensions and the
  // fieldContentPadding sub-group).
  final themeGroup = root.children['theme'];
  if (themeGroup != null) {
    for (final entry in themeGroup.children.entries) {
      final node = entry.value;
      if (node.isToken) {
        lines.add(TailwindLine.comment(cssVarName(node.path), scalarValue(node)));
      } else {
        for (final subEntry in node.children.entries) {
          lines.add(TailwindLine.comment(cssVarName(subEntry.value.path), scalarValue(subEntry.value)));
        }
      }
    }
  }

  return lines;
}

String _serializeLiteral(String? type, dynamic value) {
  switch (type) {
    case 'dimension':
      return serializeDimensionValue(((value as Map)['value'] as num).toDouble());
    case 'duration':
      return serializeDurationValue((value as Map)['value'] as num);
    case 'number':
      return serializeUnitlessNumber(value as num);
    case 'fontWeight':
      return serializeUnitlessNumber(value as num);
    case 'color':
      return serializeColor((value as Map).cast<String, dynamic>());
    default:
      throw StateError('generate_twin: unsupported scalar token \$type "$type"');
  }
}

/// Renders the full `tokens.tailwind.css` file text for [document], read from
/// [inputPath] and carrying [profileVersion] (both recorded in the header
/// comment, mirroring `tokens.css`).
String generateTailwind(TokenDocument document, {required String inputPath, required String profileVersion}) {
  final lines = buildTailwindLines(document);
  final buffer = StringBuffer();
  buffer.writeln('/* GENERATED by utopia_design_tools:generate_twin from $inputPath - do not edit. */');
  buffer.writeln('/* Regenerate: dart run utopia_design_tools:generate_twin $inputPath */');
  buffer.writeln('/* profileVersion: $profileVersion */');
  buffer.writeln('/* Tailwind v4 @theme mapping (protocol SPEC 4.3). Commented lines are token');
  buffer.writeln('   families with no stable Tailwind namespace - kept here so nothing is silently');
  buffer.writeln("   dropped; consume them via tokens.css's --utopia-* custom properties instead. */");
  buffer.writeln('@theme {');
  for (final line in lines) {
    buffer.writeln(line.text);
  }
  buffer.writeln('}');
  return buffer.toString();
}
