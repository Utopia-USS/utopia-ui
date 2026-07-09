import 'package:flutter/widgets.dart';

/// Base type for entries rendered by `UtopiaSidebar`.
///
/// A plain sealed hierarchy (no code generation): [UtopiaSidebarDestination] for
/// selectable pages, [UtopiaSidebarAction] for fire-and-forget commands, and
/// [UtopiaSidebarCustom] for an arbitrary widget slot.
sealed class UtopiaSidebarItem {
  const UtopiaSidebarItem();
}

/// A selectable page entry.
///
/// [id] is matched against the sidebar's `selectedId` to decide whether the
/// tile renders as selected; it is otherwise opaque to the sidebar (callers
/// own what it means - a route name, a page key, anything stable).
class UtopiaSidebarDestination extends UtopiaSidebarItem {
  /// Stable identifier compared against the sidebar's `selectedId`.
  final String id;

  /// The label shown next to [icon] while the sidebar is expanded. Usually a
  /// `Text`; styled by the tile via `DefaultTextStyle`.
  final Widget label;

  /// The leading glyph, shown at all times (collapsed rail, expanded rail,
  /// drawer).
  final Widget icon;

  /// Creates a selectable page entry.
  const UtopiaSidebarDestination({required this.id, required this.label, required this.icon});
}

/// A fire-and-forget entry: tapping it invokes [onPressed] and never becomes
/// "selected", unlike [UtopiaSidebarDestination].
class UtopiaSidebarAction extends UtopiaSidebarItem {
  /// The label shown next to [icon] while the sidebar is expanded. Usually a
  /// `Text`; styled by the tile via `DefaultTextStyle`.
  final Widget label;

  /// The leading glyph, shown at all times.
  final Widget icon;

  /// Invoked when the tile is tapped.
  final VoidCallback onPressed;

  /// Creates a fire-and-forget entry.
  const UtopiaSidebarAction({required this.label, required this.icon, required this.onPressed});
}

/// An arbitrary widget slot rendered in place of a tile.
///
/// Contract: [builder] receives *bounded width* (the sidebar's current
/// collapsed/expanded rail width, or the fixed drawer width) inside a column
/// whose height is the larger of the viewport and the content - the sidebar
/// scrolls when items overflow. A `LayoutBuilder`-based child is safe here:
/// the body deliberately avoids `IntrinsicHeight` (which cannot be computed
/// through a `LayoutBuilder` and would crash). `Expanded`/`Spacer` children
/// are also supported and consume the free space left when the items are
/// shorter than the viewport - the idiomatic way to pin trailing items to
/// the sidebar's bottom edge.
class UtopiaSidebarCustom extends UtopiaSidebarItem {
  /// Builds the slot's content.
  final WidgetBuilder builder;

  /// Creates an arbitrary widget slot.
  const UtopiaSidebarCustom({required this.builder});
}
