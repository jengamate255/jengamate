import 'package:jengamate/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'dart:convert';
import 'package:http/http.dart' as http;

class SupabaseService {
  SupabaseService._(); // Private constructor

  static final SupabaseService instance = SupabaseService._();
  SupabaseClient? _client;
  String? _cachedSupabaseAccessToken;
  DateTime? _cachedSupabaseAccessTokenExpiry;

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

      // Initialize Supabase. We will provide an accessToken callback that exchanges
      // the Firebase ID token for a Supabase access token via an Edge Function.
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        accessToken: () async {
          try {
            return await _getSupabaseAccessTokenFromFirebase();
          } catch (e) {
            Logger.logError('Failed to get Supabase access token from Firebase', e, StackTrace.current);
            return null;
          }
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

            // Proactively warm the Supabase access token cache after login
            await _getSupabaseAccessTokenFromFirebase(forceRefresh: true);
            Logger.log('Firebase user detected — Supabase access token cached for requests');
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

  // Exchanges Firebase ID token for a Supabase access token using the Edge Function
  // and caches it briefly to avoid excessive function calls.
  Future<String?> _getSupabaseAccessTokenFromFirebase({bool forceRefresh = false}) async {
    try {
      final fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Return cached token if valid
      if (!forceRefresh && _cachedSupabaseAccessToken != null && _cachedSupabaseAccessTokenExpiry != null) {
        if (DateTime.now().isBefore(_cachedSupabaseAccessTokenExpiry!)) {
          return _cachedSupabaseAccessToken;
        }
      }

      final idToken = await user.getIdToken();
      final uri = Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/exchange-firebase-token');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'firebaseIdToken': idToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String? accessToken = data['supabaseAccessToken'] as String?;
        final String? refreshToken = data['supabaseRefreshToken'] as String?;

        if (accessToken != null && accessToken.isNotEmpty) {
          // Optionally set session on client if refresh token present
          try {
            if (refreshToken != null && refreshToken.isNotEmpty) {
              await _client?.auth.setSession(
                refreshToken: refreshToken,
                accessToken: accessToken,
              );
            }
          } catch (e) {
            // setSession API differences across versions; ignore failures here since accessToken header still works
            Logger.log('Supabase setSession not available or failed; continuing with header token');
          }

          // Cache access token for 4 minutes
          _cachedSupabaseAccessToken = accessToken;
          _cachedSupabaseAccessTokenExpiry = DateTime.now().add(const Duration(minutes: 4));
          return accessToken;
        }
      } else {
        Logger.logError('Exchange function error: ${response.statusCode} ${response.body}', Exception('Token exchange failed'), StackTrace.current);
      }
    } catch (e) {
      Logger.logError('Error exchanging Firebase token for Supabase token', e, StackTrace.current);
    }
    return null;
  }
}