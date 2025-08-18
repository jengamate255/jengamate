import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class JMButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool filled;
  final IconData? icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool enableHapticFeedback;
  final Duration animationDuration;

  const JMButton({
    super.key,
    this.onPressed,
    required this.child,
    this.isLoading = false,
    this.filled = true,
    this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.enableHapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<JMButton> createState() => _JMButtonState();
}

class _JMButtonState extends State<JMButton> {

  void _handleTap() {
    if (widget.enableHapticFeedback && !widget.isLoading) {
      HapticFeedback.lightImpact();
    }
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
        ],
        if (widget.label != null)
          Flexible(
            child: Text(
              widget.label!,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        if (widget.icon == null && widget.label == null) widget.child,
      ],
    );
    return widget.filled
        ? FilledButton(onPressed: _handleTap, style: FilledButton.styleFrom(backgroundColor: scheme.primary), child: child)
        : OutlinedButton(onPressed: _handleTap, child: child);
  }
}
