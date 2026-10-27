# Changelog

## 0.1.0

Initial release of the Utopia Design Protocol tooling for `utopia_ui` (protocol 0.4.0):

- `validate_tokens` - protocol gates over DTCG token documents, `--fix` for mechanical
  base-unit re-derivation and color-hex resync.
- `export_tokens` - canonical DTCG export of `UtopiaThemeData.defaultTheme` (maintainer).
- `generate_theme` - token document to `buildUtopiaTheme()` Dart codegen, round-trip proven
  against the default theme.
- `generate_manifest` / `validate_manifest` - component-manifest generation (library and
  `--project` modes, merged view) with drift, namespace and freshness gates.
- `generate_twin` / `validate_twin` - design-surface codegen (`tokens.css`, Tailwind
  `@theme` variant, `DESIGN.md` front matter, gallery composition via `--compose-gallery`,
  section skeletons via `--scaffold <id>`) and the twin linter: token literals, front-matter
  freshness, manifest coverage and state-class parity.
- Twin elevation parity: `generate_twin` paints every `shadow.*` layer in `color.shadow`'s hue
  at that layer's own alpha, exactly as the runtime does, in both `tokens.css` and the Tailwind
  variant. A rebranded shadow hue now reaches the twin, not just the Flutter app. A document
  without `color.shadow` (pre-0.4.0) keeps each layer's own colour.
- `generate_manifest --project` drops a `design/.gitignore` entry for `merged.manifest.json`
  (created if absent, appended once otherwise, never rewriting a consumer's own entries): the
  merged manifest is a derived view whose library half is a byte copy of the pub-cache
  manifest, so consumer repos stop versioning it by default. SPEC 7 documents the consumer
  versioning policy.
- `generate_theme --check` - freshness gate for a consumer's generated theme file: exits 1
  on drift and writes nothing.

Naming note for the Tailwind `@theme` output: role names are kebab-cased on camelCase
boundaries, exactly like `tokens.css`'s `--utopia-*` properties - a `textStyle.bodyLarge`
role maps to `--font-body-large` / `--color-text-style-body-large`, not `--font-bodyLarge`.
Roles that are already lower-case (every role in the packaged default token document) are
unaffected. `validate_twin` now byte-compares a committed `tokens.tailwind.css` against its
generator, so a rename in this mapping is caught rather than left to drift.
