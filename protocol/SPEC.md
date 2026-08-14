# Utopia Design Protocol - Specification

Version: 0.3.0 (see [VERSIONING.md](VERSIONING.md))
Status: v0 draft, implemented by `tool/utopia_design_tools`

The Utopia Design Protocol is an open, bidirectional design-system contract for Flutter apps
built on `utopia_ui`. It connects HTML-based design surfaces (AI design tools, the HTML twin of
`utopia_ui`) with the Flutter implementation through three machine-readable artifacts:

1. **The token document** - a [DTCG 2025.10](https://www.designtokens.org/tr/2025.10/format/)
   design-tokens file describing the full visual theme (`tokens/utopia.tokens.json` in this
   repo, `design/tokens.json` in a consumer app).
2. **The component manifest** - a JSON registry of every `utopia_ui` component and its API,
   generated from source (`manifest/utopia.manifest.json`).
3. **The HTML twin** - a static, dependency-free HTML/CSS rendering of the design system whose
   every visual value resolves through CSS custom properties generated from the token document
   (`twin/`).

Both renderers - the Flutter theme and the twin's CSS - are **generated** from the token
document. "Bidirectional" means: edits made on any surface land in the token document (through
validation gates), and regeneration fans the change out to every surface. See section 6.

The words MUST, MUST NOT, SHOULD and MAY are used as in RFC 2119.

---

## 1. Artifacts and ownership

| Artifact | Canonical location (this repo) | Consumer location | Owner |
|---|---|---|---|
| Token document | `tokens/utopia.tokens.json` | `design/tokens.json` | the app (consumer-owned, editable) |
| Component manifest | `manifest/utopia.manifest.json` | read from the pub cache | `utopia_ui` (generated per release) |
| HTML twin | `twin/` | read from the pub cache | `utopia_ui` (generated + curated) |
| JSON Schemas | `protocol/schemas/*.schema.json` | read from the pub cache | this spec |

`tokens/`, `manifest/`, `twin/` and `protocol/` ship inside the `utopia_ui` pub tarball, so a
consumer project always holds artifacts matching its resolved package version.

The canonical token document in this repo is the DTCG export of
`UtopiaThemeData.defaultTheme`. A consumer's `design/tokens.json` starts as a copy of it and
diverges through rebranding; it is *not* regenerated on package upgrade.

---

## 2. The token document

### 2.1 Base format

- A token document MUST be valid JSON conforming to the DTCG **Format module 2025.10** and
  **Color module 2025.10**. No other DTCG modules apply; in particular the Resolver module
  (draft, not stable) is out of scope - a token document is **single-context** (no modes, no
  themes-in-one-file).
- Recommended file extension: `.tokens.json`.
- Token and group names MUST NOT contain `.`, `{`, `}` or start with `$` (DTCG MUST). Dotted
  identifiers such as `spacing.md` are *reference paths*, expressed in JSON as nested groups.
- Aliases use the DTCG curly-brace syntax only (`"$value": "{radius.sm}"`). JSON-Pointer
  `$ref` references are NOT part of this profile in v0. Aliases MUST resolve within the same
  document and MUST NOT be circular.
- `$extensions` MUST round-trip: any tool that rewrites a token document MUST preserve
  extension data it does not understand (DTCG MUST).

### 2.2 The utopia token tree

A conforming token document contains exactly the following top-level members. The tree mirrors
the canonical identifier table in `lib/src/theme/utopia_tokens.dart` plus the color, text style
and semantic-slot families of `UtopiaThemeData`.

| Path | DTCG `$type` | Constraints | Flutter source |
|---|---|---|---|
| `x` | `number` | > 0 | `UtopiaTokens.x` (base unit, logical px) |
| `spacing.{xxs,xs,sm,md,lg,xl,xxl,xxxl}` | `dimension` | unit `px`; base-derived | `UtopiaSpacingTokens` |
| `radius.{xs,sm,md,lg,xl}` | `dimension` | unit `px`; base-derived | `UtopiaRadiusTokens` |
| `radius.full` | `dimension` | unit `px`; NOT base-derived (9999) | `UtopiaRadiusTokens.full` |
| `border.{hairline,thin,thick}` | `dimension` | unit `px` | `UtopiaBorderTokens` |
| `shadow.{sm,md,lg}` | `shadow` | array form, even for one layer | `UtopiaShadowTokens` |
| `fontWeight.{regular,medium,semiBold,bold}` | `fontWeight` | numeric, 100..900 step 100 | `UtopiaFontWeightTokens` |
| `duration.{xs,sm,md,lg,xl}` | `duration` | unit `ms` | `UtopiaDurationTokens` |
| `breakpoint.{tablet,web,sidebar}` | `dimension` | unit `px` | `UtopiaBreakpointTokens` |
| `color.<name>` | `color` | sRGB with hex fallback; 18 names, `divider` optional | `UtopiaThemeColors` |
| `textStyle.{header,label,text,title,caption,button}` | `typography` | see 2.4 | `UtopiaThemeTextStyles` |
| `textStyle-colors.{header,label,text,title,caption,button}` | `color` | see 2.4 | `TextStyle.color` |
| `theme.borderRadius` | `dimension` | value or alias | `UtopiaThemeData.borderRadius` |
| `theme.cardRadius` | `dimension` | value or alias | `UtopiaThemeData.cardRadius` |
| `theme.fieldContentPadding.{top,right,bottom,left}` | `dimension` | value or alias | `UtopiaThemeData.fieldContentPadding` |
| `theme.fieldMinHeight` | `dimension` | value or alias | `UtopiaThemeData.fieldMinHeight` |
| `theme.pageTopPadding` | `dimension` | value or alias | `UtopiaThemeData.pageTopPadding` |
| `theme.tileHeight` | `dimension` | value or alias | `UtopiaThemeData.tileHeight` |

The `color` group members: `primary`, `accent`, `field`, `canvas`, `error`, `disabled`,
`text`, `surface`, `border`, `rowAlt`, `hover`, `chipBackground`, `chipForeground`, `hint`,
`onColoredContent`, `onColoredSelected`, `onColoredHover` are REQUIRED; `divider` is OPTIONAL.
An absent `color.divider` means "derive a contrast-safe divider colour from `color.text` over
`color.surface` at paint time" - exactly the semantics of a `null`
`UtopiaThemeColors.divider`. Tools MUST NOT invent a concrete value for it.

Derived Dart getters (`cardShadow`, `menuShadow`, `chipRadius`, `cardBorderWidth`,
`dividerThickness`, decoration getters) are **not** tokens. They are aliases in Dart and stay
in Dart; emitting them as tokens would create a second source of truth.

The token tree is deliberately **closed**: a token that has no landing spot in
`UtopiaThemeData` would be silently dead on the Flutter surface, so unknown names are
rejected rather than accepted-and-ignored. The top-level name `custom` is reserved for a
possible future consumer-extension group (an additive, minor-version change per
VERSIONING.md); protocol 0.1 documents remain closed to unknown names.

### 2.3 Type mapping rules (Flutter <-> DTCG)

| Flutter value | DTCG shape |
|---|---|
| `double` logical px | `{"value": <number>, "unit": "px"}` (`dimension`) |
| `Duration` | `{"value": <ms>, "unit": "ms"}` (`duration`) |
| `FontWeight.w<N>` | `<N>` as a number (`fontWeight`) |
| `Color` | `{"colorSpace": "srgb", "components": [r, g, b], "alpha": a, "hex": "#rrggbb"}` where components are channel/255 |
| `List<BoxShadow>` | array of shadow objects: `color`, `offsetX`, `offsetY`, `blur`, `spread` (all dimensions px; `spread` 0 when unset) |
| `TextStyle` | `typography` composite + sibling color token (2.4) |
| `BorderRadius.all(Radius.circular(r))` | `dimension` of `r` |
| `EdgeInsets.fromLTRB(l, t, r, b)` | group of four `dimension` tokens `top/right/bottom/left` |

The profile assumes **uniform corner radii** for the `theme.borderRadius` and
`theme.cardRadius` slots (`BorderRadius.all`). Non-uniform `BorderRadius` values are out of
scope in v0; exporters MUST fail with an actionable message when they encounter one.

Color rules:

- `colorSpace` MUST be `"srgb"` in v0.
- `hex` MUST be present: the 6-digit lowercase CSS hex of the RGB channels (alpha never encoded
  in `hex`).
- `alpha` SHOULD be emitted explicitly by generators, even when `1`, for stable diffs; readers
  MUST treat an absent `alpha` as `1`.
- Component values are `channel / 255` and SHOULD be limited to at most 6 fractional digits.

### 2.4 The typography wrinkle

DTCG `typography` has no color property, but `TextStyle` carries one. The profile handles this
with **sibling color tokens**:

- Every `textStyle.<role>` token MUST have a matching `textStyle-colors.<role>` color token.
- The typography token records the binding in
  `$extensions["io.utopiasoft.design"].colorToken` (value: the sibling's reference path, e.g.
  `"textStyle-colors.header"`).
- The `typography` `$value` contains exactly: `fontFamily` (string or array of strings),
  `fontSize` (dimension px), `fontWeight` (number), `letterSpacing` (dimension px).
  `lineHeight` is NOT part of the profile in v0 (`utopia_ui` does not set it).
- When a font family ships inside a Flutter package (the default theme's Sora ships inside
  `utopia_ui`), the typography token records
  `$extensions["io.utopiasoft.design"].fontPackage` (e.g. `"utopia_ui"`) so generated Dart
  reconstructs the `TextStyle(package:)` argument. Twin generators ignore this key.

### 2.5 Scale derivation

`utopia_ui`'s spatial scale derives from the base unit `x`
(`UtopiaTokens.fromBase`). The profile keeps that rescaling first-class:

- Every base-derived token records its multiple in
  `$extensions["io.utopiasoft.design"].derivation` as the string `"x*<multiple>"`
  (e.g. `"x*3"`, `"x*0.5"`, `"x*1"`).
- Base-derived tokens in the canonical tree: all of `spacing.*`, `radius.*` except
  `radius.full`, and (in the default theme) `theme.fieldContentPadding.top` (`x*2.5`),
  `theme.fieldContentPadding.bottom` (`x*1.5`) and `theme.fieldMinHeight` (`x*11`).
- A token that carries `derivation` MUST satisfy `value == x.value * multiple` (float
  tolerance 0.001). This is the validator's **scale coherence** gate.
- A rebrand that changes `x` MUST re-derive every `derivation`-carrying token (this is what
  `derivation` exists for). A token edited away from its multiple MUST drop or update its
  `derivation` extension.
- `radius.full` (9999) is deliberately not derived and MUST NOT carry `derivation`.

Aliases are the second derivation mechanism: the default theme expresses
`theme.borderRadius = {radius.sm}`, `theme.cardRadius = {radius.xl}`,
`theme.pageTopPadding = {spacing.xxxl}`, `theme.fieldContentPadding.left/right =
{spacing.lg}`. Consumers MAY replace an alias with a literal value (that is a design decision,
not drift).

### 2.6 The `io.utopiasoft.design` extension namespace

All protocol metadata lives under `$extensions["io.utopiasoft.design"]`. Registered keys:

| Key | On | Type | Meaning |
|---|---|---|---|
| `derivation` | token | string `"x*<n>"` | base-unit multiple (2.5) |
| `colorToken` | typography token | string | reference path of the sibling color token (2.4) |
| `fontPackage` | typography token | string | Flutter package bundling the font family (2.4) |
| `profileVersion` | document root | string | protocol version the document targets |
| `lastSyncedValue` | token | any | snapshot of `$value` at last external sync (6.2) |
| `lastSyncedAt` | token | string (ISO 8601) | timestamp of last external sync (6.2) |
| `sourceRef` | token | string | opaque identity in the external source, e.g. a Figma variable id (6.2) |

Unknown keys under the namespace MUST be preserved and SHOULD be warned about by the
validator. Foreign vendor namespaces (e.g. `com.figma.*`) MUST be preserved untouched.

The document root SHOULD carry
`$extensions["io.utopiasoft.design"].profileVersion` so validators can check compatibility
(see VERSIONING.md).

### 2.7 Validation gates

`validate_tokens` enforces, in order:

1. **Schema validity** - the document validates against
   `protocol/schemas/tokens.schema.json` (structure, types, units, the fixed naming table).
2. **Naming conformance** - group/token names match the canonical tree exactly (the schema
   encodes this; the validator reports the offending path).
3. **Alias resolvability** - every `{...}` reference resolves to an existing token of the
   expected type; no circular chains.
4. **Value coherence** - every `derivation`-carrying token matches `x * multiple` (2.5), and
   every color's `hex` fallback matches its `components` rounded to 8-bit channels.
5. **Extension round-trip** - on any rewrite operation, unrecognized `$extensions` data is
   preserved byte-for-byte (checked by tooling tests; validators warn on unknown keys inside
   the `io.utopiasoft.design` namespace).

Violations of gates 1-4 are errors (exit code 1). Gate 5 issues are warnings unless a rewrite
would drop data.

### 2.8 Example (abridged)

```json
{
  "$extensions": { "io.utopiasoft.design": { "profileVersion": "0.1.0" } },
  "x": { "$type": "number", "$value": 4 },
  "spacing": {
    "md": {
      "$type": "dimension",
      "$value": { "value": 12, "unit": "px" },
      "$extensions": { "io.utopiasoft.design": { "derivation": "x*3" } }
    }
  },
  "color": {
    "primary": {
      "$type": "color",
      "$value": { "colorSpace": "srgb", "components": [0.329, 0.427, 0.996], "alpha": 1, "hex": "#546dfe" }
    }
  },
  "shadow": {
    "sm": {
      "$type": "shadow",
      "$value": [{
        "color": { "colorSpace": "srgb", "components": [0, 0, 0], "alpha": 0.05, "hex": "#000000" },
        "offsetX": { "value": 0, "unit": "px" },
        "offsetY": { "value": 1, "unit": "px" },
        "blur": { "value": 6, "unit": "px" },
        "spread": { "value": 0, "unit": "px" }
      }]
    }
  },
  "textStyle": {
    "header": {
      "$type": "typography",
      "$value": {
        "fontFamily": "Sora",
        "fontSize": { "value": 24, "unit": "px" },
        "fontWeight": 600,
        "letterSpacing": { "value": 1, "unit": "px" }
      },
      "$extensions": {
        "io.utopiasoft.design": { "colorToken": "textStyle-colors.header", "fontPackage": "utopia_ui" }
      }
    }
  },
  "textStyle-colors": {
    "header": {
      "$type": "color",
      "$value": { "colorSpace": "srgb", "components": [0, 0, 0], "alpha": 0.867, "hex": "#000000" }
    }
  },
  "theme": {
    "borderRadius": { "$type": "dimension", "$value": "{radius.sm}" }
  }
}
```

---

## 3. The component manifest

### 3.1 Purpose and lineage

The manifest is the machine-readable API surface of `utopia_ui`, modeled on the Web
Components [custom-elements-manifest](https://github.com/webcomponents/custom-elements-manifest)
(CEM) and adapted to Flutter. It exists so agents and tools can answer "what components exist,
how are they constructed, which tokens do they read" without parsing Dart.

Schema: `protocol/schemas/manifest.schema.json`. Canonical instance:
`manifest/utopia.manifest.json`, regenerated per `utopia_ui` release.

### 3.2 Scope rule

Included as **components**: concrete `StatelessWidget` / `StatefulWidget` / `HookWidget`
subclasses exported from the single barrel `lib/utopia_ui.dart`.

Excluded from components: theme classes (`UtopiaTheme*`, `UtopiaTokens` and token families),
enums, typedefs, extensions, abstract/static-only classes (`UtopiaBreakpoints`), data/config
classes (`UtopiaTableEntry`, `UtopiaSidebarItem` and subtypes, `UtopiaSidebarStyle`,
`UtopiaTableSortOption`, `UtopiaTableState`), free functions and hooks.

Known v0 limitation: only constructors are modeled. Static presentation helpers
(`UtopiaConfirmDialog.show`, `UtopiaDialog.show`) have no structured representation; the
overlay's `notes` field carries their usage guidance as prose. A `staticMethods` section is
a candidate additive (minor-version) extension if agents prove to need it.

Two auxiliary sections keep the excluded-but-needed API queryable:

- `models` - data/config classes that appear in component props (e.g. `UtopiaTableEntry`,
  `UtopiaSidebarDestination`). Same constructor/prop shape as components, no component id, no
  twin binding.
- `helpers` - exported free functions, hooks and typedefs (e.g. `utopiaCardSliver`,
  `useUtopiaTableState`, `utopiaDatePickerMaterialTheme`), with signatures and descriptions.

### 3.3 Component id derivation and namespaces

`id` = the class name minus the `Utopia` prefix, converted to kebab-case:
`UtopiaButton` -> `button`, `UtopiaRemoveIconButton` -> `remove-icon-button`,
`UtopiaChipList` -> `chip-list`, `UtopiaThreeBounce` -> `three-bounce`.
Ids MUST be unique and are the stable cross-surface key: the twin marks component roots with
`data-utopia-id="<id>"`, skills reference components by id.

Namespace rule (since 0.2.0):

- **Bare ids** (`button`) are reserved for `utopia_ui` library components, forever.
- **Project component ids** (3.8) MUST be namespaced as
  `<projectPackageName>:<kebab-name>` (e.g. `stock_app:market-tile`). The local part is
  derived from the class name by the same kebab-case rule (no prefix stripping unless the
  class carries the project's own prefix - the overlay MAY override the local part).
- Multi-layer namespaces (an intermediate company library such as `acme_ui:kpi-card`) are a
  forward-compatibility rule only: valid per the id grammar, but MVP tooling implements a
  single project layer.

### 3.4 Component entry shape (summary; the schema is normative)

```jsonc
{
  "id": "button",
  "name": "UtopiaButton",
  "description": "The primary call-to-action button: ...",   // first dartdoc paragraph
  "file": "lib/src/widget/button/utopia_button.dart",
  "constructors": [
    {
      "name": "",                       // "" = unnamed; else "form", "fixed", "raw", ...
      "description": "...",
      "props": [
        {
          "name": "onTap",
          "type": "callback",           // portable type, see 3.5
          "dartType": "void Function()",
          "required": true,
          "description": "..."
        },
        {
          "name": "dense",
          "type": "bool",
          "dartType": "bool",
          "required": false,
          "default": "false"            // verbatim Dart default expression
        }
      ]
    }
  ],
  "tokenBindings": [{ "path": "colors.primary", "origin": "source" }, { "path": "theme.cardShadow", "origin": "overlay" }],
  "states": ["loading", "disabled", "hover"],
  "composes": ["gradient-background", "three-bounce"],
  "twin": { "file": "components.html", "selector": "[data-utopia-id=\"button\"]" },
  "examples": ["example/lib/sections/buttons_section.dart"]
}
```

`twin` is generated, not hand-kept: `generate_manifest` scans the twin bundle's
`components.html` for `data-utopia-id` roots (4.4) and emits
`{ "file": "components.html", "selector": "[data-utopia-id=\"<id>\"]" }` for every component
that has one, omitting the field entirely for components the twin does not render. `file` is
twin-bundle-relative (4.1). Project manifests (3.8) do not carry `twin` bindings in 0.3.0 -
the twin bundle belongs to `utopia_ui` and has no sections for project components.

### 3.5 Portable prop type vocabulary

Every prop carries both the verbatim `dartType` and a portable `type` from this closed set:

| `type` | Meaning / Dart examples |
|---|---|
| `string` | `String`, `String?` |
| `number` | `double`, `int` |
| `bool` | `bool` |
| `enum` | any enum param; entry carries `enumName` + `values` |
| `color` | `Color`, `List<Color>` gradients use `list` + `itemType: "color"` |
| `duration` | `Duration` |
| `date` | `DateTime` |
| `callback` | function types that return `void`/`Future` and are not builders |
| `widget-slot` | a plain `Widget` param |
| `builder-slot` | a function param returning `Widget` (receives `BuildContext` first) |
| `list` | `List<T>` / `IList<T>`; entry carries `itemType` (portable) + `itemDartType` |
| `generic-model` | the component's own type parameter (`T row`) or functions over it |
| `model` | an exported `utopia_ui` data class; entry carries `modelName` referencing `models` |
| `other` | opaque platform types (`Key`, `FocusNode`, `Curve`, `EdgeInsets`, ...) |

### 3.6 `tokenBindings` vocabulary

`tokenBindings` lists the theme members a component actually reads, as dotted paths rooted at
`UtopiaThemeData`, matching the context-extension access style:

- `colors.<field>` (e.g. `colors.primary`)
- `textStyles.<field>` (e.g. `textStyles.button`)
- `tokens.x`, `tokens.spacing.<step>`, `tokens.radius.<step>`, `tokens.borders.<name>`,
  `tokens.shadows.<step>`, `tokens.fontWeights.<name>`, `tokens.durations.<step>`,
  `tokens.breakpoints.<name>`
- `theme.<slotOrGetter>` for semantic slots and derived getters (e.g. `theme.borderRadius`,
  `theme.cardDecoration`)

Since 0.3.0 each entry is an object carrying the path plus its provenance:

```jsonc
"tokenBindings": [
  { "path": "colors.primary", "origin": "source" },
  { "path": "theme.cardShadow", "origin": "overlay" }
]
```

`origin` is `source` for a binding the extractor read out of the component's own
implementation, and `overlay` for one the overlay's `tokenBindingsAdd` escape hatch declared
(3.7). Generators MUST stamp it; the schema keeps it optional so documents written for 0.2 -
whose entries are bare strings - remain valid, and a bare string is read as a path of unknown
origin.

Bindings are verified against source (grep-level truth): a binding MUST appear in the
component's implementation. Recording provenance in the document is what lets
`validate_manifest` verify bindings against source WITHOUT the overlay directory, which the
`utopia_ui` pub tarball does not ship: an entry marked `overlay` is exempt from the
"must appear in the implementation" rule, and one the extractor does find there is reported as
a stale origin marker. For a 0.2 document the validator falls back to reading the overlay
directory, exactly as before.

### 3.7 Generation model and drift gates

`generate_manifest` runs the Dart `analyzer` over `lib/`, merges a hand-maintained
per-component **overlay** (`tool/utopia_design_tools/overlay/<id>.yaml`) carrying facts that
cannot be derived statically (interaction `states`, semantic notes, curated `examples`), and
writes the manifest.

Drift is an assumed condition, and generation is where it gets caught:

- Generation MUST FAIL (exit 1) when an overlay references a component, constructor or prop
  that no longer exists in the analyzed source.
- The manifest stamps `packageVersion` from `pubspec.yaml`. `validate_manifest` MUST fail when
  `packageVersion` differs from the resolved `utopia_ui` version it is validated against.
- `validate_manifest` re-checks schema validity, id uniqueness/derivation, `tokenBindings`
  against source, and twin binding targets (the bound file MUST carry a `data-utopia-id` root
  for the component's id).

### 3.8 The project manifest (custom components)

Every real project has custom components that compose library primitives and read the theme
while also taking project-specific values. The protocol's production value in agentic
development is the **stable id mapping** between design artifacts and code across
iterations - so project components carry manifest ids too, under the namespace rule of 3.3.

Two sources of truth, one derived view:

| Artifact | Location (consumer project) | Truth status |
|---|---|---|
| Library manifest | pub cache (`manifest/utopia.manifest.json`) | source of truth (shipped, 3.7) |
| Project manifest | `design/project.manifest.json` | source of truth (generated from project source + overlays) |
| Merged manifest | `design/merged.manifest.json` | DERIVED - regenerate, never edit, never treat as source |

- The project manifest contains ONLY custom components, curated **opt-in**: a component
  exists in it exactly when the project has an overlay YAML for it
  (`design/overlay/<local-part>.yaml`, same schema and drift gates as 3.7). A project never
  auto-exports every private widget.
- `generate_manifest --project` (see section 5) runs the same analyzer + overlay extraction
  over the consumer project and emits BOTH files. Generated artifacts are never hand-edited.
- Manifest documents carry flavor markers (schema 0.2.0): `package` is the described Dart
  package (the project's name in project/merged manifests, `utopia_ui` in the library one);
  `utopiaUiVersion` records the resolved `utopia_ui` version the document was generated
  against (REQUIRED on project and merged manifests); `merged: true` marks the merged view.
- Freshness gates on the merged view (`validate_manifest`): recorded `utopiaUiVersion` MUST
  equal the resolved pubspec version, and the embedded library entries MUST equal the
  shipped library manifest. Both are cheap equality/version checks. Byte-identical
  regeneration is a determinism GUARANTEE on `generate_manifest --project` (verified by its
  tests, same principle as the twin's tokens.css freshness), NOT a validate-side gate -
  `validate_manifest` never re-runs project extraction just to compare bytes; staleness of
  the project half is caught by the existing source-backed gates (tokenBindings
  re-extraction, stale-class, file cross-checks) run against project sources. A stale
  merged view is an error, not a warning - embedding a copy of the library manifest is
  exactly the silent upgrade drift the `packageVersion` gate exists to prevent.
- Namespace enforcement (`validate_manifest`): in a project manifest, every component id's
  namespace MUST equal the document's `package`; bare ids there are an error. In the
  library manifest, namespaced ids are an error. In the merged view both flavors coexist
  and each id MUST carry the namespace of its origin. `utopiaUiVersion` presence (required
  on project/merged, absent on library) is enforced by the validator, not the schema.
- `file` path roots: a bare-id entry's `file` resolves against the `utopia_ui` package
  root; a namespaced entry's `file` resolves against the project root.
- Project manifests MAY carry their own `models` and `helpers` (a custom component's props
  will reference project data classes - the portable type vocabulary of 3.5 applies with
  "exported utopia_ui class" read as "class exported/declared by the describing package").
  `modelName` resolves within the containing document; in the merged view, model names MUST
  be unique across both halves and `generate_manifest --project` MUST fail the merge on a
  collision (flat model namespace in MVP).
- Referential integrity across the merge: custom components' `composes` and prop `modelName`
  references MAY point at library ids/models; `validate_manifest` enforces resolution on the
  merged view.
- The theme stays CLOSED (2.2): theming customizes what `utopia_ui` offers. Project-specific
  visual values (e.g. gain/loss colors on a stock tile) live in project code as constants -
  a legal, documented pattern, not a smell. The reserved `custom` token group stays reserved
  and UNUSED; there is no custom-token codegen in MVP.
- The production loop this enables: a screen-building gap report names a missing component
  -> the component is scaffolded in the project (theme via context) -> an overlay YAML
  registers it -> project + merged manifests regenerate -> the design tool re-imports the
  merged manifest -> the id is live in every later development cycle.

---

## 4. The HTML twin

### 4.1 Bundle layout

```
twin/
  tokens.css            # GENERATED from the token document - do not edit
  tokens.tailwind.css   # GENERATED Tailwind v4 @theme variant (optional consumption)
  components.css        # hand-authored component styles, token-driven
  components.html       # one section per manifest component, data-utopia-id on each root
  gallery.src.html      # hand-authored gallery source: prose, section order, specimen markers
  gallery.html          # COMPOSED from gallery.src.html + components.html - do not edit
  DESIGN.md             # design.md-spec description; front matter GENERATED from tokens
```

The gallery is composed, not hand-copied: each `<!-- utopia-specimen: <id> -->` marker in
`gallery.src.html` is replaced by that specimen's subtree copied verbatim from
`components.html` (`generate_twin --compose-gallery`), and the emitted `gallery.html` stays a
committed static file. When a component has several specimens, a trailing `#<n>` picks the
n-th `data-utopia-id` root for that id in `components.html` document order (`<id>` alone means
the first). The index is positional: inserting a specimen in the middle of a catalog section
shifts the ones after it, so the composed `gallery.html` diff MUST be reviewed after catalog
edits - the committed output is what makes that drift visible. A `<!-- utopia-twin-omit: <id> -- <reason> -->` marker records a
manifest id a surface deliberately does not show; `validate_twin` treats missing ids without
one as coverage warnings.

Static HTML/CSS with minimal vanilla JS only. No frameworks, no build step: opening the files
in a browser MUST be sufficient.

### 4.2 CSS custom property naming

Rule: `--utopia-` + the token path with every segment kebab-cased (camelCase splits on case
boundaries), segments joined with `-`.

- `spacing.md` -> `--utopia-spacing-md`
- `fontWeight.semiBold` -> `--utopia-font-weight-semi-bold`
- `theme.fieldContentPadding.top` -> `--utopia-theme-field-content-padding-top`
- `breakpoint.tablet` -> `--utopia-breakpoint-tablet`

Composite expansions:

- `typography` tokens expand per property:
  `textStyle.header` -> `--utopia-text-style-header-font-family`, `...-font-size`,
  `...-font-weight`, `...-letter-spacing`.
- The sibling color group folds into the same prefix: `textStyle-colors.header` ->
  `--utopia-text-style-header-color` (NOT `--utopia-text-style-colors-header`). The reverse
  mapping applies on import: `--utopia-text-style-<role>-color` resolves to
  `textStyle-colors.<role>`.
- `shadow` tokens emit one variable holding the full CSS `box-shadow` value list:
  `--utopia-shadow-sm: 0 1px 6px 0 rgb(0 0 0 / 0.05);`.

Value serialization:

- dimension -> `<value>px` with no trailing `.0` (`6px`, `1.5px`)
- duration -> `<value>ms`
- color -> lowercase `#rrggbb` when alpha is 1, else `rgb(R G B / A)` with 0-255 integer
  channels
- fontWeight -> bare number
- `x` -> unitless number (`--utopia-x: 4`)
- aliases -> `var()` references (`--utopia-theme-border-radius: var(--utopia-radius-sm);`)

### 4.3 Tailwind `@theme` variant

`tokens.tailwind.css` maps the same tokens into Tailwind v4 namespaces inside one `@theme`
block, for consumers pasting the system into Tailwind projects:

| Token family | Tailwind namespace |
|---|---|
| `color.<name>` | `--color-<name-kebab>` |
| `textStyle-colors.<role>` | `--color-text-style-<role>` |
| `spacing.<step>` | `--spacing-<step>` |
| `radius.<step>` | `--radius-<step>` |
| `shadow.<step>` | `--shadow-<step>` |
| `fontWeight.<name>` | `--font-weight-<name-kebab>` |
| `breakpoint.<name>` | `--breakpoint-<name>` |
| `textStyle.<role>` fontFamily | `--font-<role>` |
| `duration.*`, `border.*`, `theme.*`, `x` | not mapped (no stable namespace); kept as comments |

### 4.4 Component markup contract

- Every component's root element in `components.html` and `gallery.html` MUST carry
  `data-utopia-id="<manifest id>"`.
- Every manifest component SHOULD have a twin section; components without one (pure-behavior
  widgets such as `multi-widget`) are listed in the twin with a "no visual twin" note and no
  styled markup.
- `components.css` MUST express visual values through `var(--utopia-*)` references.

### 4.5 Literals rule

The **literals linter** (part of `validate_twin`) flags raw values in `components.css` that
have a token equivalent:

- hard-fail: raw hex/rgb/hsl colors; raw `px` values matching any current spacing/radius/
  border token value; raw `font-family`/`font-weight` literals
- warn: any other raw `px`, `ms` and unitless numeric literals
- allowed exceptions (never flagged): `9999px` / `--utopia-radius-full` usage, `0`,
  percentage/fraction layout values, and values annotated
  `/* utopia-literal-ok: <reason> */` on the same line (CSS-only concerns such as a `1px`
  hairline tweak use this annotation - it IS the documented-inline mechanism)
- scope: hand-authored `.css` files AND inline `<style>` blocks in the twin HTML files get
  the full rule set; `style="..."` attributes in twin HTML are specimen scaffolding - raw
  dimensions are allowed there, raw colors and font literals still hard-fail

### 4.6 DESIGN.md

`twin/DESIGN.md` follows the
[design.md spec](https://github.com/google-labs-code/design.md): YAML front matter
(`name`, `colors`, `typography`, `rounded`, `spacing`) GENERATED from the token document,
followed by the 8 canonical prose sections in order (Overview, Colors, Typography, Layout,
Elevation & Depth, Shapes, Components, Do's and Don'ts). Prose is hand-curated; regeneration
only rewrites the front matter block.

---

## 5. Tooling surface

All tools ship as executables of the Dart package `utopia_design_tools` (developed nested in
this repo under `tool/`, published to pub.dev as its own package) and are invoked as
`dart run utopia_design_tools:<command>`. Consumers install it as a dev dependency
(`flutter pub add --dev utopia_design_tools`); `export_tokens` is the one maintainer-only
tool that additionally requires a checkout of this repo. The exact CLI contract (arguments,
exit codes, output formats) is published separately (handoff H1); the command set is fixed
here:

| Command | Role |
|---|---|
| `export_tokens` | export a `UtopiaThemeData` (default: `defaultTheme`) to a token document |
| `validate_tokens` | validation gates 2.7 |
| `generate_manifest` | analyzer + overlay -> manifest (3.7); `--project` mode emits the project + merged manifests (3.8) |
| `validate_manifest` | manifest gates (3.7) |
| `generate_theme` | token document -> Dart theme code (a `UtopiaThemeData` factory); `--check` compares in-memory regeneration against the existing generated file (freshness gate, writes nothing) |
| `generate_twin` | token document -> `twin/tokens.css`, `twin/tokens.tailwind.css`, DESIGN.md front matter; composes `gallery.html` from `gallery.src.html` when present (4.1); `--scaffold <id>` prints a components.html section skeleton to stdout |
| `validate_twin` | literals linter + `data-utopia-id` coverage vs the manifest + DESIGN.md front matter freshness + forward coverage of gallery/tier-1 (warnings, `utopia-twin-omit` markers) + manifest `states[]` vs `.is-*` parity (warnings) |

Shared conventions: exit code 0 = success, 1 = validation/generation failure (actionable
messages, one finding per line), 2 = usage or I/O error. Every command accepts `--json` for
machine-readable output.

`generate_theme` is the consumer-facing codegen: given `design/tokens.json` it emits a Dart
file exposing a `UtopiaThemeData` factory built via `UtopiaThemeData.fromTokens` plus
`copyWith` for the semantic slots. Round-trip guarantee: exporting `defaultTheme` and
generating a theme from that export MUST produce a theme equal to `defaultTheme` up to 8-bit
color quantization (colors compare by their ARGB32 value).

---

## 6. Sync model

### 6.1 Shared artifact, generated surfaces

The consumer app owns `design/tokens.json`. Everything else is generated from it:

```
                     +-----------------------+
   edits (gated) --> |  design/tokens.json   | <-- imports (gated, 6.2)
                     +-----------+-----------+
                                 |
             +-------------------+-------------------+
             v                                       v
   generate_theme                              generate_twin
   (Dart theme code)                           (tokens.css, tailwind, DESIGN.md)
```

There is no runtime sync, no watching, no network: regeneration is an explicit, validated
step. Any surface-side edit (a tweak made in the twin's CSS, a Figma variable change) becomes
durable only by landing in the token document and regenerating.

Fan-out is conditional by presence: regeneration targets every surface the consumer has
materialized. A project without a `twin/` directory gets no twin written as a rebrand side
effect - creating the design surface for the first time is an explicit choice.

### 6.2 Importing external sources

Imports (Figma DTCG exports, foreign `tokens.css` / Tailwind `@theme` files, design handoff
bundles, DESIGN.md files) map external values onto the utopia tree. Import tooling MUST be
non-silent: it produces a mapping proposal and diff for review, then applies through the
validation gates.

Three-way diffing uses the sync metadata keys of 2.6 (`lastSyncedValue`, `lastSyncedAt`,
`sourceRef`), borrowed from Figma Console MCP's proven mechanics:

- Matching priority: external id (`sourceRef`) -> token path -> value fingerprint.
- A token counts as **conflicted** when both sides changed since `lastSyncedValue`.
- Conflict modes: `ask` (default - report, write nothing), `theirs`, `ours`, `skip`.
- Metadata advancement: resolving a conflict via `theirs` or `ours` refreshes
  `lastSyncedValue`/`lastSyncedAt` to the resolved value (the decision becomes the new merge
  base, so the same conflict does not resurface); `skip` leaves the metadata untouched, so
  the conflict deliberately reappears on the next import.

---

## 7. Consuming the protocol from a project

A consumer project resolves `utopia_ui` through pub; the version-matched artifacts sit in the
pub cache (`.dart_tool/package_config.json` resolves the path). The intended consumer loop:

1. `design/tokens.json` starts as a copy of the packaged `tokens/utopia.tokens.json`.
2. Rebrand by editing the token document (usually via the `utopia-design-tokens` skill), gated
   by `validate_tokens`.
3. `generate_theme` regenerates the app's theme; `generate_twin` regenerates the design
   surface used by design tools and agents.
4. Screens are built against manifest components only (the merged manifest once the project
   registers custom components per 3.8); anything a design needs that no manifest id covers
   is reported as a gap, never hand-rolled as a lookalike.

Every consumer-facing tool and skill MUST verify the project actually resolves `utopia_ui`
(pubspec + lockfile) before acting, and stop with installation guidance otherwise.
