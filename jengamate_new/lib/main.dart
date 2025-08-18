import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/supabase_service.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';

void main() {
  // Ensure binding init and runApp happen in the SAME zone to avoid zone mismatch on web
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    const bool kTestCrashOnStart = bool.fromEnvironment('TEST_CRASH_ON_START');

    try {
      debugPrint('🚀 Initializing Firebase...');
      // Temporary: skip Firebase init on Android while Google Services are disabled
      final bool isAndroidPlatform =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      if (isAndroidPlatform) {
        debugPrint(
            '⏭️ Skipping Firebase initialization on Android for this build');
        await SupabaseService.instance.initialize();
        runApp(const MyApp());
        return; // prevent executing Firebase init below
      }
      // Manually configure Firebase for web to avoid issues with environment variables in release builds.
      const firebaseOptionsWeb = FirebaseOptions(
        apiKey: "AIzaSyCZku_umeY0AXt_IyG6Y898RKHfpL2rw7E",
        appId: "1:546254001513:web:c9b63734564a66474899f8",
        messagingSenderId: "546254001513",
        projectId: "jengamate",
        authDomain: "jengamate.firebaseapp.com",
        storageBucket: "jengamate.firebasestorage.app",
        measurementId: "G-F1FP84T3E7",
      );

      await Firebase.initializeApp(
        options: kIsWeb
            ? firebaseOptionsWeb
            : DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Supabase with configured credentials
      await SupabaseService.instance.initialize();

      debugPrint('✅ Firebase initialized successfully');

      // Connect to local emulators in debug mode - DISABLED for production
      // if (kDebugMode) {
      //   try {
      //     debugPrint('?? Connecting to local Firebase emulators...');
      //     await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      //         FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8082);
      //     await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      //     debugPrint('?? Connected to local emulators');
      //   } catch (e) {
      //     debugPrint('?? Failed to connect to emulators: $e');
      //   }
      // }

      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
        try {
          await FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(!kDebugMode);

          // Forward Flutter framework errors
          FlutterError.onError = (FlutterErrorDetails details) {
            FlutterError.presentError(details);
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          };

          // Forward uncaught async and platform errors
          PlatformDispatcher.instance.onError =
              (Object error, StackTrace stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true; // handled
          };

          // Optional one-time test crash to verify Crashlytics (only when explicitly enabled)
          if (kTestCrashOnStart && !kDebugMode) {
            Future.delayed(const Duration(seconds: 2), () {
              FirebaseCrashlytics.instance.crash();
            });
          }
        } catch (e) {
          debugPrint('⚠️ Crashlytics setup skipped/failed: $e');
        }
      }

      runApp(const MyApp());
    } catch (e, stackTrace) {
      debugPrint('❌ Firebase initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Firebase Initialization Error',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: $e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ),
      ));
    }
  }, (error, stack) {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      // Best-effort reporting on non-web
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
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
