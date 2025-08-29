import 'package:flutter/material.dart';

class TierChip extends StatelessWidget {
  final String text;
  final Color color;
  final EdgeInsets padding;
  final bool outlined;

  const TierChip({
    super.key,
    required this.text,
    required this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.15);
    final borderColor = outlined
        ? color.withValues(alpha: 0.35)
        : Colors.transparent;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
