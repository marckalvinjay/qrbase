import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class MenuButton extends StatefulWidget {
  const MenuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width = 220,
    this.height = 64,
    this.borderRadius = 18,
  });

  final String label;
  final VoidCallback onPressed;
  final List<List<dynamic>>? icon;
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF131B31) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2B3A55) : const Color(0xFFF1C9D6);
    final textColor = isDark ? const Color(0xFFEAF7FF) : const Color(0xFFFB9EB7);
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          HugeIcon(icon: widget.icon!, color: textColor, size: 22),
          const SizedBox(width: 10),
        ],
        Text(
          widget.label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
