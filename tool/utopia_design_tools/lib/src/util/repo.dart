import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Locates repo and package roots needed by the CLIs, without ever importing
/// Flutter: everything here is plain `dart:io` and `package:path`.
class RepoLocator {
  /// Walks upward from [start] (default: the current working directory)
  /// looking for a `pubspec.yaml` whose `name:` field is `utopia_ui`. Returns
  /// the directory containing it, or `null` if none is found before reaching
  /// the filesystem root.
  static Directory? findUtopiaUiRepoRoot({Directory? start}) {
    var dir = start ?? Directory.current;
    while (true) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync() && _pubspecNameIs(pubspec, 'utopia_ui')) {
        return dir;
      }
      final parent = dir.parent;
      if (p.equals(parent.path, dir.path)) {
        return null;
      }
      dir = parent;
    }
  }

  /// Walks upward from [start] looking for a `.dart_tool/package_config.json`
  /// and resolves the `utopia_ui` package's `rootUri` from it. This is how a
  /// tool run from inside a consumer project (or this repo's tool package)
  /// finds the `utopia_ui` package root - and therefore its bundled
  /// `protocol/schemas/*.schema.json` - even when `utopia_ui` is a pub
  /// dependency rather than a sibling checkout.
  ///
  /// Returns `null` when no package config is found, or it does not resolve
  /// a `utopia_ui` entry.
  static Directory? resolveUtopiaUiPackageRoot({Directory? start}) {
    var dir = start ?? Directory.current;
    while (true) {
      final configFile = File(p.join(dir.path, '.dart_tool', 'package_config.json'));
      if (configFile.existsSync()) {
        final root = _rootUriFromPackageConfig(configFile, 'utopia_ui');
        if (root != null) {
          return root;
        }
      }
      final parent = dir.parent;
      if (p.equals(parent.path, dir.path)) {
        return null;
      }
      dir = parent;
    }
  }

  /// Resolves the `protocol/schemas/tokens.schema.json` file: prefers a
  /// direct sibling-repo lookup (this repo checkout), falling back to the
  /// `utopia_ui` package root resolved via [resolveUtopiaUiPackageRoot].
  /// Returns `null` when neither lookup succeeds.
  static File? findTokensSchema({Directory? start}) {
    final repoRoot = findUtopiaUiRepoRoot(start: start);
    if (repoRoot != null) {
      final schema = File(p.join(repoRoot.path, 'protocol', 'schemas', 'tokens.schema.json'));
      if (schema.existsSync()) {
        return schema;
      }
    }
    final packageRoot = resolveUtopiaUiPackageRoot(start: start);
    if (packageRoot != null) {
      final schema = File(p.join(packageRoot.path, 'protocol', 'schemas', 'tokens.schema.json'));
      if (schema.existsSync()) {
        return schema;
      }
    }
    return null;
  }

  static bool _pubspecNameIs(File pubspec, String name) {
    final content = pubspec.readAsStringSync();
    for (final line in const LineSplitter().convert(content)) {
      final match = RegExp(r'^name:\s*(\S+)\s*$').firstMatch(line);
      if (match != null) {
        return match.group(1) == name;
      }
    }
    return false;
  }

  static Directory? _rootUriFromPackageConfig(File configFile, String packageName) {
    final dynamic decoded = jsonDecode(configFile.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final packages = decoded['packages'];
    if (packages is! List) {
      return null;
    }
    for (final entry in packages) {
      if (entry is Map<String, dynamic> && entry['name'] == packageName) {
        final rootUri = entry['rootUri'] as String?;
        if (rootUri == null) {
          return null;
        }
        // Per the package_config.json spec, relative URIs are resolved
        // against the location of the config file itself (i.e. the
        // `.dart_tool` directory), not its parent.
        final resolved = _resolveRootUri(rootUri, configFile.parent);
        return resolved;
      }
    }
    return null;
  }

  static Directory _resolveRootUri(String rootUri, Directory dartToolDir) {
    if (rootUri.startsWith('file://')) {
      return Directory(Uri.parse(rootUri).toFilePath());
    }
    return Directory(p.normalize(p.join(dartToolDir.path, rootUri)));
  }
}
