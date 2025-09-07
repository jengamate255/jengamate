import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jengamate/services/supabase_service.dart';
import 'package:jengamate/utils/logger.dart';

class SupabaseStorageService {
  final SupabaseClient _supabaseClient;
  final String bucket;

  SupabaseStorageService({
    required SupabaseClient supabaseClient,
    this.bucket =
        'payment_proofs', // Changed default bucket to match RLS policies
  }) : _supabaseClient = supabaseClient;

  /// Uploads an image to Supabase Storage
  ///
  /// [fileName] - The name to give the uploaded file
  /// [folder] - The folder to upload the file to
  /// [bytes] - The file bytes (required for web)
  /// [file] - The file to upload (required for mobile/desktop)
  ///
  /// Returns the public URL of the uploaded file
  @Deprecated('Use uploadFile instead with user-specific folders')
  Future<String> uploadImage({
    required String fileName,
    required String folder,
    Uint8List? bytes,
    File? file,
  }) async {
    try {
      return await uploadFile(
        fileName: fileName,
        folder: folder,
        bytes: bytes,
        file: file,
      );
    } catch (e, st) {
      Logger.logError('Image upload failed: $e', e, st);
      rethrow;
    }
  }

  /// Uploads a file to Supabase Storage with user-specific folder
  ///
  /// [fileName] - The name to give the uploaded file
  /// [folder] - Optional subfolder within the user's folder
  /// [bytes] - The file bytes (required for web)
  /// [file] - The file to upload (required for mobile/desktop)
  ///
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required String fileName,
    String? folder,
    Uint8List? bytes,
    File? file,
  }) async {
    try {
      // Get Firebase user ID for storage path
      final supabaseUserId = _supabaseClient.auth.currentUser?.id;

      // Try to get Firebase user ID as fallback
      final firebaseUserId = FirebaseAuth.instance.currentUser?.uid;

      // Use either Supabase user ID or Firebase user ID
      final userId = supabaseUserId ?? firebaseUserId;

      if (userId == null) {
        // Use a temporary folder for unauthenticated users
        Logger.log('No authenticated user, using temp folder');
        throw Exception('User must be authenticated to upload files');
      }

      Logger.log(
          'Using user ID for folder: $userId (Firebase: $firebaseUserId, Supabase: $supabaseUserId)');

      // Create user-specific path
      final userFolder = userId;
      final uploadPath = folder != null
          ? '$userFolder/$folder/$fileName'
          : '$userFolder/$fileName';

      Logger.log('Uploading file to path: $uploadPath');

      // Handle upload based on platform
      if (kIsWeb) {
        if (bytes == null) {
          throw ArgumentError('Bytes must be provided for web uploads');
        }
        await _supabaseClient.storage
            .from(bucket)
            .uploadBinary(uploadPath, bytes);
      } else {
        if (file == null) {
          throw ArgumentError(
              'File must be provided for mobile/desktop uploads');
        }
        await _supabaseClient.storage.from(bucket).upload(uploadPath, file);
      }

      // Get public URL (if bucket is public)
      final publicUrl =
          _supabaseClient.storage.from(bucket).getPublicUrl(uploadPath);

      Logger.log('File uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e, st) {
      Logger.logError('Failed to upload file: $e', e, st);
      rethrow;
    }
  }

  /// Gets a signed URL for a file (works with private buckets)
  Future<String?> getSignedUrl(String filePath) async {
    try {
      final response = await _supabaseClient.storage
          .from(bucket)
          .createSignedUrl(filePath, 60 * 60); // 1 hour expiry
      return response;
    } catch (e, st) {
      Logger.logError('Failed to get signed URL: $e', e, st);
      return null;
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
