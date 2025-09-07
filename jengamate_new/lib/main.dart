import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/supabase_service.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/theme_service.dart';
import 'package:jengamate/services/notification_service.dart';
import 'package:jengamate/services/invoice_service.dart';
import 'package:jengamate/services/order_service.dart';
import 'package:provider/provider.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Wrap the entire application in a guarded zone to catch all errors.
  runZonedGuarded<Future<void>>(
    () async {
      // Ensure Flutter bindings are initialized first.
      WidgetsFlutterBinding.ensureInitialized();

      // Sentry removed.

      // Initialize Firebase and Supabase.
      try {
        debugPrint('🚀 Initializing Firebase...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await SupabaseService.instance.initialize();
        debugPrint('✅ Firebase and Supabase initialized successfully');

        // Set up crash reporting and global error handlers.
        if (kIsWeb) {
          FlutterError.onError = (FlutterErrorDetails details) {
            // Sentry removed; keep default behavior if needed.
          };
        } else {
          // For mobile, use more comprehensive error handling.
          await FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(kReleaseMode);

          FlutterError.onError = (FlutterErrorDetails details) {
            FlutterError.presentError(details);
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          };

          PlatformDispatcher.instance.onError =
              (Object error, StackTrace stack) {
            if (kReleaseMode) {
              FirebaseCrashlytics.instance
                  .recordError(error, stack, fatal: true);
            }
            return true; // Error handled.
          };
        }

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
      // Errors caught by the zone are reported to Crashlytics (Sentry removed).
      if (!kIsWeb && kReleaseMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
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
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        StreamProvider<UserModel?>(
          create: (context) {
            final userStream = context.read<AuthService>().authStateChanges;
            return userStream.asyncMap((user) async {
              if (user == null) {
                return null;
              }
              final enhancedUser = await DatabaseService().getUser(user.uid);
              return enhancedUser;
            });
          },
          initialData: null,
        ),
        Provider<OrderService>(
          create: (_) => OrderService(),
        ),
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
