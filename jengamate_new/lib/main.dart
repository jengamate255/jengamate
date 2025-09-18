import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/supabase_service.dart';
import 'package:jengamate/services/theme_service.dart';
import 'package:jengamate/services/notification_service.dart';
import 'package:jengamate/services/invoice_service.dart';
import 'package:jengamate/services/order_service.dart';
import 'package:jengamate/services/payment_approval_service.dart';
import 'package:jengamate/services/bulk_operations_service.dart';
import 'package:jengamate/services/audit_service.dart'; // Added
import 'package:jengamate/services/document_verification_service.dart'; // Added
import 'package:jengamate/services/role_service.dart'; // Added
import 'package:jengamate/services/app_config_service.dart'; // Add this import
import 'package:jengamate/services/user_state_provider.dart'; // Add this import
import 'package:jengamate/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';

Future<void> main() async {
  // Wrap the entire application in a guarded zone to catch all errors.
  runZonedGuarded<Future<void>>(
    () async {
      // Ensure Flutter bindings are initialized first.
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize services in correct order.
      try {
        // Initialize Firebase first so Supabase can exchange the Firebase ID token
        // for a Supabase session during requests.
        debugPrint('🔥 Initializing Firebase...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase initialized successfully');

        // Initialize Supabase after Firebase so the accessToken callback can
        // retrieve a valid Firebase ID token and exchange it for a Supabase token.
        debugPrint('🚀 Initializing Supabase...');
        await SupabaseService.instance.initialize();

        // Initialize payment approval service for automated workflow
        PaymentApprovalService();

        // Initialize bulk operations service
        BulkOperationsService();

        // Load dynamic app configurations
        final appConfigService = AppConfigService();
        final dynamicConfigs = await appConfigService.getAllConfigs();
        Logger.log('Dynamic App Configurations: $dynamicConfigs');

        // TODO: Integrate dynamicConfigs into a Provider or equivalent for app-wide access.

        debugPrint('✅ Supabase, Payment Approval, and Bulk Operations Services initialized successfully');

        // Set up global error handlers.
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          // Consider logging to a Supabase-based error tracking if needed
        };

        PlatformDispatcher.instance.onError =
            (Object error, StackTrace stack) {
          // Consider logging to a Supabase-based error tracking if needed
          return true; // Error handled.
        };

        // Run the app.
        runApp(const MyApp());
      } catch (e, stackTrace) {
        debugPrint('❌ Initialization failed: $e');
        debugPrint('Stack trace: $stackTrace');
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Initialization Error: $e'),
              ),
            ),
          ),
        );
      }
    },
    (error, stack) {
      // Errors caught by the zone are reported.
      debugPrint('Unhandled error in runZonedGuarded: $error');
      debugPrint('Stack trace: $stack');
      // Consider logging to a Supabase-based error tracking if needed
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>(
          create: (_) {
            final themeService = ThemeService();
            themeService.loadTheme(); // Load theme asynchronously
            return themeService;
          },
        ),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<NotificationService>(
          create: (_) {
            final notificationService = NotificationService();
            notificationService
                .loadNotificationSettings(); // Load settings asynchronously
            return notificationService;
          },
        ),
        Provider<InvoiceService>(
          create: (_) => InvoiceService(),
        ),
        // Removed Firebase-related StreamProviders for user authentication
        Provider<OrderService>(
          create: (_) => OrderService(),
        ),
        Provider<AuditService>(create: (_) => AuditService()),
        Provider<DocumentVerificationService>(create: (_) => DocumentVerificationService()), // Added
        Provider<RoleService>(create: (_) => RoleService()), // Added
        ChangeNotifierProvider<UserStateProvider>(create: (_) => UserStateProvider()), // Added
      ],
      child: Consumer<ThemeService>(
        builder: (context, theme, child) {
          return MaterialApp.router(
            title: 'JengaMate',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
