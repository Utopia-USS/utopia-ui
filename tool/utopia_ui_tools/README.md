<img src="https://raw.githubusercontent.com/Utopia-USS/utopia-ui/main/tool/utopia_ui_tools/docs/header.png" width="239" alt="Utopia UI Tools"/>

[![pub][pub_badge]][pub_link] [![publisher][publisher_badge]][publisher_link] [![license][license_badge]][license_link] [![style: utopia\_lints][style_badge]][style_link]

# utopia_ui_tools

Command-line tooling for the [Utopia Design Protocol](https://github.com/Utopia-USS/utopia-ui/blob/main/protocol/SPEC.md):
token validation and repair, theme and design-surface codegen, and component-manifest
generation for Flutter apps built on [utopia_ui](https://pub.dev/packages/utopia_ui).

It is what keeps an AI-assisted design workflow honest: the token document, the generated
Flutter theme, the HTML twin and the component manifest are checked against each other, so a
design that drifts from the code - or code that drifts from the design - fails a command
instead of reaching review.

Install as a dev dependency in a project that uses `utopia_ui`:

```sh
flutter pub add --dev utopia_ui_tools
```

Every command follows one contract: exit `0` = success, `1` = validation/generation failure
(findings on stdout, one per line, `ERROR <path>: <message>` / `WARN <path>: <message>`,
summary last), `2` = usage or I/O error. Every command accepts `--json` for machine-readable
output. Generated files are deterministic: the same input produces byte-identical output.

## Consumer commands (run inside your project)

| Command | What it does |
|---|---|
| `dart run utopia_ui_tools:validate_tokens` | Validates `design/tokens.json` against the protocol gates (schema, aliases, scale coherence, color coherence). `--fix` mechanically repairs base-unit derivations and color hex after a rescale. Prints a bootstrap copy command when no token document exists yet. |
| `dart run utopia_ui_tools:generate_theme` | Generates `lib/theme/utopia_theme.g.dart` with a `buildUtopiaTheme()` factory from your token document. Validates first; refuses to write on errors. Wire it: `UtopiaTheme(data: buildUtopiaTheme(), child: ...)`. |
| `dart run utopia_ui_tools:generate_twin` | Regenerates the design surface (`tokens.css`, `tokens.tailwind.css`, `DESIGN.md` front matter) from your token document into `./twin`. |
| `dart run utopia_ui_tools:validate_twin` | Lints a twin bundle: token-literal violations in hand-authored CSS, component-id coverage against the manifest, `tokens.css` freshness. On a generated-only twin (no `components.html`) the coverage gate auto-skips. |
| `dart run utopia_ui_tools:validate_manifest` | Validates a component manifest; with zero arguments it checks the shipped `utopia_ui` manifest against your resolved package version (the drift gate). Point it at `design/merged.manifest.json` to validate a merged view. |
| `dart run utopia_ui_tools:generate_manifest --project` | Registers your project's custom components (opt-in via `design/overlay/<component>.yaml`) and writes `design/project.manifest.json` plus the merged view `design/merged.manifest.json` for design tools. |

## Maintainer commands (require the utopia-ui repo checkout)

| Command | What it does |
|---|---|
| `dart run utopia_ui_tools:export_tokens` | Exports `UtopiaThemeData.defaultTheme` to the canonical `tokens/utopia.tokens.json` (captures live values via `flutter test`, so it needs the Flutter SDK and this repo). |
| `dart run utopia_ui_tools:generate_manifest` | Regenerates the shipped component manifest from `lib/` + the curated overlays. |
| `tool/utopia_ui_tools/smoke/run.sh` | The end-to-end smoke harness (in-repo pass, CLI regression, external-app e2e, screenshot captures). |

## Where the contracts live

- Protocol specification: [protocol/SPEC.md](https://github.com/Utopia-USS/utopia-ui/blob/main/protocol/SPEC.md)
- JSON Schemas: [protocol/schemas/](https://github.com/Utopia-USS/utopia-ui/tree/main/protocol/schemas)
- Versioning policy: [protocol/VERSIONING.md](https://github.com/Utopia-USS/utopia-ui/blob/main/protocol/VERSIONING.md)

The protocol artifacts themselves (canonical token document, component manifest, HTML twin)
ship inside the `utopia_ui` package and are resolved from your pub cache - these tools find
them through `.dart_tool/package_config.json`, no configuration needed.

## Related packages

| Package | What it adds |
|---|---|
| [utopia_ui](https://pub.dev/packages/utopia_ui) | The design system these tools validate and generate for |
| [utopia_hooks](https://pub.dev/packages/utopia_hooks) | State management with hooks |
| [utopia_arch](https://pub.dev/packages/utopia_arch) | The full architecture bundle |

Built by [Utopiasoft](https://utopiasoft.io).

## License

BSD-3-Clause. See [LICENSE](LICENSE).

[pub_badge]: https://img.shields.io/pub/v/utopia_ui_tools.svg?logo=dart
[pub_link]: https://pub.dev/packages/utopia_ui_tools
[publisher_badge]: https://img.shields.io/pub/publisher/utopia_ui_tools.svg?color=7A4FC2
[publisher_link]: https://pub.dev/publishers/utopiasoft.io
[license_badge]: https://img.shields.io/badge/license-BSD--3--Clause-2E8B57.svg
[license_link]: LICENSE
[style_badge]: https://img.shields.io/badge/style-utopia__lints-0B5EA2.svg
[style_link]: https://pub.dev/packages/utopia_lints
