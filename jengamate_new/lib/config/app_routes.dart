
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
  static const String orders = '/orders';
  static const String orderDetails = '/orders/:orderId';
  static const String invoices = '/invoices';
  static const String invoiceDetails = '/invoices/:invoiceId';
  static const String createInvoice = '/invoices/create';
}

class AppRouteBuilders {
  static String otpVerificationPath(String verificationId) {
    return AppRoutes.otpVerification
        .replaceFirst(':verificationId', verificationId);
  }

  static String chatConversationPath(String chatId) {
    return AppRoutes.chatConversation.replaceFirst(':chatId', chatId);
  }

  static String rfqSubmissionPath(
      {required String productId, required String productName}) {
    return AppRoutes.rfqSubmission
        .replaceFirst(':productId', productId)
        .replaceFirst(':productName', Uri.encodeComponent(productName));
  }

  static String rfqDetailsPath(String rfqId) {
    return AppRoutes.rfqDetails.replaceFirst(':rfqId', rfqId);
  }

  static String orderDetailsPath(String orderId) {
    return AppRoutes.orderDetails.replaceFirst(':orderId', orderId);
  }

  static String invoiceDetailsPath(String invoiceId) {
    return AppRoutes.invoiceDetails.replaceFirst(':invoiceId', invoiceId);
  }
}
