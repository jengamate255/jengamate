import 'package:flutter/material.dart';

/// A reusable confirmation dialog with customizable actions and appearance
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final Color? cancelColor;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onCancel,
    this.confirmColor,
    this.cancelColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            if (onCancel != null) {
              onCancel!();
            } else {
              Navigator.of(context).pop();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: cancelColor ?? Theme.of(context).colorScheme.onSurface,
          ),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? (isDestructive
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary),
            foregroundColor: isDestructive
              ? Theme.of(context).colorScheme.onError
              : Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// Utility function to show confirmation dialog
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color? confirmColor,
  Color? cancelColor,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
      confirmColor: confirmColor,
      cancelColor: cancelColor,
      isDestructive: isDestructive,
    ),
  );
}
