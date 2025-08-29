import 'package:flutter/material.dart';
import 'package:jengamate/auth/login_screen.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/screens/dashboard_screen.dart';
import 'package:jengamate/screens/settings_screen.dart';
import 'package:jengamate/screens/profile/profile_screen.dart';
import 'package:jengamate/screens/admin/admin_tools_screen.dart';
import 'package:jengamate/screens/chat/chat_list_screen.dart';
import 'package:jengamate/screens/notifications/notifications_screen.dart';
import 'package:jengamate/screens/analytics/analytics_screen.dart';
import 'package:jengamate/screens/products/products_screen.dart';
import 'package:jengamate/screens/categories/categories_screen.dart';
import 'package:jengamate/screens/inquiry/new_inquiry_screen.dart';
import 'package:jengamate/screens/chat/chat_conversation_screen.dart';
import 'package:jengamate/screens/commission/commission_screen.dart';
import 'package:jengamate/screens/admin/commission_tiers_screen.dart';
import 'package:jengamate/screens/withdrawals/withdrawals_screen.dart';
import 'package:jengamate/screens/help_screen.dart';
import 'package:jengamate/auth/password_reset_screen.dart';
import 'package:jengamate/screens/profile/change_password_screen.dart';
import 'package:jengamate/screens/profile/security_screen.dart';
import 'package:jengamate/screens/profile/identity_verification_screen.dart';
import 'package:jengamate/screens/profile/priority_support_screen.dart';
import 'package:jengamate/auth/phone_registration_screen.dart';
import 'package:jengamate/auth/otp_verification_screen.dart';
import 'package:jengamate/auth/approval_pending_screen.dart';
import 'package:jengamate/screens/inquiry/inquiry_screen.dart';
import 'package:jengamate/screens/rfq/rfq_submission_screen.dart';
import 'package:jengamate/screens/rfq/rfq_list_screen.dart';
import 'package:jengamate/screens/admin/rfq_management_screen.dart';
import 'package:jengamate/screens/admin/rfq_management_screen.dart' as admin;
import 'package:jengamate/screens/test/image_upload_test_screen.dart';
import 'package:jengamate/screens/rfq/rfq_details_screen.dart' as rfq_details;
import 'package:jengamate/auth/engineer_registration_screen.dart';
import 'package:jengamate/screens/admin/add_edit_product_screen.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/screens/invoices/invoices_screen.dart';
import 'package:jengamate/screens/invoices/invoice_details_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String adminTools = '/admin-tools';

  static const String userDetails = 'user-details';
  static const String auditLog = 'audit-log';
  static const String chatList = '/chat-list';
  static const String notifications = '/notifications';
  static const String analytics = '/analytics';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String newInquiry = '/new-inquiry';
  static const String passwordReset = '/password-reset';
  static const String changePassword = '/change-password';
  static const String security = '/security';
  static const String help = '/help';
  static const String identityVerification = '/identity-verification';
  static const String prioritySupport = '/priority-support';
  static const String commission = '/commission';
  static const String commissionTiers = '/commission-tiers';
  static const String withdrawals = '/withdrawals';
  static const String phoneRegistration = '/phone-registration';
  static const String otpVerification = '/otp-verification/:verificationId';
  static const String approvalPending = '/approval-pending';
  static const String inquiries = '/inquiries';
  static const String rfqSubmission = '/rfq-submission/:productId/:productName';
  static const String inquirySubmission = '/inquiry-submission';
  static const String rfqList = '/rfq-list';
  static const String rfqManagement = '/rfq-management';
  static const String rfqDetails = '/rfqs/:rfqId';
  static const String engineerRegistration = '/engineer-registration';
  static const String imageUploadTest = '/image-upload-test';
  static const String addEditProduct = '/add-edit-product';
  static const String chatConversation = '/chat-conversation/:chatId';
  static const String invoices = '/invoices';
  static const String invoiceDetails = '/invoices/:invoiceId';
  static const String createInvoice = '/invoices/create';


}

class AppRouteBuilders {
  static String otpVerificationPath(String verificationId) {
    return AppRoutes.otpVerification.replaceFirst(':verificationId', verificationId);
  }

  static String chatConversationPath(String chatId) {
    return AppRoutes.chatConversation.replaceFirst(':chatId', chatId);
  }

  static String rfqSubmissionPath({required String productId, required String productName}) {
    return AppRoutes.rfqSubmission
        .replaceFirst(':productId', productId)
        .replaceFirst(':productName', Uri.encodeComponent(productName));
  }

  static String rfqDetailsPath(String rfqId) {
    return AppRoutes.rfqDetails.replaceFirst(':rfqId', rfqId);
  }

  static String invoiceDetailsPath(String invoiceId) {
    return AppRoutes.invoiceDetails.replaceFirst(':invoiceId', invoiceId);
  }
}
