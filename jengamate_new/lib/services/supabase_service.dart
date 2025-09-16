import 'package:jengamate/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class SupabaseService {
  SupabaseService._(); // Private constructor

  static final SupabaseService instance = SupabaseService._();
  SupabaseClient? _client;

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client has not been initialized. Call initialize() first.');
    }
    return _client!;
  }

  Future<void> initialize() async {
    try {
      if (SupabaseConfig.supabaseUrl.isEmpty || SupabaseConfig.supabaseAnonKey.isEmpty) {
        const msg =
            'Missing Supabase configuration. Ensure you pass --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=... when running the app.';
        Logger.logError(msg, Exception('Invalid Supabase env'), StackTrace.current);
        throw Exception(msg);
      }
      Logger.log('SupabaseService.initialize: Initializing with URL: ${SupabaseConfig.supabaseUrl}');
      Logger.log('SupabaseService.initialize: Initializing with Anon Key: ${SupabaseConfig.supabaseAnonKey}');

      // Initialize Supabase with Firebase Auth integration
      // This uses the official third-party auth approach
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        accessToken: () async {
          try {
            // Return Firebase ID token for Supabase to use
            // Only access Firebase if it has been initialized
            final fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
            if (user != null) {
              final idToken = await user.getIdToken();
              return idToken;
            }
          } catch (e) {
            // Firebase not initialized yet, return null
            Logger.log('Firebase not initialized yet, skipping token retrieval');
          }
          return null;
        },
      );

      _client = Supabase.instance.client;

      // Listen for Firebase auth changes and keep Supabase state in sync where possible
      // Only set up listener if Firebase is available
      try {
        fb_auth.FirebaseAuth.instance.authStateChanges().listen((fb_auth.User? user) async {
          try {
            if (user == null) {
              Logger.log('Firebase user signed out — clearing Supabase auth');
              await _client?.auth.signOut();
              return;
            }

            await user.getIdToken();
            Logger.log('Firebase user detected — Supabase will use Firebase ID token for requests');
            // Supabase SDK will call the accessToken callback per request; no extra action required here.
          } catch (e) {
            Logger.logError('Error handling Firebase auth state change for Supabase: $e', e, StackTrace.current);
          }
        });
      } catch (e) {
        Logger.log('Firebase not available for auth state listening, skipping listener setup');
      }

      Logger.log('Supabase client initialized successfully with Firebase Auth integration.');
    } catch (e) {
      Logger.logError('Error initializing Supabase: $e', e, StackTrace.current);
      // Don't rethrow - allow the app to continue without Supabase
      Logger.log('Continuing without Supabase integration');
    }
  }
}