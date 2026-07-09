/// Single source of truth for utopia_ui responsive breakpoints.
///
/// Two independent families, deliberately measured at different nodes of the
/// tree - do not collapse them into one:
///
/// * **Content** ([tabletMin] / [webMin]) - resolved by `UtopiaPageWrapper` from
///   the width the content actually receives, *after* the sidebar has taken its
///   share. Drives form column nesting, table layout and paddings. The same
///   window width can map to a different content class depending on the sidebar
///   state - that is intended, because the content wrapper knows nothing about
///   the sidebar.
/// * **Shell** ([sidebarMin]) - resolved by the shell from the full *window*
///   width. A single line: at or above it the sidebar is an in-layout rail
///   (collapsed by default, hover-peeks, pinned open via the top toggle); below
///   it - on tablet and phone alike - the sidebar is hidden behind a drawer,
///   reached by the burger next to the page title. Separate from the content
///   family precisely because it is measured before the sidebar exists.
abstract final class UtopiaBreakpoints {
  // --- Content size classes (measured on content width) ---

  /// At or above this content width the layout is at least
  /// `UtopiaPageType.tablet`; below it, `UtopiaPageType.mobile`.
  static const double tabletMin = 600;

  /// At or above this content width the layout is `UtopiaPageType.web`.
  static const double webMin = 900;

  // --- Shell / sidebar (measured on window width) ---

  /// At or above this window width the shell shows the sidebar as a rail;
  /// below it (tablet and phone), the sidebar is hidden behind a drawer.
  static const double sidebarMin = 900;
}
