# utopia_design_tools

Design-protocol tooling for [`utopia_ui`](https://github.com/Utopia-USS/utopia-ui): token
export/validation, manifest generation, theme and twin codegen. This package is the
implementation of the [Utopia Design Protocol](../../protocol/SPEC.md).

## Commands

| Command | Role |
|---|---|
| `export_tokens` | export a `UtopiaThemeData` (default: `defaultTheme`) to a token document |
| `validate_tokens` | run the token document validation gates (protocol SPEC 2.7) |

More commands (`generate_manifest`, `validate_manifest`, `generate_theme`, `generate_twin`,
`validate_twin`) are planned per the protocol's tooling surface (SPEC section 5) and will land
in later tasks.

## export_tokens is maintainer-only

`export_tokens` reads the compiled `UtopiaThemeData.defaultTheme` out of the Flutter
`utopia_ui` package at runtime, so it needs a full checkout of the `utopia_ui` repository (this
package developed nested under `tool/`) plus the Flutter SDK. It is not something a consumer
app runs; it is how *this repo* regenerates the canonical `tokens/utopia.tokens.json` whenever
`UtopiaThemeData.defaultTheme` changes. Everything else in this package (`validate_tokens` and,
later, the other pure-Dart tools) is an ordinary consumer-facing dev dependency: run
`flutter pub add --dev utopia_design_tools` in a consumer project and invoke commands with
`dart run utopia_design_tools:<command>` - no Flutter SDK access to `utopia_ui` internals
required.

## Usage

From the `utopia-ui` repo root (after `flutter pub get` inside `tool/utopia_design_tools`):

```sh
dart run tool/utopia_design_tools/bin/export_tokens.dart
dart run tool/utopia_design_tools/bin/validate_tokens.dart tokens/utopia.tokens.json
```

Or, once this package is added as a dependency, `dart run utopia_design_tools:export_tokens`
and `dart run utopia_design_tools:validate_tokens` from within its own package directory.

Both commands accept `--json` for machine-readable output and exit 0 on success, 1 on
validation/generation failure, 2 on usage or I/O error, matching the shared conventions in
protocol SPEC section 5.
