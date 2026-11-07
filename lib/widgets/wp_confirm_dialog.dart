import 'package:flutter/material.dart';
import 'wp_button.dart';

/// A Windows Phone style confirmation dialog.
///
/// Anchored to the top of the screen and horizontally fills the entire width.
/// If [dangerous] is true, the confirm button will use a reddish press
/// color (useful for delete/remove actions).
class WpConfirmDialog extends StatelessWidget {
  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final bool dangerous;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const WpConfirmDialog({
    super.key,
    required this.title,
    this.confirmLabel = 'ok',
    this.cancelLabel = 'cancel',
    this.dangerous = false,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Anchors the dialog to the top and removes standard margins
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        // Using the app's standard dark grey 0xFF1F1F1F. Change to Colors.black
        // if you want it to match the screenshot exactly.
        color: const Color(0xFF1F1F1F),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: WpButton(
                        label: cancelLabel,
                        onPressed: onCancel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WpButton(
                        label: confirmLabel,
                        pressedColor: dangerous
                            ? Colors.red.shade700
                            : const Color(0xFF2A2A2A),
                        onPressed: onConfirm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}