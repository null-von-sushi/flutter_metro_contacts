import 'package:flutter/material.dart';
import '../other/accent_color.dart';

/// A Windows Phone style picker.
///
/// Renders a label above a tappable box. On press, the box inverts (white
/// background, black text) and the border changes to the current accent colour.
class WpPicker extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? leadingSwatch;

  const WpPicker({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.leadingSwatch,
  });

  @override
  State<WpPicker> createState() => _WpPickerState();
}

class _WpPickerState extends State<WpPicker> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    final bgColor = _isPressed && enabled ? Colors.white : Colors.black;
    final borderColor = _isPressed && enabled ? AccentColor : Colors.white;
    final textColor = _isPressed && enabled
        ? Colors.black
        : (enabled ? Colors.white : Colors.white30);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 20,
              height: 1.1,
              fontWeight: FontWeight.w300,
              color: Color(0xffa6a6a6),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown:
            enabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp:
            enabled ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel:
            enabled ? () => setState(() => _isPressed = false) : null,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  if (widget.leadingSwatch != null) ...[
                    Container(
                      width: 16,
                      height: 16,
                      color: widget.leadingSwatch,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}