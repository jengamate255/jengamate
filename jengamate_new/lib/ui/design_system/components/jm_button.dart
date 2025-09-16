import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum JMButtonSize { small, medium, large }
enum JMButtonVariant { primary, secondary, danger, success, warning }

class JMButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final JMButtonVariant variant;
  final JMButtonSize size;
  final IconData? icon;
  final String? label;
  final bool enableHapticFeedback;
  final bool fullWidth;
  final BorderRadius? borderRadius;

  const JMButton({
    super.key,
    this.onPressed,
    required this.child,
    this.isLoading = false,
    this.variant = JMButtonVariant.primary,
    this.size = JMButtonSize.medium,
    this.icon,
    this.label,
    this.enableHapticFeedback = true,
    this.fullWidth = false,
    this.borderRadius,
  });

  @override
  State<JMButton> createState() => _JMButtonState();
}

class _JMButtonState extends State<JMButton> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enableHapticFeedback && !widget.isLoading) {
      HapticFeedback.lightImpact();
    }

    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      widget.onPressed!();
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.isLoading) {
      return theme.colorScheme.surfaceContainerHighest;
    }

    switch (widget.variant) {
      case JMButtonVariant.primary:
        return theme.colorScheme.primary;
      case JMButtonVariant.secondary:
        return theme.colorScheme.secondary;
      case JMButtonVariant.danger:
        return theme.colorScheme.error;
      case JMButtonVariant.success:
        return const Color(0xFF2E7D32);
      case JMButtonVariant.warning:
        return const Color(0xFFF9A825);
    }
  }

  Color _getForegroundColor(ThemeData theme) {
    if (widget.isLoading) {
      return theme.colorScheme.onSurface;
    }

    switch (widget.variant) {
      case JMButtonVariant.primary:
        return theme.colorScheme.onPrimary;
      case JMButtonVariant.secondary:
        return theme.colorScheme.onSecondary;
      case JMButtonVariant.danger:
        return theme.colorScheme.onError;
      case JMButtonVariant.success:
        return Colors.white;
      case JMButtonVariant.warning:
        return Colors.black;
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case JMButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case JMButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case JMButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case JMButtonSize.small:
        return 12;
      case JMButtonSize.medium:
        return 14;
      case JMButtonSize.large:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: widget.size == JMButtonSize.small ? 16 : 18,
          ),
          const SizedBox(width: 8),
        ],
        if (widget.label != null)
          Flexible(
            child: Text(
              widget.label!,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: _getFontSize(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (widget.icon == null && widget.label == null) widget.child,
        if (widget.isLoading) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: widget.size == JMButtonSize.small ? 12 : 16,
            height: widget.size == JMButtonSize.small ? 12 : 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getForegroundColor(theme)),
            ),
          ),
        ],
      ],
    );

    final button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isLoading ? 1.0 : _scaleAnimation.value,
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : _handleTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(theme),
          foregroundColor: _getForegroundColor(theme),
          padding: _getPadding(),
          elevation: widget.isLoading ? 0 : 2,
          shadowColor: _getBackgroundColor(theme).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          ),
          minimumSize: widget.fullWidth ? const Size(double.infinity, 0) : null,
        ),
        child: child,
      ),
    );

    return Semantics(
      button: true,
      enabled: !widget.isLoading && widget.onPressed != null,
      label: widget.label ?? 'Button',
      child: widget.fullWidth
          ? button
          : ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: widget.size == JMButtonSize.small ? 80 : 120,
              ),
              child: button,
            ),
    );
  }
}
