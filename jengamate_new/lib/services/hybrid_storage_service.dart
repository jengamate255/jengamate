import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:jengamate/services/storage_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HybridStorageService {
  final StorageService _firebaseStorageService;
  final SupabaseClient _supabaseClient;

  HybridStorageService({
    required SupabaseClient supabaseClient,
    required StorageService firebaseStorageService,
  })  : _supabaseClient = supabaseClient,
        _firebaseStorageService = firebaseStorageService;

  Future<String?> uploadImage({
    required String fileName,
    required String folder,
    Uint8List? bytes,
    File? file,
  }) async {
    try {
      Logger.log('Attempting to upload to Supabase Storage...');
      final uploadPath = '$folder/$fileName';

      if (bytes != null) {
        await _supabaseClient.storage.from('product_images').uploadBinary(
              uploadPath,
              bytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
      } else if (file != null) {
        await _supabaseClient.storage.from('product_images').upload(
              uploadPath,
              file,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
      } else {
        throw ArgumentError('Either bytes or file must be provided.');
      }

      final downloadUrl = _supabaseClient.storage.from('product_images').getPublicUrl(uploadPath);
      Logger.log('Supabase upload successful: $downloadUrl');
      return downloadUrl;
    } catch (e, st) {
      // Bubble up the exact error so UI can display it in SnackBar
      Logger.logError('Supabase upload failed: $e', e, st);
      rethrow;
    }
  }

  Future<bool> deleteImage(String url) async {
    try {
      // Handle Supabase public URLs only
      if (url.contains('supabase.co')) {
        // Expected formats:
        // - .../storage/v1/object/public/<bucket>/<path>
        // - .../storage/v1/object/<bucket>/<path> (non-public URL)
        final uri = Uri.parse(url);
        final segments = uri.pathSegments;
        final storageIndex = segments.indexOf('object');
        if (storageIndex != -1 && storageIndex + 1 < segments.length) {
          final bucket = segments[storageIndex + 1];
          final path = segments.sublist(storageIndex + 2).join('/');
          await _supabaseClient.storage.from(bucket).remove([path]);
          Logger.log('Successfully deleted image from Supabase.');
          return true;
        }
      }
      // Non-Supabase URL or unrecognized format
      Logger.log('Delete skipped: non-Supabase URL or unrecognized format.');
      return false;
    } catch (e) {
      Logger.logError('Error deleting image', e);
      return false;
    }
  }
}
