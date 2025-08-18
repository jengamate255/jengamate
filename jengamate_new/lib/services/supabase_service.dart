import 'package:jengamate/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/utils/logger.dart';

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
        final msg =
            'Missing Supabase configuration. Ensure you pass --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=... when running the app.';
        Logger.logError(msg, Exception('Invalid Supabase env'), StackTrace.current);
        throw Exception(msg);
      }
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      Logger.log('Supabase client initialized successfully.');
    } catch (e) {
      Logger.logError('Error initializing Supabase: $e', e, StackTrace.current);
      // Optionally re-throw or handle the error as needed
      rethrow;
    }
  }
}
