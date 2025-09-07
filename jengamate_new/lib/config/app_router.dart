import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/auth/login_screen.dart';
import 'package:jengamate/screens/dashboard_screen.dart';
import 'package:jengamate/screens/admin/financial_oversight_screen.dart';
import 'package:jengamate/auth/engineer_registration_screen.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/screens/admin/admin_tools_screen.dart';
import 'package:jengamate/screens/rfq/rfq_submission_screen.dart';
import 'package:jengamate/screens/inquiry/inquiry_submission_screen.dart';
import 'package:jengamate/screens/products/products_screen.dart';
import 'package:jengamate/screens/profile/profile_screen.dart';
import 'package:jengamate/screens/settings_screen.dart';
import 'package:jengamate/screens/help_screen.dart';
import 'package:jengamate/screens/profile/change_password_screen.dart';
import 'package:jengamate/screens/profile/security_screen.dart';
import 'package:jengamate/screens/profile/identity_verification_screen.dart';
import 'package:jengamate/screens/profile/priority_support_screen.dart';
import 'package:jengamate/screens/chat/chat_list_screen.dart';
import 'package:jengamate/screens/notifications/notifications_screen.dart';
import 'package:jengamate/screens/analytics/analytics_screen.dart';
import 'package:jengamate/screens/categories/categories_screen.dart';
import 'package:jengamate/screens/inquiry/new_inquiry_screen.dart';
import 'package:jengamate/auth/password_reset_screen.dart';
import 'package:jengamate/auth/phone_registration_screen.dart';
import 'package:jengamate/auth/otp_verification_screen.dart';
import 'package:jengamate/auth/approval_pending_screen.dart';
import 'package:jengamate/screens/inquiry/inquiry_list_screen.dart';
import 'package:jengamate/screens/rfq/rfq_list_screen.dart';
import 'package:jengamate/screens/rfq/rfq_management_screen.dart';
import 'package:jengamate/screens/rfq/rfq_details_screen.dart';
import 'package:jengamate/screens/chat/chat_conversation_screen.dart';
import 'package:jengamate/screens/commission/commission_screen.dart';
import 'package:jengamate/screens/withdrawals/withdrawals_screen.dart';
import 'package:jengamate/screens/test/image_upload_test_screen.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/screens/admin/add_edit_product_screen.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/screens/admin/user_management_screen.dart';
import 'package:jengamate/screens/admin/withdrawal_management_screen.dart';
import 'package:jengamate/screens/admin/referral_management_screen.dart';
import 'package:jengamate/screens/admin/user_details_screen.dart';
import 'package:jengamate/screens/admin/audit_log_screen.dart';
import 'package:jengamate/models/enhanced_user.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/screens/admin/product_management_screen.dart';
import 'package:jengamate/screens/admin/category_management_screen.dart';
import 'package:jengamate/screens/admin/analytics_screen.dart'
    as admin_analytics;
import 'package:jengamate/screens/admin/commission_list_screen.dart';
import 'package:jengamate/screens/finance/financial_dashboard_screen.dart';
import 'package:jengamate/screens/referral/referral_dashboard_screen.dart';
import 'package:jengamate/screens/admin/system_settings_screen.dart';
import 'package:jengamate/screens/analytics/advanced_analytics_screen.dart';
import 'package:jengamate/screens/admin/enhanced_audit_log_screen.dart';
import 'package:jengamate/screens/admin/commission_tier_management_screen.dart';
import 'package:jengamate/screens/admin/content_moderation_dashboard.dart';
import 'package:jengamate/screens/support/support_dashboard_screen.dart';
import 'package:jengamate/screens/admin/send_commission_screen.dart';
import 'package:jengamate/screens/admin/commission_tiers_screen.dart';
import 'package:jengamate/screens/admin/rfq_management_dashboard.dart';
import 'package:jengamate/screens/admin/rfq_analytics_dashboard.dart';
import 'package:jengamate/screens/supplier/supplier_rfq_dashboard.dart';
import 'package:jengamate/screens/admin/rfq_management_test.dart';
import 'package:jengamate/screens/invoices/invoices_screen.dart';
import 'package:jengamate/screens/invoices/invoice_details_screen.dart';
import 'package:jengamate/screens/invoices/create_invoice_screen.dart';
import 'package:jengamate/screens/order/orders_management_screen.dart';
import 'package:jengamate/screens/order/order_details_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final returnTo = state.uri.queryParameters['returnTo'];
          return LoginScreen(returnRoute: returnTo);
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.engineerRegistration,
        builder: (context, state) => const EngineerRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.rfqSubmission,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          final productName = Uri.decodeComponent(state.pathParameters['productName']!);
          return RFQSubmissionScreen(
            productId: productId,
            productName: productName,
          );
        },
        redirect: (context, state) {
          final currentUser = Provider.of<UserModel?>(context, listen: false);
          if (currentUser == null) {
            // Redirect to login with return URL
            return '${AppRoutes.login}?returnTo=${Uri.encodeComponent(state.uri.toString())}';
          }
          return null;
        },
      ),
      GoRoute(
        path: AppRoutes.inquirySubmission,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return const InquirySubmissionScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.adminTools,
        name: 'adminTools',
        builder: (context, state) => const AdminToolsScreen(),
        redirect: (context, state) {
          final currentUser = Provider.of<UserModel?>(context, listen: false);
          if (currentUser == null || currentUser.role != UserRole.admin) {
            return AppRoutes.dashboard;
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'financial-oversight',
            name: 'adminFinancialOversight',
            builder: (context, state) => const FinancialOversightScreen(),
          ),
          GoRoute(
            path: 'user-management',
            name: 'adminUserManagement',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: 'withdrawal-management',
            name: 'adminWithdrawalManagement',
            builder: (context, state) => const WithdrawalManagementScreen(),
          ),
          GoRoute(
            path: 'referral-management',
            name: 'adminReferralManagement',
            builder: (context, state) => const ReferralManagementScreen(),
          ),
          GoRoute(
            path: AppRoutes.userDetails,
            name: 'adminUserDetails',
            builder: (context, state) {
              final user = state.extra as EnhancedUser;
              return UserDetailsScreen(user: user);
            },
          ),
          GoRoute(
            path: AppRoutes.auditLog,
            name: 'adminAuditLog',
            builder: (context, state) {
              final args = state.extra as Map<String, String>;
              return AuditLogScreen(
                  userId: args['userId']!, userName: args['userName']!);
            },
          ),
          GoRoute(
            path: 'product-management',
            name: 'adminProductManagement',
            builder: (context, state) => const ProductManagementScreen(),
          ),
          GoRoute(
            path: 'category-management',
            name: 'adminCategoryManagement',
            builder: (context, state) => const CategoryManagementScreen(),
          ),
          GoRoute(
            path: 'analytics-reporting',
            name: 'adminAnalyticsReporting',
            builder: (context, state) =>
                const admin_analytics.AnalyticsScreen(),
          ),
          GoRoute(
            path: 'commission-tools',
            name: 'adminCommissionTools',
            builder: (context, state) => const CommissionListScreen(),
            routes: [
              GoRoute(
                path: 'send-commission',
                name: 'adminSendCommission',
                builder: (context, state) => const SendCommissionScreen(),
              ),
              GoRoute(
                path: 'commission-tiers',
                name: 'adminCommissionTiers',
                builder: (context, state) => const CommissionTiersScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.addEditProduct,
        builder: (context, state) {
          final product = state.extra as ProductModel?;
          return AddEditProductScreen(product: product);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.security,
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: AppRoutes.identityVerification,
        builder: (context, state) => const IdentityVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.prioritySupport,
        builder: (context, state) => const PrioritySupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatList,
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.newInquiry,
        builder: (context, state) => const NewInquiryScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordReset,
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneRegistration,
        builder: (context, state) => const PhoneRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (context, state) {
          final verificationId = state.pathParameters['verificationId']!;
          final extra = state.extra as Map<String, String?>;
          final phoneNumber = extra['phoneNumber'] ?? '';
          final name = extra['name'] ?? '';
          final company = extra['company'] ?? '';
          final roleString = extra['role'] ?? 'engineer';

          return OtpVerificationScreen(
            verificationId: verificationId,
            phoneNumber: phoneNumber,
            name: name,
            company: company,
            role: UserRole.values.firstWhere(
              (e) => e.toString() == 'UserRole.$roleString',
              orElse: () => UserRole.engineer, // Default value
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.approvalPending,
        builder: (context, state) => const ApprovalPendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.inquiries,
        builder: (context, state) => const InquiryListScreen(),
      ),
      GoRoute(
        path: AppRoutes.rfqList,
        builder: (context, state) => const RFQListScreen(),
      ),
      GoRoute(
        path: AppRoutes.rfqManagement,
        builder: (context, state) => const RFQManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.rfqDetails,
        builder: (context, state) {
          final rfqId = state.pathParameters['rfqId']!;
          return RfqDetailsScreen(rfqId: rfqId);
        },
      ),
      GoRoute(
        path: AppRoutes.chatConversation,
        builder: (context, state) {
          final chatRoomId = state.pathParameters['chatId'];
          if (chatRoomId == null) {
            // Handle missing chatId parameter
            return const Scaffold(
              body: Center(
                child: Text('Invalid chat room ID'),
              ),
            );
          }

          final extra = state.extra as Map<String, String?>?;
          final otherUserName = extra?['otherUserName'] ?? 'Chat';
          final otherUserId = extra?['otherUserId'] ?? '';
          final currentUserId = extra?['currentUserId'] ?? '';

          return ChatConversationScreen(
            chatRoomId: chatRoomId,
            otherUserName: otherUserName,
            otherUserId: otherUserId,
            currentUserId: currentUserId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.commission,
        builder: (context, state) => const CommissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.commissionTiers,
        builder: (context, state) => const CommissionTiersScreen(),
      ),
      GoRoute(
        path: AppRoutes.withdrawals,
        builder: (context, state) => const WithdrawalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.imageUploadTest,
        builder: (context, state) => const ImageUploadTestScreen(),
      ),
      GoRoute(
        path: '/financial-dashboard',
        builder: (context, state) => const FinancialDashboardScreen(),
      ),
      GoRoute(
        path: '/referral-dashboard',
        builder: (context, state) => const ReferralDashboardScreen(),
      ),
      GoRoute(
        path: '/system-settings',
        builder: (context, state) => const SystemSettingsScreen(),
      ),
      GoRoute(
        path: '/advanced-analytics',
        builder: (context, state) => const AdvancedAnalyticsScreen(),
      ),
      GoRoute(
        path: '/enhanced-audit-logs',
        builder: (context, state) => const EnhancedAuditLogScreen(),
      ),
      GoRoute(
        path: '/commission-tier-management',
        builder: (context, state) => const CommissionTierManagementScreen(),
      ),
      GoRoute(
        path: '/content-moderation',
        builder: (context, state) => const ContentModerationDashboard(),
      ),
      GoRoute(
        path: '/support-dashboard',
        builder: (context, state) => const SupportDashboardScreen(),
      ),
      GoRoute(
        path: '/rfq-management-dashboard',
        builder: (context, state) => const RfqManagementDashboard(),
      ),
      GoRoute(
        path: '/rfq-analytics-dashboard',
        builder: (context, state) => const RFQAnalyticsDashboard(),
      ),
      GoRoute(
        path: '/supplier-rfq-dashboard',
        builder: (context, state) => const SupplierRFQDashboard(),
      ),
      GoRoute(
        path: '/rfq-test',
        builder: (context, state) => const RfqManagementTest(),
      ),
      GoRoute(
        path: '/admin-support',
        builder: (context, state) =>
            const SupportDashboardScreen(isAdminView: true),
      ),
      // Invoice Routes
      GoRoute(
        path: AppRoutes.invoices,
        builder: (context, state) => const InvoicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.createInvoice,
        builder: (context, state) => const CreateInvoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.invoiceDetails,
        builder: (context, state) {
          final invoiceId = state.pathParameters['invoiceId']!;
          return InvoiceDetailsScreen(invoiceId: invoiceId);
        },
      ),
      // Order Routes
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderDetails,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailsScreen(orderId: orderId);
        },
      ),
    ],
  );
}
