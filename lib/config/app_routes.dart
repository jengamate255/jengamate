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
import 'package:jengamate/screens/withdrawals/withdrawals_screen.dart';
import 'package:jengamate/screens/help_screen.dart';
import 'package:jengamate/auth/phone_registration_screen.dart';
import 'package:jengamate/auth/otp_verification_screen.dart';
import 'package:jengamate/auth/approval_pending_screen.dart';
import 'package:jengamate/screens/inquiry/inquiry_screen.dart';
import 'package:jengamate/screens/rfq/rfq_list_screen.dart';
import 'package:jengamate/screens/rfq/rfq_management_screen.dart';
import 'package:jengamate/screens/rfq/rfq_details_screen.dart';
import 'package:jengamate/auth/engineer_registration_screen.dart'; // Import the new screen

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String adminTools = '/admin-tools';
  static const String chatList = '/chat-list';
  static const String notifications = '/notifications';
  static const String analytics = '/analytics';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String newInquiry = '/new-inquiry';
  static const String chatConversation = '/chat-conversation';
  static const String commission = '/commission';
  static const String withdrawals = '/withdrawals';
  static const String help = '/help';
  static const String phoneRegistration = '/phone-registration';
  static const String otpVerification = '/otp-verification';
  static const String approvalPending = '/approval-pending';
  static const String inquiries = '/inquiries';
  static const String rfqSubmission = '/rfq-submission';
  static const String rfqList = '/rfq-list';
  static const String rfqManagement = '/rfq-management';
  static const String rfqDetails = '/rfq-details';
  static const String engineerRegistration =
      '/engineer-registration'; // New route

  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (settings.name == login) {
      return MaterialPageRoute(builder: (_) => LoginScreen());
    } else if (settings.name == dashboard) {
      return MaterialPageRoute(builder: (_) => const DashboardScreen());
    } else if (settings.name == settings) {
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    } else if (settings.name == profile) {
      return MaterialPageRoute(builder: (_) => const ProfileScreen());
    } else if (settings.name == adminTools) {
      return MaterialPageRoute(builder: (_) => const AdminToolsScreen());
    } else if (settings.name == chatList) {
      return MaterialPageRoute(builder: (_) => const ChatListScreen());
    } else if (settings.name == notifications) {
      return MaterialPageRoute(builder: (_) => const NotificationsScreen());
    } else if (settings.name == analytics) {
      return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
    } else if (settings.name == products) {
      return MaterialPageRoute(builder: (_) => const ProductsScreen());
    } else if (settings.name == categories) {
      return MaterialPageRoute(builder: (_) => const CategoriesScreen());
    } else if (settings.name == newInquiry) {
      return MaterialPageRoute(builder: (_) => const NewInquiryScreen());
    } else if (settings.name == chatConversation) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args != null &&
          args.containsKey('chatRoomId') &&
          args.containsKey('otherUserName')) {
        return MaterialPageRoute(
          builder: (_) => ChatConversationScreen(
            chatRoomId: args['chatRoomId'] as String,
            otherUserName: args['otherUserName'] as String,
            otherUserId: args['otherUserId'] as String,
          ),
        );
      } else {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
                child: Text('Invalid chat conversation parameters')),
          ),
        );
      }
    } else if (settings.name == commission) {
      return MaterialPageRoute(builder: (_) => const CommissionScreen());
    } else if (settings.name == withdrawals) {
      return MaterialPageRoute(builder: (_) => const WithdrawalsScreen());
    } else if (settings.name == help) {
      return MaterialPageRoute(builder: (_) => const HelpScreen());
    } else if (settings.name == phoneRegistration) {
      return MaterialPageRoute(builder: (_) => const PhoneRegistrationScreen());
    } else if (settings.name == otpVerification) {
      return MaterialPageRoute(builder: (_) => const OtpVerificationScreen());
    } else if (settings.name == approvalPending) {
      return MaterialPageRoute(builder: (_) => const ApprovalPendingScreen());
    } else if (settings.name == inquiries) {
      return MaterialPageRoute(builder: (_) => const InquiryScreen());
    } else if (settings.name == rfqList) {
      return MaterialPageRoute(builder: (_) => const RFQListScreen());
    } else if (settings.name == rfqManagement) {
      return MaterialPageRoute(builder: (_) => const RFQManagementScreen());
    } else if (settings.name == rfqDetails) {
      final args = settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('rfq')) {
        return MaterialPageRoute(
          builder: (_) => RFQDetailsScreen(rfq: args['rfq'] as RFQModel),
        );
      } else {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Invalid RFQ details parameters')),
          ),
        );
      }
    }
    // else if (settings.name == rfqSubmission) {
    //   return MaterialPageRoute(builder: (_) => const RFQSubmissionScreen());
    // }
    else if (settings.name == engineerRegistration) {
      // New route case
      return MaterialPageRoute(
          builder: (_) => const EngineerRegistrationScreen());
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
          ),
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
    }
  }
}
