import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

enum JMCardVariant { elevated, outlined, filled }
enum JMCardSize { small, medium, large }

class JMCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final JMCardVariant variant;
  final JMCardSize size;
  final bool enableHover;
  final bool enablePress;
  final Widget? leading;
  final Widget? trailing;
  final String? title;
  final String? subtitle;

  const JMCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.variant = JMCardVariant.elevated,
    this.size = JMCardSize.medium,
    this.enableHover = true,
    this.enablePress = true,
    this.leading,
    this.trailing,
    this.title,
    this.subtitle,
  });

  @override
  State<JMCard> createState() => _JMCardState();
}

class _JMCardState extends State<JMCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _pressAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (!widget.enableHover) return;

    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _handlePress(bool isPressed) {
    if (!widget.enablePress) return;

    setState(() {
      _isPressed = isPressed;
    });

    if (isPressed) {
      _pressController.forward();
    } else {
      _pressController.reverse();
    }
  }

  EdgeInsets _getPadding() {
    if (widget.padding != null) return widget.padding!;

    switch (widget.size) {
      case JMCardSize.small:
        return const EdgeInsets.all(JMSpacing.sm);
      case JMCardSize.medium:
        return const EdgeInsets.all(JMSpacing.md);
      case JMCardSize.large:
        return const EdgeInsets.all(JMSpacing.lg);
    }
  }

  EdgeInsets _getMargin() {
    return widget.margin ?? const EdgeInsets.all(JMSpacing.md);
  }

  double _getElevation() {
    if (widget.elevation != null) return widget.elevation!;

    double baseElevation;
    switch (widget.variant) {
      case JMCardVariant.elevated:
        baseElevation = 4.0;
        break;
      case JMCardVariant.outlined:
        baseElevation = 0.0;
        break;
      case JMCardVariant.filled:
        baseElevation = 2.0;
        break;
    }

    if (_isHovered) {
      baseElevation += 2.0;
    }

    return baseElevation;
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    switch (widget.variant) {
      case JMCardVariant.elevated:
        return theme.colorScheme.surface;
      case JMCardVariant.outlined:
        return theme.colorScheme.surface;
      case JMCardVariant.filled:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  ShapeBorder _getShape(ThemeData theme) {
    final borderRadius = BorderRadius.circular(12);

    switch (widget.variant) {
      case JMCardVariant.elevated:
        return RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        );
      case JMCardVariant.outlined:
        return RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: theme.colorScheme.outline,
            width: 1.5,
          ),
        );
      case JMCardVariant.filled:
        return RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide.none,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = Padding(
      padding: _getPadding(),
      child: widget.leading != null || widget.trailing != null || widget.title != null || widget.subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.leading != null || widget.title != null || widget.trailing != null)
                  Row(
                    children: [
                      if (widget.leading != null) ...[
                        widget.leading!,
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.title != null)
                              Text(
                                widget.title!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (widget.subtitle != null)
                              Text(
                                widget.subtitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.trailing != null) ...[
                        const SizedBox(width: 8),
                        widget.trailing!,
                      ],
                    ],
                  ),
                if (widget.leading != null || widget.title != null || widget.trailing != null)
                  const SizedBox(height: 12),
                widget.child,
              ],
            )
          : widget.child,
    );

    final card = AnimatedBuilder(
      animation: Listenable.merge([_hoverAnimation, _pressAnimation]),
      builder: (context, child) {
        final hoverScale = 1.0 + (_hoverAnimation.value * 0.02);
        final pressScale = _pressAnimation.value;
        final scale = hoverScale * pressScale;

        return Transform.scale(
          scale: scale,
          child: Card(
            margin: _getMargin(),
            elevation: _getElevation(),
            color: _getBackgroundColor(theme),
            shape: _getShape(theme),
            child: InkWell(
              onTap: widget.onTap,
              onHover: _handleHover,
              onTapDown: (_) => _handlePress(true),
              onTapUp: (_) => _handlePress(false),
              onTapCancel: () => _handlePress(false),
              borderRadius: BorderRadius.circular(12),
              child: cardContent,
            ),
          ),
        );
      },
    );

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.title ?? 'Card',
      child: card,
    );
  }
}
