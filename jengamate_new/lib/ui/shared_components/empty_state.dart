import 'package:flutter/material.dart';

/// A reusable empty state widget for when there's no data to display
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final EdgeInsetsGeometry? padding;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionText,
    this.onActionPressed,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Common empty state configurations
class EmptyStates {
  static EmptyState noItems({
    required String itemType,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'No $itemType Found',
      subtitle: 'There are no $itemType to display at the moment.',
      actionText: actionText,
      onActionPressed: onActionPressed,
    );
  }

  static EmptyState noSearchResults({
    required String searchTerm,
    VoidCallback? onClearSearch,
  }) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      subtitle: 'No items match your search for "$searchTerm".',
      actionText: 'Clear Search',
      onActionPressed: onClearSearch,
    );
  }

  static EmptyState noInternet({
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'No Internet Connection',
      subtitle: 'Please check your internet connection and try again.',
      actionText: 'Retry',
      onActionPressed: onRetry,
    );
  }

  static EmptyState error({
    required String message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something Went Wrong',
      subtitle: message,
      actionText: onRetry != null ? 'Retry' : null,
      onActionPressed: onRetry,
    );
  }
}
