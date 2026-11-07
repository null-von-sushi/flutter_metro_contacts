import 'package:flutter/material.dart';

/// A Windows Phone style button: black fill, thick white border, sharp
/// corners, plain white text. Width fits the content unless a parent
/// constrains it.
class WpButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double fontSize;

  /// Fill colour shown while the button is held down. Defaults to a
  /// subtle dark grey; pass e.g. `AccentColor` for destructive actions.
  final Color pressedColor;

  const WpButton({
    super.key,
    required this.label,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.borderWidth = 2,
    this.fontSize = 18,
    this.pressedColor = const Color(0xFF2A2A2A),
  });

  @override
  State<WpButton> createState() => _WpButtonState();
}

class _WpButtonState extends State<WpButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final foreground = enabled ? Colors.white : Colors.white30;
    final fill = _pressed ? widget.pressedColor : Color(0xFF1F1F1F);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        padding: widget.padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: foreground, width: widget.borderWidth),
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}