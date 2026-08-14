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

Naming note for the Tailwind `@theme` output: role names are kebab-cased on camelCase
boundaries, exactly like `tokens.css`'s `--utopia-*` properties - a `textStyle.bodyLarge`
role maps to `--font-body-large` / `--color-text-style-body-large`, not `--font-bodyLarge`.
Roles that are already lower-case (every role in the packaged default token document) are
unaffected. `validate_twin` now byte-compares a committed `tokens.tailwind.css` against its
generator, so a rename in this mapping is caught rather than left to drift.
