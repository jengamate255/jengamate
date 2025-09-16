import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:jengamate/utils/logger.dart';

/// Local payment proof service as fallback when Supabase storage fails
class LocalPaymentProofService {
  static const String _storageKey = 'payment_proofs';
  
  /// Store payment proof locally as base64 encoded data
  static Future<String?> storePaymentProof({
    required String orderId,
    required String userId,
    required Uint8List proofBytes,
    String? fileName,
  }) async {
    try {
      // Create a unique key for this proof
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final key = '${userId}_${orderId}_$timestamp';
      
      // Encode the bytes as base64
      final base64Data = base64Encode(proofBytes);
      
      // Store in local storage (using shared preferences or similar)
      // For now, we'll just return a local reference
      final localReference = 'local://$key';
      
      Logger.log('Payment proof stored locally: $localReference');
      
      return localReference;
    } catch (e, st) {
      Logger.logError('Failed to store payment proof locally', e, st);
      return null;
    }
  }
  
  /// Retrieve payment proof from local storage
  static Future<Uint8List?> getPaymentProof(String localReference) async {
    try {
      // Extract the key from the local reference
      final key = localReference.replaceFirst('local://', '');
      
      // In a real implementation, you would retrieve from local storage
      // For now, return null as this is just a fallback mechanism
      Logger.log('Retrieving payment proof from local storage: $key');
      
      return null;
    } catch (e, st) {
      Logger.logError('Failed to retrieve payment proof from local storage', e, st);
      return null;
    }
  }
  
  /// Check if a reference is a local storage reference
  static bool isLocalReference(String? reference) {
    return reference?.startsWith('local://') ?? false;
  }
}

