import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// Anchors a dismissible popup beneath a trigger using the framework's
/// [OverlayPortal] + [CompositedTransformFollower] - no external portal package.
///
/// Uses the two-layer portal pattern (a full-screen tap-to-dismiss barrier
/// behind an anchored follower), built on native Flutter so core ships zero
/// extra dependencies.
class UtopiaOverlayAnchor extends HookWidget {
  /// Builds the trigger. Call `open` (e.g. from a tap) to show the popup.
  final Widget Function(BuildContext context, VoidCallback open) triggerBuilder;

  /// Builds the popup content. Call `close` to dismiss it.
  final Widget Function(BuildContext context, VoidCallback close) overlayBuilder;

  /// Hard cap on popup height; content scrolls beyond it.
  final double maxHeight;

  /// Stretch the popup to the trigger's allotted width (else it sizes to content).
  final bool matchTriggerWidth;

  /// Creates a dismissible popup anchored to a trigger.
  const UtopiaOverlayAnchor({
    super.key,
    required this.triggerBuilder,
    required this.overlayBuilder,
    this.maxHeight = 320,
    this.matchTriggerWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final link = useMemoized(LayerLink.new);
    final controller = useMemoized(OverlayPortalController.new);
    final theme = context.theme;

    void close() => controller.hide();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = matchTriggerWidth && constraints.hasBoundedWidth ? constraints.maxWidth : null;
        return CompositedTransformTarget(
          link: link,
          child: OverlayPortal(
            controller: controller,
            overlayChildBuilder: (context) => Stack(
              children: [
                // Layer 1: tap-outside-to-dismiss barrier (opaque: swallow the tap
                // instead of leaking it to whatever sits behind the popup).
                Positioned.fill(
                  child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: close),
                ),
                // Layer 2: the popup, anchored to the trigger's bottom-left.
                CompositedTransformFollower(
                  link: link,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.bottomLeft,
                  offset: const Offset(0, 6),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: width,
                      // Absorb taps that land on the popup chrome so they don't
                      // fall through to the dismiss barrier and close it.
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: Container(
                          constraints: BoxConstraints(maxHeight: maxHeight),
                          decoration: theme.cardDecoration,
                          foregroundDecoration: theme.cardBorderDecoration,
                          clipBehavior: Clip.antiAlias,
                          child: overlayBuilder(context, close),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            child: triggerBuilder(context, controller.show),
          ),
        );
      },
    );
  }
}
