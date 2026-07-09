import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A raised, rounded, hairline-bordered surface - the container the table and
/// other grouped content sit on. Styling comes from `UtopiaThemeData.cardDecoration`
/// and `cardBorderDecoration`, so it stays themable from one place.
class UtopiaCard extends StatelessWidget {
  /// The content laid over the card decoration.
  final Widget child;

  /// Creates a card surface around [child].
  const UtopiaCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: context.theme.cardDecoration,
      foregroundDecoration: context.theme.cardBorderDecoration,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// The sliver counterpart of [UtopiaCard]: wraps [sliver] in the card decoration -
/// a filled, rounded, shadowed back layer plus a foreground hairline border.
///
/// A [DecoratedSliver] does not clip its child, so round the last row yourself
/// (see `UtopiaTableItem`) to keep it off the rounded bottom corners.
Widget utopiaCardSliver(BuildContext context, {required Widget sliver}) {
  final theme = context.theme;
  return DecoratedSliver(
    decoration: theme.cardDecoration,
    sliver: DecoratedSliver(
      decoration: theme.cardBorderDecoration,
      position: DecorationPosition.foreground,
      sliver: sliver,
    ),
  );
}
