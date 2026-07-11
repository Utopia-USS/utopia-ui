# Changelog

## 0.1.0

Initial release of the Utopia Design Protocol tooling (protocol 0.2.0):

- `validate_tokens` - protocol gates over DTCG token documents, `--fix` for mechanical
  base-unit re-derivation and color-hex resync.
- `export_tokens` - canonical DTCG export of `UtopiaThemeData.defaultTheme` (maintainer).
- `generate_theme` - token document to `buildUtopiaTheme()` Dart codegen, round-trip proven
  against the default theme.
- `generate_manifest` / `validate_manifest` - component-manifest generation (library and
  `--project` modes, merged view) with drift, namespace and freshness gates.
- `generate_twin` / `validate_twin` - design-surface codegen (`tokens.css`, Tailwind
  `@theme` variant, `DESIGN.md` front matter) and the twin literals linter.
