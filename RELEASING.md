# Releasing utopia_ui

Release runbook for `utopia_ui` and its nested tooling package
`utopia_design_tools`. Follow the steps in order; do not skip regeneration.

## a. Bump the version

Bump the `version:` field in `pubspec.yaml` (repo root, `utopia_ui`). Follow
semver. Update `CHANGELOG.md` with the new version's entry.

## b. Regenerate ALL shipped artifacts

REQUIRED, every release, no exceptions: `validate_manifest` enforces
`packageVersion == resolved utopia_ui version`. A version bump without
regeneration self-sabotages every consumer on day one - the manifest and
theme golden go stale against the new version and the protocol gates fail
immediately.

Run, from the repo root:

```
dart run tool/utopia_design_tools/bin/export_tokens.dart -o tokens/utopia.tokens.json
dart run tool/utopia_design_tools/bin/generate_manifest.dart -o manifest/utopia.manifest.json
dart run tool/utopia_design_tools/bin/generate_twin.dart
```

Then regenerate the theme golden via the documented test command (run from
`tool/utopia_design_tools`):

```
dart run utopia_design_tools:generate_theme ../../tokens/utopia.tokens.json -o test/goldens/default_theme.g.dart
```

Commit all regenerated files (`tokens/`, `manifest/`, `twin/`, the theme
golden) alongside the version bump.

## c. Validate and test

```
dart run tool/utopia_design_tools/bin/validate_tokens.dart
dart run tool/utopia_design_tools/bin/validate_manifest.dart
dart run tool/utopia_design_tools/bin/validate_twin.dart
flutter test
tool/utopia_design_tools/smoke/run.sh
```

All must exit 0. Fix any failure before proceeding - do not publish on a
red gate.

## d. Dry-run and diff the file listing

```
dart pub publish --dry-run
```

Diff the reported file listing against the D1 criterion:

- MUST include: `protocol/`, `tokens/`, `manifest/`, `twin/`, `skills/`
- MUST NOT include: `research/`, `ledger/`, `PROTOCOL_*`, `SESSION_*`,
  `DIRECTION_REVIEW_PROMPT.md`, `tool/`, `CHARTER.md`, `AGENTS.md`

Zero warnings expected. Do not proceed on a listing mismatch or a warning.

## e. Publish order

1. `utopia_ui` first.
2. `utopia_design_tools` second (it depends on the hosted `utopia_ui ^`
   constraint, not a path/git override - update its pubspec dependency
   before publishing if it still points at a pre-release constraint).
3. Push the `utopia-flutter-skills` marketplace update last, so the
   marketplace never points ahead of what is live on pub.dev.

## f. Post-publish smoke (launch-day gate)

Run against a fresh Flutter app, with both dependencies resolved from
pub.dev (no path/git overrides):

1. Bootstrap a new Flutter app.
2. Add `utopia_ui` and `utopia_design_tools` as normal hosted dependencies.
3. `bootstrap` (create `design/tokens.json` via the printed command).
4. `rebrand` (edit a token value).
5. `validate --fix`.
6. `generate_theme`.
7. Wire `UtopiaTheme(data: buildUtopiaTheme(), ...)` into the app.
8. `flutter run` and confirm the rebrand renders.
9. Install one real marketplace plugin end to end
   (`/plugin marketplace add` + `/plugin install`) and confirm it resolves.

Any failure here blocks the announcement - fix and re-run the full
post-publish smoke, do not patch around it silently.

## g. Announce

Announce the release once the post-publish smoke is fully green.
