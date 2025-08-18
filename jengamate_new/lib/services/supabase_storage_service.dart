import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/utils/logger.dart';

class SupabaseStorageService {
  final SupabaseClient _supabaseClient;
  final String bucket;

  SupabaseStorageService({
    required SupabaseClient supabaseClient,
    this.bucket = 'product_images',
  }) : _supabaseClient = supabaseClient;

  Future<String?> uploadImage({
    required String fileName,
    required String folder,
    Uint8List? bytes,
    File? file,
  }) async {
    try {
      final uploadPath = '$folder/$fileName';

      if (bytes != null) {
        await _supabaseClient.storage.from(bucket).uploadBinary(
              uploadPath,
              bytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
      } else if (file != null) {
        await _supabaseClient.storage.from(bucket).upload(
              uploadPath,
              file,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
      } else {
        throw ArgumentError('Either bytes or file must be provided.');
      }

      final downloadUrl = _supabaseClient.storage.from(bucket).getPublicUrl(uploadPath);
      Logger.log('Supabase upload successful: $downloadUrl');
      return downloadUrl;
    } catch (e, st) {
      Logger.logError('Supabase upload failed: $e', e, st);
      rethrow;
    }
  }

  Future<bool> deleteImage(String url) async {
    try {
      // Expected public URL format:
      // .../storage/v1/object/public/<bucket>/<path>
      // or non-public: .../storage/v1/object/<bucket>/<path>
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final storageIndex = segments.indexOf('object');
      if (storageIndex != -1 && storageIndex + 1 < segments.length) {
        final bucketName = segments[storageIndex + 1];
        final path = segments.sublist(storageIndex + 2).join('/');
        await _supabaseClient.storage.from(bucketName).remove([path]);
        Logger.log('Successfully deleted image from Supabase.');
        return true;
      }
      Logger.log('Delete skipped: unrecognized Supabase URL format.');
      return false;
    } catch (e) {
      Logger.logError('Error deleting image', e);
      return false;
    }
  }
}
