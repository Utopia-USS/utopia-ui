import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

/// A stock/instrument quote, used by [MarketTile]. Exercises a project model
/// referenced by an opt-in component's props (SPEC 3.8: models/helpers
/// extraction closes over included components' props only).
class Quote {
  /// The ticker symbol, e.g. "ACME".
  final String symbol;

  /// The last traded price.
  final double price;

  /// Whether the last move was a gain (controls the tile's accent colour).
  final bool isGain;

  /// Creates a quote.
  const Quote({required this.symbol, required this.price, required this.isGain});
}

/// Layout density for [MarketTile]. Exercises a project-declared enum prop.
enum TileDensity {
  /// A shorter tile, tighter internal padding.
  compact,

  /// The default, comfortable spacing.
  regular,
}

/// The legal "values on the side" pattern (protocol SPEC 3.8): project-
/// specific gain/loss colours live as plain project constants, not in the
/// closed theme tree.
const Color _gainColor = Color(0xFF1B873F);
const Color _lossColor = Color(0xFFB3261E);

/// A custom project component composing `UtopiaCard` + `UtopiaChip`, reading
/// the theme (`context.colors`/`context.spacing`) while also taking a
/// project-specific model ([Quote]) and enum ([TileDensity]) prop. The
/// canonical "stock-market tile" example from the protocol's AMENDMENT 1.
class MarketTile extends StatelessWidget {
  /// The quote this tile displays.
  final Quote quote;

  /// Layout density.
  final TileDensity density;

  /// Creates a market tile for [quote] at the given [density].
  const MarketTile({super.key, required this.quote, this.density = TileDensity.regular});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final accent = quote.isGain ? _gainColor : _lossColor;
    final padding = density == TileDensity.compact ? spacing.sm : spacing.md;

    return UtopiaCard(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(quote.symbol, style: TextStyle(color: colors.text)),
            UtopiaChip(color: accent, child: Text(quote.price.toStringAsFixed(2))),
          ],
        ),
      ),
    );
  }
}

/// A second project widget deliberately left WITHOUT an overlay, to exercise
/// the opt-in extraction rule (SPEC 3.8): this class must NOT be included in
/// the generated project manifest even though it is a perfectly ordinary
/// concrete widget.
class UnregisteredWidget extends StatelessWidget {
  /// Creates the unregistered widget.
  const UnregisteredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// A widget whose derived local part ("demo-rating-stars") deliberately does
/// NOT match its overlay's filename ("star-rating.yaml"), to exercise the
/// SPEC 3.3 class-override mechanism: the overlay carries an explicit
/// `class: DemoRatingStars` key, binding it to this class under the
/// filename's local part instead of the derived one.
class DemoRatingStars extends StatelessWidget {
  /// Number of filled stars, 0-5.
  final int filled;

  /// Creates a star rating row.
  const DemoRatingStars({super.key, required this.filled});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [for (var i = 0; i < 5; i++) Icon(Icons.star, color: i < filled ? colors.primary : colors.border)],
    );
  }
}
