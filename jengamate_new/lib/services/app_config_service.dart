import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/utils/logger.dart';

class AppConfigService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _appConfigTable = 'app_config';

  /// Fetches a single configuration value by its key.
  Future<Map<String, dynamic>?> getConfigValue(String key) async {
    try {
      final response = await _supabase
          .from(_appConfigTable)
          .select('value')
          .eq('key', key)
          .single();

      if (response.isNotEmpty) {
        return response['value'] as Map<String, dynamic>;
      }
      return null;
    } catch (e, st) {
      Logger.logError('Error fetching app config for key: $key', e, st);
      return null;
    }
  }

  /// Fetches all application configurations.
  Future<Map<String, dynamic>> getAllConfigs() async {
    try {
      final response = await _supabase.from(_appConfigTable).select();
      final Map<String, dynamic> configs = {};
      for (final item in response) {
        configs[item['key']] = item['value'];
      }
      return configs;
    } catch (e, st) {
      Logger.logError('Error fetching all app configs', e, st);
      return {};
    }
  }

  /// Updates a configuration value.
  Future<void> updateConfigValue(String key, Map<String, dynamic> value) async {
    try {
      await _supabase.from(_appConfigTable).upsert({
        'key': key,
        'value': value,
      });
      Logger.log('App config for key "$key" updated successfully.');
    } catch (e, st) {
      Logger.logError('Error updating app config for key: $key', e, st);
      rethrow;
    }
  }

  /// Provides a stream of configuration changes for a specific key.
  Stream<Map<String, dynamic>?> streamConfigValue(String key) {
    return _supabase
        .from(_appConfigTable)
        .stream(primaryKey: ['key'])
        .eq('key', key)
        .limit(1)
        .map((data) {
          if (data.isNotEmpty) {
            return data.first['value'] as Map<String, dynamic>;
          }
          return null;
        });
  }
}
