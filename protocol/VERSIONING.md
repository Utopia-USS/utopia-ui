# Utopia Design Protocol - Versioning

## Protocol version

The protocol is versioned as a single unit under [semver](https://semver.org): the
specification ([SPEC.md](SPEC.md)) and both JSON Schemas
(`schemas/tokens.schema.json`, `schemas/manifest.schema.json`) always change together under
one version number.

Current version: **0.3.0**.

History:

- **0.3.0** (2026-08-14) - additive: `tokenBindings` entries carry provenance (SPEC 3.6) - an
  entry is now an object `{ "path": ..., "origin": "source" | "overlay" }`; the bare-string
  form written by 0.2 generators stays valid and is read as a path of unknown origin. The
  component `twin` binding (SPEC 3.4) is generated rather than hand-kept: `generate_manifest`
  emits it for every component the HTML twin renders. The twin bundle gains a hand-authored
  `gallery.src.html` from which `gallery.html` is composed (SPEC 4.1), and the
  `utopia-twin-omit` marker records deliberate coverage omissions. `validate_manifest` now
  applies the document-version rule below to a manifest's `schemaVersion`. Token profile
  unchanged.
- **0.2.0** (2026-07-10) - additive: project manifests and the merged view (SPEC 3.8), the
  id namespace rule (SPEC 3.3), manifest schema fields `utopiaUiVersion` + `merged`,
  `package` widened from the `utopia_ui` constant to any Dart package name, component id
  grammar widened to allow a `<package>:` namespace prefix. Token profile unchanged.
- **0.1.0** (2026-07-10) - initial: token profile, component manifest, twin contract.

Semantics:

- **Major** - breaking: a previously valid document becomes invalid, or its meaning changes
  (renamed token paths, removed manifest fields, changed serialization rules).
- **Minor** - additive and backwards-compatible: new optional fields, new extension keys, new
  manifest sections, loosened constraints. Documents written for an older minor remain valid.
- **Patch** - clarifications and bug fixes to the spec or schema with no validity change.

Pre-1.0 caveat (standard semver): minor versions MAY break. Consumers should pin the pair
(`utopia_ui` version, protocol version) they were built against.

## How documents declare their version

- **Token documents** SHOULD carry the protocol version at the document root:
  `$extensions["io.utopiasoft.design"].profileVersion` (e.g. `"0.1.0"`).
- **Manifests** MUST carry it in the required `schemaVersion` field.

Validators accept documents whose declared version has the same major version as the
validator, warn when the declared minor is newer than the validator's, and fail on a major
mismatch. A missing `profileVersion` on a token document produces a warning, not an error.

## Relation to the utopia_ui package version

The protocol version and the `utopia_ui` package version are independent streams:

- `manifest/utopia.manifest.json` is regenerated for every `utopia_ui` release and stamps that
  release's version in `packageVersion`. `validate_manifest` fails when `packageVersion`
  differs from the pubspec version it is validated against - this is the drift gate between a
  manifest and the library it describes.
- `tokens/utopia.tokens.json` (the packaged default-theme export) is regenerated whenever the
  default theme changes; a consumer's `design/tokens.json` is consumer-owned and never
  overwritten by a package upgrade.
- The twin's generated files (`twin/tokens.css`, `twin/tokens.tailwind.css`, the DESIGN.md
  front matter) are regenerated together with the packaged token document.

A given `utopia_ui` release therefore ships artifacts pinned to exactly one protocol version;
resolving the package through pub is what version-matches the artifacts to the code.

## Schema identity

Each schema carries a stable `$id` (its canonical raw GitHub URL on `main`). Because the `$id`
is unversioned, the authoritative version signal is the protocol version embedded in the
schema's `description` plus this document; released schema snapshots are recoverable through
the git tag of the corresponding `utopia_ui` release and through the pub tarball of that
release (`protocol/` ships in the package).

## Change process

- While the protocol is under initial construction (pre-merge), changes to locked design
  decisions or published schema surfaces go through an RFC entry in the working ledger; the
  session that owns the schema answers, and both sides pin the outcome.
- After release, schema and spec changes arrive as ordinary PRs to this repo and MUST include:
  a version bump per the rules above, a CHANGELOG entry, and updated fixtures so
  `validate_tokens` / `validate_manifest` exercise the change.
