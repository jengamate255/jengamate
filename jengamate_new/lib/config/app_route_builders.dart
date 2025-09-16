import 'package:jengamate/config/app_route_builders.dart';
class AppRouteBuilders {
  static String chatConversationPath(String chatId) => '/chat/$chatId';
  
  static String otpVerificationPath(String verificationId) => '/otp-verification/$verificationId';
  
  static String rfqDetailsPath(String rfqId) => '/rfq/$rfqId';
  
  static String orderDetailsPath(String orderId) => '/order/$orderId';
  
  static String invoiceDetailsPath(String invoiceId) => '/invoice/$invoiceId';
  
  static String rfqSubmissionPath(String productId, String productName) => 
      '/rfq-submission/$productId/${Uri.encodeComponent(productName)}';
}
