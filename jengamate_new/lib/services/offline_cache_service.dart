import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineCacheService {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    Logger.log('OfflineCacheService initialized.');
  }

  Future<void> saveData(String key, Map<String, dynamic> data) async {
    try {
      if (_prefs == null) await initialize();
      final processedData = _convertTimestampsToStrings(data);
      final String jsonString = json.encode(processedData);
      await _prefs!.setString(key, jsonString);
      Logger.log('Data saved to cache: $key');
    } catch (e, s) {
      Logger.logError('Error saving data to cache for key: $key', e, s);
    }
  }

  Map<String, dynamic>? getData(String key) {
    try {
      if (_prefs == null) {
        Logger.log('OfflineCacheService not initialized when trying to get data for key: $key');
        return null;
      }
      final String? jsonString = _prefs!.getString(key);
      if (jsonString != null) {
        Logger.log('Data retrieved from cache: $key');
        return json.decode(jsonString) as Map<String, dynamic>;
      }
    } catch (e, s) {
      Logger.logError('Error getting data from cache for key: $key', e, s);
    }
    return null;
  }

  Future<void> saveListData(String key, List<Map<String, dynamic>> data) async {
    try {
      if (_prefs == null) await initialize();
      final List<String> jsonList = data.map((item) {
        final processedItem = _convertTimestampsToStrings(item);
        return json.encode(processedItem);
      }).toList();
      await _prefs!.setStringList(key, jsonList);
      Logger.log('List data saved to cache: $key');
    } catch (e, s) {
      Logger.logError('Error saving list data to cache for key: $key', e, s);
    }
  }

  List<Map<String, dynamic>>? getListData(String key) {
    try {
      if (_prefs == null) {
        Logger.log('OfflineCacheService not initialized when trying to get list data for key: $key');
        return null;
      }
      final List<String>? jsonList = _prefs!.getStringList(key);
      if (jsonList != null) {
        Logger.log('List data retrieved from cache: $key');
        return jsonList.map((jsonString) => json.decode(jsonString) as Map<String, dynamic>).toList();
      }
    } catch (e, s) {
      Logger.logError('Error getting list data from cache for key: $key', e, s);
    }
    return null;
  }

  Future<void> removeData(String key) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs!.remove(key);
      Logger.log('Data removed from cache: $key');
    } catch (e, s) {
      Logger.logError('Error removing data from cache for key: $key', e, s);
    }
  }

  Future<void> clearAllCache() async {
    try {
      if (_prefs == null) await initialize();
      await _prefs!.clear();
      Logger.log('All cache cleared.');
    } catch (e, s) {
      Logger.logError('Error clearing all cache', e, s);
    }
  }

  // Helper function to convert Timestamp objects to ISO 8601 strings
  dynamic _convertTimestampsToStrings(dynamic item) {
    if (item is Timestamp) {
      return item.toDate().toIso8601String();
    } else if (item is Map) {
      return item.map((key, value) => MapEntry(key, _convertTimestampsToStrings(value)));
    } else if (item is List) {
      return item.map((value) => _convertTimestampsToStrings(value)).toList();
    }
    return item;
  }

  // Check network connectivity
  // Note: This is a placeholder. Real-world apps should use connectivity_plus package.
  Future<bool> isOnline() async {
    // For demonstration, always assume online. Implement actual check with connectivity_plus.
    return true;
  }
}

