import 'package:flutter/material.dart';
import '../design_system/tokens/spacing.dart';

enum JMLoadingOverlayType { fullscreen, inline, card }

class JMLoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;
  final String? loadingTitle;
  final JMLoadingOverlayType type;
  final bool dismissible;
  final VoidCallback? onDismiss;
  final Widget? customLoader;
  final bool showProgressBar;
  final double? progressValue;
  final Color? overlayColor;
  final Color? progressColor;

  const JMLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
    this.loadingTitle,
    this.type = JMLoadingOverlayType.fullscreen,
    this.dismissible = false,
    this.onDismiss,
    this.customLoader,
    this.showProgressBar = false,
    this.progressValue,
    this.overlayColor,
    this.progressColor,
  });

  @override
  State<JMLoadingOverlay> createState() => _JMLoadingOverlayState();
}

class _JMLoadingOverlayState extends State<JMLoadingOverlay> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(JMLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildLoader() {
    if (widget.customLoader != null) {
      return widget.customLoader!;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated loader
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.progressColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (widget.loadingTitle != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.loadingTitle!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.loadingMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.loadingMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.showProgressBar) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: widget.progressValue,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.progressColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineLoader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.progressColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (widget.loadingMessage != null) ...[
            const SizedBox(width: 12),
            Text(
              widget.loadingMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case JMLoadingOverlayType.inline:
        return Column(
          children: [
            widget.child,
            if (widget.isLoading) _buildInlineLoader(),
          ],
        );

      case JMLoadingOverlayType.card:
        return Stack(
          children: [
            widget.child,
            if (widget.isLoading)
              Positioned.fill(
                child: Container(
                  color: widget.overlayColor ?? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                  child: Center(
                    child: _buildLoader(),
                  ),
                ),
              ),
          ],
        );

      case JMLoadingOverlayType.fullscreen:
      default:
        return Stack(
          children: [
            widget.child,
            if (widget.isLoading)
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      color: widget.overlayColor ?? Colors.black.withValues(alpha: 0.4),
                      child: widget.dismissible
                          ? GestureDetector(
                              onTap: widget.onDismiss,
                              child: Center(
                                child: _buildLoader(),
                              ),
                            )
                          : Center(
                              child: _buildLoader(),
                            ),
                    ),
                  );
                },
              ),
          ],
        );
    }
  }
}

// Enhanced skeleton loader with better animations
class JMSkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Widget? loadingWidget;

  const JMSkeletonLoader({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingWidget,
  });

  @override
  State<JMSkeletonLoader> createState() => _JMSkeletonLoaderState();
}

class _JMSkeletonLoaderState extends State<JMSkeletonLoader> with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Theme.of(context).colorScheme.surfaceContainerHighest,
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
              stops: [
                0.0,
                _shimmerAnimation.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.loadingWidget ?? widget.child,
        );
      },
    );
  }
}

/// Extension method to easily show loading overlay on any widget
extension LoadingOverlayExtension on Widget {
  Widget withJMLoadingOverlay({
    required bool isLoading,
    String? message,
    String? title,
    JMLoadingOverlayType type = JMLoadingOverlayType.fullscreen,
    bool dismissible = false,
    VoidCallback? onDismiss,
    Widget? customLoader,
    bool showProgressBar = false,
    double? progressValue,
    Color? overlayColor,
    Color? progressColor,
  }) {
    return JMLoadingOverlay(
      isLoading: isLoading,
      child: this,
      loadingMessage: message,
      loadingTitle: title,
      type: type,
      dismissible: dismissible,
      onDismiss: onDismiss,
      customLoader: customLoader,
      showProgressBar: showProgressBar,
      progressValue: progressValue,
      overlayColor: overlayColor,
      progressColor: progressColor,
    );
  }

  Widget withJMSkeletonLoader({
    required bool isLoading,
    Widget? loadingWidget,
  }) {
    return JMSkeletonLoader(
      child: this,
      isLoading: isLoading,
      loadingWidget: loadingWidget,
    );
  }
}
