---
name: utopia-design
description: >
  Entry point for the Utopia Design Protocol in a project that resolves
  utopia_ui: rebrandable DTCG design tokens, a component manifest, and an
  HTML twin, all shipped version-matched inside the utopia_ui package.
  Applies when: working with design/tokens.json, rebranding, importing a
  design (Figma DTCG export, tokens.css, handoff bundle), regenerating the
  Flutter theme or HTML twin, or building screens from a design. This is a
  THIN POINTER skill - the full skills live in the utopia-design plugin of
  the utopia-flutter-skills marketplace; install that plugin for the real
  workflows. Does NOT itself cover state management or app architecture.
license: BSD-2-Clause
metadata:
  author: UtopiaSoftware
  tags: flutter, dart, utopia_ui, design-tokens, dtcg, design-protocol
---

# Utopia Design Protocol - package entry point

This package ships the protocol artifacts, version-matched to the resolved
`utopia_ui`:

- `protocol/` - SPEC.md, VERSIONING.md, JSON Schemas
- `tokens/utopia.tokens.json` - DTCG export of the default theme
- `manifest/utopia.manifest.json` - the component registry
- `twin/` - the static HTML/CSS twin

Resolve the package root via `.dart_tool/package_config.json` (the
`utopia_ui` entry's `rootUri`); read artifacts from there, never from
memory - they match the resolved package version.

## Get the full skills

The complete skill set (edit/rebrand tokens, import external designs, sync
generated surfaces, build screens from the manifest) ships as the
`utopia-design` plugin in the `utopia-flutter-skills` marketplace:

    /plugin marketplace add Utopia-USS/utopia-flutter-skills
    /plugin install utopia-design@utopia-flutter-skills

Companion CLI tooling (validators, generators):

    flutter pub add --dev utopia_design_tools

(until it reaches pub.dev: a git dependency on the utopia-ui repo with
path `tool/utopia_design_tools` - the plugin's validation reference has
the exact snippet).

## Attribution

Built on [utopia_ui](https://pub.dev/packages/utopia_ui) and the Utopia
Design Protocol, by UtopiaSoftware.
