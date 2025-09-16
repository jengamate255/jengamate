import 'package:flutter/material.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/spacing.dart';

enum JMNotificationType { success, error, warning, info }
enum JMNotificationPosition { top, bottom }

class JMNotification extends StatefulWidget {
  final String message;
  final String? title;
  final JMNotificationType type;
  final Duration duration;
  final VoidCallback? onDismiss;
  final Widget? action;
  final bool showProgressBar;

  const JMNotification({
    super.key,
    required this.message,
    this.title,
    this.type = JMNotificationType.info,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
    this.action,
    this.showProgressBar = true,
  });

  @override
  State<JMNotification> createState() => _JMNotificationState();
}

class _JMNotificationState extends State<JMNotification> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_progressController);

    _slideController.forward();
    _progressController.forward().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case JMNotificationType.success:
        return JMColors.success.withValues(alpha: 0.95);
      case JMNotificationType.error:
        return JMColors.danger.withValues(alpha: 0.95);
      case JMNotificationType.warning:
        return JMColors.warning.withValues(alpha: 0.95);
      case JMNotificationType.info:
        return JMColors.info.withValues(alpha: 0.95);
    }
  }

  Color _getForegroundColor() {
    switch (widget.type) {
      case JMNotificationType.success:
        return Colors.white;
      case JMNotificationType.error:
        return Colors.white;
      case JMNotificationType.warning:
        return Colors.black;
      case JMNotificationType.info:
        return Colors.white;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case JMNotificationType.success:
        return Icons.check_circle;
      case JMNotificationType.error:
        return Icons.error;
      case JMNotificationType.warning:
        return Icons.warning;
      case JMNotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final foregroundColor = _getForegroundColor();

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _progressController.stop();
              widget.onDismiss?.call();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIcon(),
                        color: foregroundColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.title != null) ...[
                              Text(
                                widget.title!,
                                style: TextStyle(
                                  color: foregroundColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: foregroundColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.action != null) ...[
                        const SizedBox(width: 12),
                        widget.action!,
                      ],
                    ],
                  ),
                  if (widget.showProgressBar) ...[
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: foregroundColor.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            foregroundColor,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Notification Manager for showing notifications globally
class JMNotificationManager {
  static final JMNotificationManager _instance = JMNotificationManager._internal();
  factory JMNotificationManager() => _instance;
  JMNotificationManager._internal();

  OverlayEntry? _currentNotification;

  void show(
    BuildContext context, {
    required String message,
    String? title,
    JMNotificationType type = JMNotificationType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
    Widget? action,
    bool showProgressBar = true,
  }) {
    // Remove existing notification
    _currentNotification?.remove();
    _currentNotification = null;

    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: JMNotification(
          message: message,
          title: title,
          type: type,
          duration: duration,
          onDismiss: () {
            entry.remove();
            _currentNotification = null;
            onDismiss?.call();
          },
          action: action,
          showProgressBar: showProgressBar,
        ),
      ),
    );

    _currentNotification = entry;
    overlay.insert(entry);
  }

  void dismiss() {
    _currentNotification?.remove();
    _currentNotification = null;
  }
}

// Extension methods for easy usage
extension NotificationExtension on BuildContext {
  void showSuccess(String message, {String? title, Duration? duration}) {
    JMNotificationManager().show(
      this,
      message: message,
      title: title,
      type: JMNotificationType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void showError(String message, {String? title, Duration? duration}) {
    JMNotificationManager().show(
      this,
      message: message,
      title: title,
      type: JMNotificationType.error,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  void showWarning(String message, {String? title, Duration? duration}) {
    JMNotificationManager().show(
      this,
      message: message,
      title: title,
      type: JMNotificationType.warning,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  void showInfo(String message, {String? title, Duration? duration}) {
    JMNotificationManager().show(
      this,
      message: message,
      title: title,
      type: JMNotificationType.info,
      duration: duration ?? const Duration(seconds: 4),
    );
  }
}
