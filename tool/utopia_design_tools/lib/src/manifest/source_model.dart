/// Parses the `utopia_ui` barrel (`lib/utopia_ui.dart`) and every file it
/// exports into a flat, queryable picture of the package's public surface:
/// classes, enums, top-level functions and typedefs, keyed by name.
///
/// Parser-based only (package:analyzer's `parseString`/`parseFile`, parsed AST,
/// no element resolution, no analysis context) - see `ledger/checkpoints/A3-spec.md`
/// for the architecture rationale.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

/// A single parsed source file exported (transitively, one hop) from the
/// barrel, with its declarations pre-sorted by kind.
class ParsedFile {
  /// Creates a parsed file record.
  ParsedFile({
    required this.repoRelativePath,
    required this.unit,
    required this.classes,
    required this.enums,
    required this.functions,
    required this.typedefs,
  });

  /// Repo-relative path (e.g. `lib/src/widget/button/utopia_button.dart`),
  /// always forward-slashed regardless of host platform.
  final String repoRelativePath;

  /// The parsed compilation unit (kept for whole-file AST visitors, e.g. the
  /// token-bindings extractor and the composes scan).
  final CompilationUnit unit;

  /// Every class declaration in this file (component/model candidates and
  /// private helper widgets alike).
  final List<ClassDeclaration> classes;

  /// Every top-level enum declaration in this file.
  final List<EnumDeclaration> enums;

  /// Every top-level function declaration in this file (helpers/hooks).
  final List<FunctionDeclaration> functions;

  /// Every top-level typedef (`GenericTypeAlias`/`FunctionTypeAlias`) in this
  /// file.
  final List<NamedCompilationUnitMember> typedefs;
}

/// The full parsed picture of `utopia_ui`'s public surface: every file
/// exported (directly or transitively through further `export`s, though in
/// practice the barrel is single-level) from `lib/utopia_ui.dart`.
class SourceModel {
  SourceModel._({
    required this.utopiaUiRoot,
    required this.files,
    required this.classesByName,
    required this.enumsByName,
  });

  /// Parses the barrel at `<utopiaUiRoot>/lib/utopia_ui.dart` and every file
  /// it exports, returning the assembled model.
  ///
  /// Only `export` directives are followed (not `import`s): the barrel's
  /// exports are, by charter, the entire public surface.
  factory SourceModel.parse(Directory utopiaUiRoot) {
    // package:analyzer's parseFile requires an absolute, normalized path (no
    // "..": "path must be normalized"); callers may reasonably pass a
    // Directory built by joining ".." segments (e.g. a test walking up from
    // the tool package to the repo root), so normalize defensively here.
    final normalizedRoot = p.normalize(utopiaUiRoot.absolute.path);
    final barrelPath = p.join(normalizedRoot, 'lib', 'utopia_ui.dart');
    final barrelFile = File(barrelPath);
    if (!barrelFile.existsSync()) {
      throw StateError('barrel not found: $barrelPath');
    }
    final barrelUnit = parseFile(path: barrelPath, featureSet: FeatureSet.latestLanguageVersion()).unit;

    final files = <ParsedFile>[];
    final libDir = p.join(normalizedRoot, 'lib');
    for (final directive in barrelUnit.directives) {
      if (directive is! ExportDirective) continue;
      final uriValue = directive.uri.stringValue;
      if (uriValue == null || !uriValue.endsWith('.dart') || uriValue.contains(':')) {
        // Skip package: exports (e.g. fast_immutable_collections re-export) -
        // those are third-party types, not utopia_ui source.
        continue;
      }
      final absolutePath = p.normalize(p.join(libDir, uriValue));
      final relativePath = p.relative(absolutePath, from: normalizedRoot);
      files.add(_parseOneFile(absolutePath, _toForwardSlash(relativePath)));
    }

    final classesByName = <String, ClassDeclaration>{};
    final enumsByName = <String, EnumDeclaration>{};
    for (final file in files) {
      for (final cls in file.classes) {
        classesByName[cls.name.lexeme] = cls;
      }
      for (final enumDecl in file.enums) {
        enumsByName[enumDecl.name.lexeme] = enumDecl;
      }
    }

    return SourceModel._(
      utopiaUiRoot: Directory(normalizedRoot),
      files: files,
      classesByName: classesByName,
      enumsByName: enumsByName,
    );
  }

  /// Parses every `.dart` file under `<projectRoot>/lib/` (recursive,
  /// depth-first, sorted for determinism), regardless of barrel exports.
  ///
  /// Used for `generate_manifest --project` (SPEC 3.8): a consumer project's
  /// custom components need not be barrel-exported, so extraction scans the
  /// whole `lib/` tree instead of following `export` directives from a
  /// package barrel.
  factory SourceModel.parseProjectLib(Directory projectRoot) {
    final normalizedRoot = p.normalize(projectRoot.absolute.path);
    final libDir = Directory(p.join(normalizedRoot, 'lib'));
    if (!libDir.existsSync()) {
      throw StateError('project lib/ not found: ${libDir.path}');
    }

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final files = <ParsedFile>[
      for (final file in dartFiles)
        _parseOneFile(p.normalize(file.absolute.path), _toForwardSlash(p.relative(file.path, from: normalizedRoot))),
    ];

    final classesByName = <String, ClassDeclaration>{};
    final enumsByName = <String, EnumDeclaration>{};
    for (final file in files) {
      for (final cls in file.classes) {
        classesByName[cls.name.lexeme] = cls;
      }
      for (final enumDecl in file.enums) {
        enumsByName[enumDecl.name.lexeme] = enumDecl;
      }
    }

    return SourceModel._(
      utopiaUiRoot: Directory(normalizedRoot),
      files: files,
      classesByName: classesByName,
      enumsByName: enumsByName,
    );
  }

  /// The package root this model was parsed from (the `utopia_ui` checkout
  /// for [SourceModel.parse], or the consumer project root for
  /// [SourceModel.parseProjectLib]).
  final Directory utopiaUiRoot;

  /// Every exported file, in barrel export order.
  final List<ParsedFile> files;

  /// Every exported class, keyed by its Dart name (last declaration wins on
  /// a name collision, which should not occur in a well-formed barrel).
  final Map<String, ClassDeclaration> classesByName;

  /// Every exported top-level enum, keyed by its Dart name.
  final Map<String, EnumDeclaration> enumsByName;

  /// The [ParsedFile] that declares [className], or `null` if not found.
  ParsedFile? fileDeclaring(String className) {
    for (final file in files) {
      if (file.classes.any((c) => c.name.lexeme == className)) return file;
    }
    return null;
  }

  /// The [ParsedFile] declaring the top-level enum named [enumName], or
  /// `null` if not found.
  ParsedFile? fileDeclaringEnum(String enumName) {
    for (final file in files) {
      if (file.enums.any((e) => e.name.lexeme == enumName)) return file;
    }
    return null;
  }

  static ParsedFile _parseOneFile(String absolutePath, String repoRelativePath) {
    final unit = parseFile(path: absolutePath, featureSet: FeatureSet.latestLanguageVersion()).unit;
    final classes = <ClassDeclaration>[];
    final enums = <EnumDeclaration>[];
    final functions = <FunctionDeclaration>[];
    final typedefs = <NamedCompilationUnitMember>[];
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        classes.add(declaration);
      } else if (declaration is EnumDeclaration) {
        enums.add(declaration);
      } else if (declaration is FunctionDeclaration) {
        functions.add(declaration);
      } else if (declaration is FunctionTypeAlias || declaration is GenericTypeAlias) {
        typedefs.add(declaration as NamedCompilationUnitMember);
      }
    }
    return ParsedFile(
      repoRelativePath: repoRelativePath,
      unit: unit,
      classes: classes,
      enums: enums,
      functions: functions,
      typedefs: typedefs,
    );
  }

  static String _toForwardSlash(String path) => path.replaceAll(r'\', '/');
}

/// Whether [name] is a public Dart identifier (does not start with `_`).
bool isPublicName(String name) => !name.startsWith('_');

/// Extracts a declaration's `///` doc comment as raw joined lines (still
/// carrying the leading `/// ` marker per line), or `null` if there is none.
String? rawDocComment(Comment? comment) {
  if (comment == null || comment.tokens.isEmpty) return null;
  return comment.tokens.map((t) => t.lexeme).join('\n');
}

/// Cleans a raw `///`-joined doc comment into the manifest's single-line
/// description: strips the `/// ` marker from each line, keeps only the
/// first paragraph (up to the first blank doc line), unwraps `[Bracket]`
/// dartdoc references to their plain text, and collapses internal newlines
/// to single spaces.
String? cleanDescription(String? raw) {
  if (raw == null) return null;
  final lines = raw.split('\n');
  final paragraph = <String>[];
  for (final line in lines) {
    final stripped = _stripDocMarker(line);
    if (stripped.trim().isEmpty) {
      if (paragraph.isNotEmpty) break;
      continue;
    }
    paragraph.add(stripped);
  }
  if (paragraph.isEmpty) return null;
  final joined = paragraph.join(' ').trim();
  final unbracketed = joined.replaceAllMapped(RegExp(r'\[([^\]]+)\]'), (m) => m.group(1)!);
  return _collapseWhitespace(unbracketed);
}

String _stripDocMarker(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('/// ')) return trimmed.substring(4);
  if (trimmed.startsWith('///')) return trimmed.substring(3);
  return trimmed;
}

String _collapseWhitespace(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();
