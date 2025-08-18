import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/models/notification_model.dart';

class NotificationNavigation {
  static void navigateToRelatedScreen({
    required BuildContext context,
    required NotificationModel notification,
  }) {
    switch (notification.type) {
      case 'order':
        // Navigate to dashboard for orders
        context.go(AppRoutes.dashboard);
        break;

      case 'rfq':
        // Navigate to RFQ list instead of submission (submission requires params)
        context.go(AppRoutes.rfqList);
        break;

      case 'inquiry':
        if (notification.relatedId != null) {
          // Navigate to inquiry details
          context.go(AppRoutes.inquiries,
              extra: {'inquiryId': notification.relatedId});
        } else {
          context.go(AppRoutes.inquiries);
        }
        break;

      case 'withdrawal':
        // Navigate to dashboard for withdrawals
        context.go(AppRoutes.dashboard);
        break;

      case 'approval':
        context.go(AppRoutes.settings);
        break;

      case 'system':
      default:
        // For system notifications, go to dashboard
        context.go(AppRoutes.dashboard);
        break;
    }
  }
}
