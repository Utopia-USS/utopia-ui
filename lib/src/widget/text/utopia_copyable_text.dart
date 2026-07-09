import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/misc/utopia_multi_widget.dart';

/// A single-line, ellipsized text label that copies its value to the
/// clipboard on tap, showing a tooltip with the full text and a snackbar
/// confirmation once copied. A `null` [text] renders as `-` and is not
/// copyable.
class UtopiaCopyableText extends StatelessWidget {
  /// The text to display and copy; `null` renders as `-` and disables copying.
  final String? text;

  /// Creates a copy-on-tap text label.
  const UtopiaCopyableText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.text;

    return Align(
      alignment: Alignment.centerLeft,
      child: UtopiaMultiWidget([
        if (text != null) (child) => Tooltip(message: text!, child: child),
        (_) => _buildContent(style: style, context: context),
      ]),
    );
  }

  Widget _buildContent({required TextStyle style, required BuildContext context}) {
    return _buildGestureDetector(
      context: context,
      child: Text(text ?? '-', style: style, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildGestureDetector({required Widget child, required BuildContext context}) {
    final snackbarTextStyle = context.textStyles.button;
    final snackbarBackgroundColor = context.colors.accent;
    final screenWidth = MediaQuery.of(context).size.width;
    return MouseRegion(
      cursor: text != null ? SystemMouseCursors.copy : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: () async {
          if (text != null) {
            await Clipboard.setData(ClipboardData(text: text!));
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(_buildSnackBar(snackbarTextStyle, snackbarBackgroundColor, screenWidth));
          }
        },
        child: child,
      ),
    );
  }

  SnackBar _buildSnackBar(TextStyle style, Color backgroundColor, double screenWidth) {
    const double width = 200;
    final margin = (screenWidth - width) / 2;
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      margin: EdgeInsets.fromLTRB(margin, 0, margin, 36),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
