[![pub][pub_badge]][pub_link] [![publisher][publisher_badge]][publisher_link] [![license][license_badge]][license_link] [![style: utopia\_lints][style_badge]][style_link]

# utopia_ui

A themeable, general-purpose Flutter design system: one foundational token scale and the basic building
blocks built on it - buttons, fields, tables, dialogs, chips, a navigation sidebar and layout primitives.

`utopia_ui` is data-shape agnostic and carries no domain logic. It doesn't know what a `JsonMap` is, doesn't
assume a delegate or a backend, and doesn't ship any CRUD logic - every component is generic over your own
model types and driven by plain values and callbacks. If your project needs a themed table / button / dialog
but has its own models, its own data layer and its own brand, you can adopt this package without forking it.

## Install

```
flutter pub add utopia_ui
```

or add it to `pubspec.yaml` directly:

```yaml
dependencies:
  utopia_ui: ^0.1.0
```

## 60-second start

Wrap your app (or just the subtree that needs it) in a `UtopiaTheme`, then use any component from the barrel
import - everything renders correctly even without a `UtopiaTheme` ancestor, but wrapping one is how you brand it.

```dart
import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UtopiaTheme(
        data: UtopiaThemeData.defaultTheme,
        child: Scaffold(
          body: Center(
            child: UtopiaButton(
              onTap: () {},
              child: const Text('Get started'),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Design tokens & theming

Every visual constant a component reads comes from one context-resolved root: `UtopiaThemeData`, carried by the
`UtopiaTheme` inherited widget. Components never hardcode a color, a font, a gap or a radius; if a component
needs a new visual constant, it's added to the token system, never inlined into a widget.

**The token scale.** All dimensional values derive from a single base unit, `UtopiaTokens.x` (4 logical pixels
by default). `UtopiaTokens` groups the foundational families:

| Family | Type | Steps |
|---|---|---|
| `spacing` | `UtopiaSpacingTokens` | `xxs 2 · xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48` |
| `radius` | `UtopiaRadiusTokens` | `xs 4 · sm 6 · md 8 · lg 12 · xl 16 · full`, each with a `BorderRadius` preset (`smAll`, ...) |
| `borders` | `UtopiaBorderTokens` | `hairline 1 · thin 1.5 · thick 2` |
| `shadows` | `UtopiaShadowTokens` | `sm · md · lg` elevation presets |
| `fontWeights` | `UtopiaFontWeightTokens` | `regular · medium · semiBold · bold` |
| `durations` | `UtopiaDurationTokens` | `xs 100ms · sm 150 · md 200 · lg 300 · xl 400` |
| `breakpoints` | `UtopiaBreakpointTokens` | `tabletMin 600 · webMin 900 · sidebarMin 1000` |

`UtopiaTokens.fromBase(5)` re-derives the spatial families from a new base - the whole system rescales from one
number. The token identifiers double as the canonical names for mirroring the scale into external tools (Figma
variables, CSS custom properties).

**The theme.** `UtopiaThemeData` carries the token scale plus the color and type families and a small set of
semantic slots - values that encode a design decision beyond "which token":

- `tokens` - the `UtopiaTokens` scale above
- `colors` (`UtopiaThemeColors`) - `primary`, `text`, `surface`, `border`, `hover`, `hint`, ...
- `textStyles` (`UtopiaThemeTextStyles`) - `header`, `title`, `text`, `label`, `button`, `caption`
- `borderRadius`, `cardRadius` - which radius step controls and cards sit on
- `fieldContentPadding`, `fieldMinHeight`, `pageTopPadding`, `tileHeight` - field/page/table metrics

Pure token aliases (`cardShadow`, `menuShadow`, `cardBorderWidth`, `dividerThickness`, `chipRadius`) are derived
getters, so they always track `tokens` and can never go stale.

`UtopiaThemeData.fromTokens(colors:, textStyles:, tokens:)` is the canonical constructor - it derives every
dimensional slot from the token scale so the whole theme sits on one grid.

**Distribution.** `UtopiaTheme` is a plain `InheritedWidget`, like `Theme` or `DefaultTextStyle` - no `provider`
dependency:

- `UtopiaTheme.of(context)` returns the closest ancestor's `UtopiaThemeData`, silently falling back to
  `UtopiaThemeData.defaultTheme` when there is none. Every component works zero-config.
- `UtopiaTheme.maybeOf(context)` returns `null` instead of falling back, for callers that need to tell the two
  cases apart.
- Nested `UtopiaTheme`s re-theme (or rescale) just their subtree.

**Ergonomic lookups** are context extensions, backed by `UtopiaTheme.of`:

```dart
context.theme;           // UtopiaThemeData
context.colors;          // UtopiaThemeColors
context.textStyles;      // UtopiaThemeTextStyles
context.tokens;          // UtopiaTokens
context.spacing;         // UtopiaSpacingTokens  e.g. context.spacing.md
context.radius;          // UtopiaRadiusTokens   e.g. context.radius.lgAll
context.fieldDecoration; // BoxDecoration for a field's background
```

To rebrand an app, construct your own `UtopiaThemeData` (via `UtopiaThemeData.fromTokens(...)` or
`UtopiaThemeData.defaultTheme.copyWith(...)`) and pass it to a `UtopiaTheme` at the root - every descendant
re-themes automatically.

## Design protocol

`utopia_ui` is the reference implementation of the Utopia Design Protocol - the first open,
bidirectional design-system protocol for Flutter. A shared, generic contract (design tokens plus
stable component ids) lets a design surface and a Flutter app stay in sync in both directions,
instead of a one-way "design-to-code" handoff.

<img src="https://raw.githubusercontent.com/Utopia-USS/utopia-ui/feat/design-protocol/docs/protocol/hero-flutter-components.png" width="49%" alt="The utopia_ui example app's Components page, live in Flutter"/> <img src="https://raw.githubusercontent.com/Utopia-USS/utopia-ui/feat/design-protocol/docs/protocol/hero-twin-default.png" width="49%" alt="The HTML twin's gallery, mirroring the same components"/>

The Flutter app (left) and the HTML twin (right) render the same components from the same
tokens. Rebrand the tokens and both surfaces follow - here the default theme becomes a pink
gradient brand with one token edit:

<img src="https://raw.githubusercontent.com/Utopia-USS/utopia-ui/feat/design-protocol/docs/protocol/hero-twin-rebrand.png" width="100%" alt="The HTML twin gallery after a token-only rebrand to a pink gradient brand"/>

The package ships three protocol artifacts, version-matched to the `utopia_ui` release you resolve:

- **Tokens** - a DTCG 2025.10 token document at [`tokens/utopia.tokens.json`](tokens/utopia.tokens.json),
  the canonical export of the default theme.
- **Manifest** - a component registry at [`manifest/utopia.manifest.json`](manifest/utopia.manifest.json)
  mapping every `utopia_ui` widget to a stable id, its props and its states.
- **Twin** - a static HTML/CSS mirror of the component library at [`twin/`](twin/), for design
  tools and reviewers that never open Flutter.

### The consumer loop

1. Bootstrap `design/tokens.json` in your project via the command printed by the tools (a copy of
   the packaged default DTCG document).
2. Edit or rebrand it - change token values to match your brand.
3. Validate it: `dart run utopia_design_tools:validate_tokens` (add `--fix` to re-derive
   rescaled values after changing the base unit).
4. Generate the theme and wire it: `dart run utopia_design_tools:generate_theme`, then pass the
   result to your root widget - `UtopiaTheme(data: buildUtopiaTheme(), child: ...)`.
5. Optionally, `dart run utopia_design_tools:generate_twin` for an always-current HTML design
   surface, and `dart run utopia_design_tools:generate_manifest --project` to register your own
   custom components with stable ids alongside the library's.

### v0 limits (roadmap)

Stated up front, not discovered later:

- **Single-context.** The protocol carries one theme at a time - there is no dark-mode pairing
  yet. A future version will add a second linked context.
- **Closed token tree.** The token document covers `utopia_ui`'s own scale and slots. Project-specific
  values (a one-off brand color used nowhere else, a bespoke metric) live as plain constants in your
  project code; custom components earn a manifest id through the project manifest (`generate_manifest
  --project`), not by growing the shared token tree.

### Install the tools

```
flutter pub add --dev utopia_design_tools
```

<sub>Before `utopia_design_tools` reaches pub.dev, add it as a git dependency on this repo
(path `tool/utopia_design_tools`) with a matching `dependency_overrides` entry - drop this
sentence once the tools package is published.</sub>

### Learn more

- [Protocol spec](https://github.com/Utopia-USS/utopia-ui/blob/feat/design-protocol/protocol/SPEC.md)
- [Versioning policy](https://github.com/Utopia-USS/utopia-ui/blob/feat/design-protocol/protocol/VERSIONING.md)
- [Token schema](https://github.com/Utopia-USS/utopia-ui/blob/feat/design-protocol/protocol/schemas/tokens.schema.json)
- [Manifest schema](https://github.com/Utopia-USS/utopia-ui/blob/feat/design-protocol/protocol/schemas/manifest.schema.json)

## The table

`UtopiaTable<T>` is a general-purpose, data-shape-agnostic table generic over a row type `T` of your choosing. It
is fully controlled: you pass rows, sort state and callbacks, and it renders and reports interaction - it never
owns app state itself. It's also sliver-first, so it composes into a `CustomScrollView` alongside your page's
other content rather than requiring its own scroll view.

Columns are declared as `UtopiaTableEntry<T>`:

```dart
UtopiaTableEntry<T>({
  required Widget Function(BuildContext, T) cellBuilder,
  String? id,             // falls back to `title` via `effectiveId`
  String? title,
  int? flex = 2,          // flexes like Expanded.flex
  Comparable<Object?>? Function(T)? sortBy,   // enables toggle-sort
  String? Function(T)? searchBy,              // enables client-side search
  List<UtopiaTableSortOption<T>>? sortOptions,   // named-orderings dropdown instead of a toggle
})

UtopiaTableEntry<T>.fixed({
  required Widget Function(BuildContext, T) cellBuilder,
  required double width,  // fixed instead of flexing
  // ... same optional fields as above
})
```

Sorting is controlled: `UtopiaTable.currentSort` (a `({String columnId, bool descending})` record) says which
column is active, and `onSortPressed` / `onSortSelected` report taps back to you. If you don't need
server-side sorting or search, the `useUtopiaTableState` hook gives you both for free, entirely client-side:

```dart
final tableState = useUtopiaTableState<TeamMember>(rows: members, entries: entries);

UtopiaTable<TeamMember>(
  rows: tableState.visibleRows,      // search-filtered, then sorted
  entries: entries,
  rowKey: (row) => row.name,
  currentSort: tableState.currentSort,
  onSortPressed: tableState.onSortPressed,
  onSortSelected: tableState.onSortSelected,
  searchPanel: UtopiaTableSearchPanel(
    searchField: UtopiaSearchField(
      value: tableState.searchState.value,
      hint: 'Search by name or role',
      onChanged: (value) => tableState.searchState.value = value ?? '',
    ),
  ),
)
```

`rows: null` renders a skeleton loader that mirrors the real row layout; an empty (non-null) list renders
`emptyWidget` (or `UtopiaTableEmpty` / a themed default "No items" message). Rows are matched across rebuilds by
`rowKey`, so reordering or inserting rows doesn't tear down unrelated row state.

Because it's a sliver, `UtopiaTable` is placed inside a `CustomScrollView`:

```dart
CustomScrollView(
  slivers: [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      sliver: UtopiaTable<TeamMember>(
        rows: tableState.visibleRows,
        entries: entries,
        rowKey: (row) => row.name,
        currentSort: tableState.currentSort,
        onSortPressed: tableState.onSortPressed,
      ),
    ),
  ],
)
```

## Dialogs

`UtopiaDialog` is adaptive dialog chrome: a full-screen surface on mobile widths, a centered rounded card
everywhere else - it resolves its own size class internally, so it works from any call site.

- **`UtopiaDialog(title:, builder:)`** - the raw constructor, full control of the body below the title row.
- **`UtopiaDialog.form(title:, sliver:, bottom:)`** - the common case: a scrollable sliver of fields with a
  pinned bottom action bar.
- **`UtopiaConfirmDialog`** - a neutral confirm/cancel prefab (no baked-in copy; you supply your own strings).

```dart
UtopiaButton(
  onTap: () => UtopiaDialog.show<void>(context, builder: (_) => const EditProfileDialog()),
  child: const Text('Edit profile'),
);

class EditProfileDialog extends StatelessWidget {
  const EditProfileDialog();

  @override
  Widget build(BuildContext context) {
    return UtopiaDialog.form(
      title: const Text('Edit profile'),
      sliver: SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        sliver: SliverList.list(
          children: [
            UtopiaTextField(value: 'Ava Chen', label: const Text('Name'), onChanged: (_) {}),
            const SizedBox(height: 14),
            UtopiaSwitchField(value: true, title: 'Active', onChanged: (_) {}),
          ],
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: UtopiaButton(onTap: () => Navigator.of(context).maybePop(), child: const Text('Done')),
      ),
    );
  }
}
```

A confirm prompt is a one-liner:

```dart
final confirmed = await UtopiaConfirmDialog.show(
  context,
  title: 'Remove member?',
  subtitle: 'This cannot be undone.',
  confirmLabel: 'Remove',
);
```

**Theme re-attachment.** `UtopiaDialog.show` and `UtopiaConfirmDialog.show` are thin wrappers over vanilla
`showDialog` - the only navigation opinion they take is capturing `UtopiaTheme.of(context)` before pushing the
route and re-wrapping the pushed builder in a `UtopiaTheme` with that data. This matters because `showDialog`
roots its route at the app `Navigator`, outside of any `UtopiaTheme` ancestor in your widget tree - without the
re-attachment, the dialog subtree would silently fall back to `UtopiaThemeData.defaultTheme` instead of inheriting
whatever theme is scoped around the call site. If you push a dialog through some other route mechanism, do the
same: capture `UtopiaTheme.of(context)` and wrap your builder's result in a `UtopiaTheme` with it.

## Sidebar

`UtopiaSidebar` is an adaptive navigation sidebar: a collapsible hover/pin rail on wide screens, a flush full-width
drawer body on small screens. It carries no data-layer or navigation opinions - it never pushes routes and
never closes its own drawer; "selected" means nothing more than `selectedId` matching a destination's `id`.

Items are one of three kinds:

```dart
UtopiaSidebarDestination(id: 'home', icon: const Icon(Icons.home_outlined), label: const Text('Home'));
UtopiaSidebarAction(icon: const Icon(Icons.logout), label: const Text('Sign out'), onPressed: signOut);
UtopiaSidebarCustom(builder: (context) => const Divider());
```

```dart
UtopiaSidebar(
  selectedId: selectedId,
  presentation: isWide ? UtopiaSidebarPresentation.rail : UtopiaSidebarPresentation.drawer,
  onDestinationPressed: (destination) => onSelect(destination.id),
  items: [
    UtopiaSidebarDestination(id: 'home', icon: const Icon(Icons.home_outlined), label: const Text('Home')),
    UtopiaSidebarDestination(id: 'settings', icon: const Icon(Icons.settings_outlined), label: const Text('Settings')),
    UtopiaSidebarAction(icon: const Icon(Icons.logout), label: const Text('Sign out'), onPressed: signOut),
  ],
)
```

`presentation` chooses `rail` (default: collapsed by default, peeks open on hover, pins open via the top toggle
icon) or `drawer` (always full and flush - host it in your own `Scaffold.drawer` and close it yourself after a
tap). Resolve `isWide` from the *window* width against `tokens.breakpoints.sidebarMin` (1000 by default) - the
shell breakpoint is measured before the sidebar takes its share, unlike the content size classes. `style`
(`UtopiaSidebarStyle`) is opt-in branding: a `backgroundColors` gradient and a `headerBuilder` for a logo pinned
above the items; leaving both unset renders a plain surface card matching the content card.

**Pinning items to the bottom.** The sidebar's body sizes itself to the larger of the viewport and its content,
which means `Expanded` / `Spacer` items are supported as direct entries and will consume the free space left
when the items above are shorter than the viewport - the way to push trailing items (e.g. "Sign out", a version
label) down to the sidebar's bottom edge is a `UtopiaSidebarCustom` spacer between the two groups:

```dart
items: [
  UtopiaSidebarDestination(id: 'home', icon: const Icon(Icons.home_outlined), label: const Text('Home')),
  UtopiaSidebarDestination(id: 'settings', icon: const Icon(Icons.settings_outlined), label: const Text('Settings')),
  const UtopiaSidebarCustom(builder: _buildSpacer),
  UtopiaSidebarAction(icon: const Icon(Icons.logout), label: const Text('Sign out'), onPressed: signOut),
],

// top-level function or static method
Widget _buildSpacer(BuildContext context) => const Spacer();
```

A `UtopiaSidebarCustom` builder is safe to build with a `LayoutBuilder` (the body deliberately avoids
`IntrinsicHeight`, which cannot be computed through one) - useful for custom entries that need their own
constraints-aware layout.

## Component index

Everything below is exported from the single barrel, `package:utopia_ui/utopia_ui.dart` - there are no
per-family barrels and no deep imports into `src/`.

**Theme & tokens**
`UtopiaTheme`, `UtopiaThemeData`, `UtopiaThemeColors`, `UtopiaThemeTextStyles`, `UtopiaTokens` (with the
`UtopiaSpacingTokens` / `UtopiaRadiusTokens` / `UtopiaBorderTokens` / `UtopiaShadowTokens` / `UtopiaFontWeightTokens` /
`UtopiaDurationTokens` / `UtopiaBreakpointTokens` families), and the `context.theme` / `context.colors` /
`context.textStyles` / `context.tokens` / `context.spacing` / `context.radius` / `context.fieldDecoration` extensions.

**Buttons**
`UtopiaButton` - the primary call-to-action button, with an inline loading state.
`UtopiaRemoveIconButton` - a small "x" affordance to remove/clear a value.

**Chips**
`UtopiaChip`, `UtopiaChipList` - themed tags, with overflow collapsing on `UtopiaChipList`.

**Fields**
`UtopiaTextField`, `UtopiaSearchField`, `UtopiaDropdownField`, `UtopiaSwitch`, `UtopiaSwitchField`, `UtopiaCheckRow`,
`UtopiaDatePicker`, `UtopiaFieldWrapper` (shared field chrome), `UtopiaLabeledField` (read-only, "picked value" field
chrome used by dropdowns).

**Dialogs**
`UtopiaDialog` (raw and `.form`), `UtopiaConfirmDialog`.

**Sidebar**
`UtopiaSidebar`, `UtopiaSidebarDestination`, `UtopiaSidebarAction`, `UtopiaSidebarCustom`, `UtopiaSidebarStyle`,
`UtopiaSidebarPresentation`.

**Table**
`UtopiaTable<T>`, `UtopiaTableEntry<T>`, `UtopiaTableSort`, `UtopiaTableSortOption<T>`, `UtopiaTableSearchPanel`,
`UtopiaTableEmpty`, `UtopiaTableState<T>` / `useUtopiaTableState`.

**Layout**
`UtopiaBreakpoints`, `UtopiaPageWrapper`, `UtopiaPageType`, `UtopiaCard`, `UtopiaDivider`, `UtopiaGradientBackground`,
`UtopiaFormLayout` (scrollable content over a pinned bottom bar, with a scroll-aware fade bar).

**Misc**
`UtopiaCollapsible` (axis-collapse animation wrapper), `UtopiaMultiWidget` (flattens deeply nested wrapper widgets).

**Loading**
`UtopiaLoader`, `UtopiaMockLoadingBox` (skeleton placeholder), `UtopiaThreeBounce` (the indicator inside `UtopiaButton`).

**Overlay**
`UtopiaOverlayAnchor` - an anchored popup/dropdown follower built on native Flutter, no extra dependency.

**Text**
`UtopiaTitle`, `UtopiaCopyableText` (tap-to-copy text with a confirmation).

**Utilities**
`UtopiaDateTimeExtension` - `DateTime` display-formatting and calendar arithmetic used by `UtopiaDatePicker`. Plus
`IList` / `FicIterableExtension` (from `fast_immutable_collections`), re-exported since they appear in this
package's own public API (`UtopiaTable.rows`, entry lists, `useUtopiaTableState`).

## Related packages

| Package | What it adds |
|---|---|
| [utopia_cms](https://pub.dev/packages/utopia_cms) | A CMS framework built on this kind of component: delegates, entries, CRUD flows |
| [utopia_hooks](https://pub.dev/packages/utopia_hooks) | State management with hooks |

Built by [Utopiasoft](https://utopiasoft.io).

## Contributing

👾 Contributions are welcome - open an issue to discuss a change, or send a pull request.

## License

BSD-3-Clause. See [LICENSE](LICENSE).

[pub_badge]: https://img.shields.io/pub/v/utopia_ui.svg?logo=dart
[pub_link]: https://pub.dev/packages/utopia_ui
[publisher_badge]: https://img.shields.io/pub/publisher/utopia_ui.svg?color=7A4FC2
[publisher_link]: https://pub.dev/publishers/utopiasoft.io
[license_badge]: https://img.shields.io/badge/license-BSD--3--Clause-2E8B57.svg
[license_link]: LICENSE
[style_badge]: https://img.shields.io/badge/style-utopia__lints-0B5EA2.svg
[style_link]: https://pub.dev/packages/utopia_lints
