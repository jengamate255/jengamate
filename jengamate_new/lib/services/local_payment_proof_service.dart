import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local payment proof service as fallback when Supabase storage fails
class LocalPaymentProofService {
  static const String _storageKey = 'payment_proofs';
  static const int _maxLocalStorageSize = 50 * 1024 * 1024; // 50MB limit
  
  /// Store payment proof locally as base64 encoded data
  static Future<String?> storePaymentProof({
    required String orderId,
    required String userId,
    required Uint8List proofBytes,
    String? fileName,
  }) async {
    try {
      // Check file size limit
      if (proofBytes.length > 5 * 1024 * 1024) { // 5MB limit for local storage
        Logger.log('Payment proof too large for local storage: ${proofBytes.length} bytes');
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      
      // Create a unique key for this proof
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final key = '${userId}_${orderId}_$timestamp';
      final storageKey = '${_storageKey}_$key';
      
      // Encode the bytes as base64
      final base64Data = base64Encode(proofBytes);
      
      // Store metadata
      final metadata = {
        'orderId': orderId,
        'userId': userId,
        'fileName': fileName ?? 'payment_proof.jpg',
        'timestamp': timestamp,
        'size': proofBytes.length,
        'data': base64Data,
      };
      
      // Store in shared preferences
      final success = await prefs.setString(storageKey, jsonEncode(metadata));
      
      if (success) {
        final localReference = 'local://$key';
        Logger.log('Payment proof stored locally: $localReference (${proofBytes.length} bytes)');
        
        // Clean up old local storage entries to prevent storage bloat
        await _cleanupOldEntries();
        
        return localReference;
      } else {
        Logger.log('Failed to store payment proof in local storage');
        return null;
      }
    } catch (e, st) {
      Logger.logError('Failed to store payment proof locally', e, st);
      return null;
    }
  }
  
  /// Retrieve payment proof from local storage
  static Future<Uint8List?> getPaymentProof(String localReference) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Extract the key from the local reference
      final key = localReference.replaceFirst('local://', '');
      final storageKey = '${_storageKey}_$key';
      
      final dataString = prefs.getString(storageKey);
      if (dataString == null) {
        Logger.log('Payment proof not found in local storage: $key');
        return null;
      }
      
      final metadata = jsonDecode(dataString) as Map<String, dynamic>;
      final base64Data = metadata['data'] as String;
      
      // Decode base64 data
      final bytes = base64Decode(base64Data);
      Logger.log('Retrieved payment proof from local storage: $key (${bytes.length} bytes)');
      
      return bytes;
    } catch (e, st) {
      Logger.logError('Failed to retrieve payment proof from local storage', e, st);
      return null;
    }
  }
  
  /// Get metadata for a local payment proof
  static Future<Map<String, dynamic>?> getPaymentProofMetadata(String localReference) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final key = localReference.replaceFirst('local://', '');
      final storageKey = '${_storageKey}_$key';
      
      final dataString = prefs.getString(storageKey);
      if (dataString == null) return null;
      
      final metadata = jsonDecode(dataString) as Map<String, dynamic>;
      
      // Remove the actual data from metadata for efficiency
      final metadataOnly = Map<String, dynamic>.from(metadata);
      metadataOnly.remove('data');
      
      return metadataOnly;
    } catch (e, st) {
      Logger.logError('Failed to get payment proof metadata', e, st);
      return null;
    }
  }
  
  /// List all local payment proofs for a user
  static Future<List<String>> listUserPaymentProofs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final userProofs = <String>[];
      
      for (final key in keys) {
        if (key.startsWith('${_storageKey}_${userId}_')) {
          final localKey = key.replaceFirst('${_storageKey}_', '');
          userProofs.add('local://$localKey');
        }
      }
      
      return userProofs;
    } catch (e, st) {
      Logger.logError('Failed to list user payment proofs', e, st);
      return [];
    }
  }
  
  /// Delete a local payment proof
  static Future<bool> deletePaymentProof(String localReference) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final key = localReference.replaceFirst('local://', '');
      final storageKey = '${_storageKey}_$key';
      
      final success = await prefs.remove(storageKey);
      
      if (success) {
        Logger.log('Deleted local payment proof: $key');
      }
      
      return success;
    } catch (e, st) {
      Logger.logError('Failed to delete local payment proof', e, st);
      return false;
    }
  }
  
  /// Clean up old local storage entries to prevent storage bloat
  static Future<void> _cleanupOldEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final proofKeys = keys.where((key) => key.startsWith(_storageKey)).toList();
      
      // Sort by timestamp (newest first)
      proofKeys.sort((a, b) {
        try {
          final aData = jsonDecode(prefs.getString(a) ?? '{}') as Map<String, dynamic>;
          final bData = jsonDecode(prefs.getString(b) ?? '{}') as Map<String, dynamic>;
          
          final aTimestamp = aData['timestamp'] as int? ?? 0;
          final bTimestamp = bData['timestamp'] as int? ?? 0;
          
          return bTimestamp.compareTo(aTimestamp);
        } catch (e) {
          return 0;
        }
      });
      
      // Keep only the 10 most recent entries
      const maxEntries = 10;
      if (proofKeys.length > maxEntries) {
        final keysToDelete = proofKeys.skip(maxEntries);
        
        for (final key in keysToDelete) {
          await prefs.remove(key);
          Logger.log('Cleaned up old local payment proof: $key');
        }
      }
      
      // Also check total storage size and clean up if needed
      int totalSize = 0;
      for (final key in proofKeys.take(maxEntries)) {
        try {
          final dataString = prefs.getString(key);
          if (dataString != null) {
            final metadata = jsonDecode(dataString) as Map<String, dynamic>;
            totalSize += metadata['size'] as int? ?? 0;
          }
        } catch (e) {
          // Skip invalid entries
        }
      }
      
      Logger.log('Local storage usage: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
    } catch (e, st) {
      Logger.logError('Failed to cleanup old local storage entries', e, st);
    }
  }
  
  /// Check if a reference is a local storage reference
  static bool isLocalReference(String? reference) {
    return reference?.startsWith('local://') ?? false;
  }
  
  /// Get total local storage usage
  static Future<int> getLocalStorageUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_storageKey)) {
          try {
            final dataString = prefs.getString(key);
            if (dataString != null) {
              final metadata = jsonDecode(dataString) as Map<String, dynamic>;
              totalSize += metadata['size'] as int? ?? 0;
            }
          } catch (e) {
            // Skip invalid entries
          }
        }
      }
      
      return totalSize;
    } catch (e, st) {
      Logger.logError('Failed to calculate local storage usage', e, st);
      return 0;
    }
  }
}

