import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utopia_ui/src/theme/utopia_tokens.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/misc/utopia_multi_widget.dart';

/// A single-line, ellipsized text label that copies its value to the
/// clipboard on tap, showing a tooltip with the full text and a snackbar
/// confirmation once copied. Tints to the accent colour on hover so the copy
/// affordance is visible before the cursor change. A `null` [text] renders
/// as `-` and is not copyable.
class UtopiaCopyableText extends HookWidget {
  /// The text to display and copy; `null` renders as `-` and disables copying.
  final String? text;

  /// Creates a copy-on-tap text label.
  const UtopiaCopyableText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    // Hook lives here (not in the nested builder closure): UtopiaMultiWidget
    // invokes its builders during its own build, outside this hook context.
    final hovering = useState<bool>(false);
    return Align(
      alignment: Alignment.centerLeft,
      child: UtopiaMultiWidget([
        if (text != null) (child) => Tooltip(message: text!, child: child),
        (_) => _buildContent(context, hovering),
      ]),
    );
  }

  Widget _buildContent(BuildContext context, StateHookState<bool> hovering) {
    final style = context.textStyles.text;
    return _buildGestureDetector(
      context: context,
      hovering: hovering,
      child: AnimatedDefaultTextStyle(
        duration: context.tokens.durations.xs,
        style: hovering.value && text != null ? style.copyWith(color: context.colors.accent) : style,
        overflow: TextOverflow.ellipsis,
        child: Text(text ?? '-'),
      ),
    );
  }

  Widget _buildGestureDetector({
    required Widget child,
    required BuildContext context,
    required StateHookState<bool> hovering,
  }) {
    final snackbarTextStyle = context.textStyles.button;
    final snackbarBackgroundColor = context.colors.accent;
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = context.spacing;
    return MouseRegion(
      cursor: text != null ? SystemMouseCursors.copy : SystemMouseCursors.basic,
      onEnter: (_) => hovering.value = true,
      onExit: (_) => hovering.value = false,
      child: GestureDetector(
        onTap: () async {
          if (text != null) {
            await Clipboard.setData(ClipboardData(text: text!));
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(_buildSnackBar(snackbarTextStyle, snackbarBackgroundColor, screenWidth, spacing));
          }
        },
        child: child,
      ),
    );
  }

  SnackBar _buildSnackBar(TextStyle style, Color backgroundColor, double screenWidth, UtopiaSpacingTokens spacing) {
    const double width = 200;
    final margin = (screenWidth - width) / 2;
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      margin: EdgeInsets.fromLTRB(margin, 0, margin, spacing.xxl),
      padding: EdgeInsets.symmetric(horizontal: spacing.xl, vertical: spacing.md),
      elevation: 20,
      content: Row(
        children: [
          Text("Copied", style: style),
          const Spacer(),
          Icon(Icons.done_all, color: style.color),
        ],
      ),
    );
  }
}
