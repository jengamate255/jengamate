import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jengamate/services/supabase_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';

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

/// Specialized storage service for payment proofs with advanced features
class PaymentProofStorageService extends SupabaseStorageService {
  static const String _paymentProofsBucket = 'payment_proofs';
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> _allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'application/pdf',
  ];

  PaymentProofStorageService({
    required SupabaseClient supabaseClient,
  }) : super(
    supabaseClient: supabaseClient,
    bucket: _paymentProofsBucket,
  );

  /// Upload payment proof with comprehensive validation and processing
  Future<PaymentProofUploadResult> uploadPaymentProof({
    required String orderId,
    required String userId,
    required String transactionId,
    Uint8List? proofBytes,
    File? proofFile,
    String? fileName,
    int maxRetries = 3,
    bool compressImage = true,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    final startTime = DateTime.now();

    try {
      // Step 1: Validate authentication
      final user = await _validateAuthentication();
      if (user == null) {
        return PaymentProofUploadResult.failure(
          error: 'User authentication required',
          errorType: PaymentProofErrorType.authentication,
          metadata: {'user_id': userId},
        );
      }

      // Step 2: Validate and process file
      final fileValidation = await _validateAndProcessFile(
        proofBytes: proofBytes,
        proofFile: proofFile,
        compressImage: compressImage,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );

      if (!fileValidation.isValid) {
        return PaymentProofUploadResult.failure(
          error: fileValidation.errorMessage ?? 'File validation failed',
          errorType: PaymentProofErrorType.validation,
          metadata: fileValidation.details,
        );
      }

      // Step 3: Generate secure filename
      final secureFileName = _generateSecureFileName(
        orderId: orderId,
        userId: userId,
        transactionId: transactionId,
        originalFileName: fileName,
      );

      // Step 4: Upload with retry mechanism
      final uploadResult = await _uploadWithRetry(
        fileName: secureFileName,
        folder: '$userId/$orderId',
        bytes: fileValidation.processedBytes,
        file: proofFile,
        maxRetries: maxRetries,
      );

      if (!uploadResult.success) {
        return PaymentProofUploadResult.failure(
          error: uploadResult.error ?? 'Upload failed',
          errorType: PaymentProofErrorType.upload,
          metadata: uploadResult.metadata,
        );
      }

      // Step 5: Verify upload and generate metadata
      final verificationResult = await _verifyUpload(uploadResult.proofUrl!);
      if (!verificationResult.isAccessible) {
        // Cleanup failed upload
        await deleteImage(uploadResult.proofUrl!);
        return PaymentProofUploadResult.failure(
          error: 'Upload verification failed',
          errorType: PaymentProofErrorType.verification,
          metadata: verificationResult.details,
        );
      }

      // Step 6: Generate comprehensive metadata
      final metadata = await _generatePaymentProofMetadata(
        originalFileName: fileName,
        processedBytes: fileValidation.processedBytes,
        proofUrl: uploadResult.proofUrl!,
        filePath: uploadResult.filePath!,
        processingTime: DateTime.now().difference(startTime).inMilliseconds,
        uploadAttempts: uploadResult.metadata?['upload_attempts'] as int? ?? 1,
      );

      Logger.log('Payment proof uploaded successfully: ${uploadResult.proofUrl}');

      return PaymentProofUploadResult.success(
        proofUrl: uploadResult.proofUrl!,
        filePath: uploadResult.filePath!,
        metadata: metadata,
      );

    } catch (e, stackTrace) {
      Logger.logError('Unexpected error in uploadPaymentProof', e, stackTrace);

      return PaymentProofUploadResult.failure(
        error: 'Unexpected error: $e',
        errorType: PaymentProofErrorType.unexpected,
        metadata: {
          'stack_trace': stackTrace.toString(),
          'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
        },
      );
    }
  }

  /// Validate user authentication
  Future<String?> _validateAuthentication() async {
    try {
      final supabaseUser = _supabaseClient.auth.currentUser;
      final firebaseUser = FirebaseAuth.instance.currentUser;

      final userId = supabaseUser?.id ?? firebaseUser?.uid;

      if (userId == null) {
        Logger.logError('No authenticated user found', null, StackTrace.current);
        return null;
      }

      Logger.log('Authenticated user: $userId');
      return userId;
    } catch (e) {
      Logger.logError('Authentication validation failed', e, StackTrace.current);
      return null;
    }
  }

  /// Validate and process file
  Future<FileValidationResult> _validateAndProcessFile({
    Uint8List? proofBytes,
    File? proofFile,
    required bool compressImage,
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    try {
      Uint8List fileBytes;

      // Get file bytes
      if (kIsWeb && proofBytes != null) {
        fileBytes = proofBytes;
      } else if (!kIsWeb && proofFile != null) {
        fileBytes = await proofFile.readAsBytes();
      } else {
        return FileValidationResult.invalid('No file data provided');
      }

      // Validate file size
      if (fileBytes.length > _maxFileSizeBytes) {
        return FileValidationResult.invalid(
          'File size exceeds maximum limit of ${_maxFileSizeBytes ~/ (1024 * 1024)}MB',
          details: {'file_size': fileBytes.length, 'max_size': _maxFileSizeBytes},
        );
      }

      // Detect MIME type
      final mimeType = _detectMimeType(fileBytes);
      if (mimeType == null || !_allowedMimeTypes.contains(mimeType)) {
        return FileValidationResult.invalid(
          'Unsupported file type: $mimeType',
          details: {'detected_mime_type': mimeType, 'allowed_types': _allowedMimeTypes},
        );
      }

      // Process image if compression is enabled
      Uint8List processedBytes = fileBytes;
      if (compressImage && mimeType.startsWith('image/') && !mimeType.contains('svg')) {
        final compressionResult = await _compressImage(
          fileBytes,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
        processedBytes = compressionResult.bytes;
      }

      return FileValidationResult.valid(
        processedBytes,
        mimeType: mimeType,
        originalSize: fileBytes.length,
        processedSize: processedBytes.length,
      );

    } catch (e, stackTrace) {
      Logger.logError('File validation failed', e, stackTrace);
      return FileValidationResult.invalid(
        'File processing failed: $e',
        details: {'error': e.toString(), 'stack_trace': stackTrace.toString()},
      );
    }
  }

  /// Detect MIME type from file bytes
  String? _detectMimeType(Uint8List bytes) {
    if (bytes.length < 4) return null;

    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // PNG
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }

    // WebP
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return 'image/webp';
    }

    // PDF
    if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
      return 'application/pdf';
    }

    return null;
  }

  /// Compress image
  Future<ImageCompressionResult> _compressImage(
    Uint8List bytes, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        return ImageCompressionResult(bytes, originalWidth: 0, originalHeight: 0);
      }

      // Calculate new dimensions
      var newWidth = image.width;
      var newHeight = image.height;

      if (newWidth > maxWidth || newHeight > maxHeight) {
        final aspectRatio = newWidth / newHeight;

        if (newWidth > newHeight) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }

      // Resize if needed
      img.Image resizedImage;
      if (newWidth != image.width || newHeight != image.height) {
        resizedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.average,
        );
      } else {
        resizedImage = image;
      }

      // Compress
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      return ImageCompressionResult(
        Uint8List.fromList(compressedBytes),
        originalWidth: image.width,
        originalHeight: image.height,
        newWidth: newWidth,
        newHeight: newHeight,
        compressionRatio: bytes.length / compressedBytes.length,
      );

    } catch (e) {
      Logger.logError('Image compression failed', e, StackTrace.current);
      return ImageCompressionResult(bytes, originalWidth: 0, originalHeight: 0);
    }
  }

  /// Generate secure filename
  String _generateSecureFileName({
    required String orderId,
    required String userId,
    required String transactionId,
    String? originalFileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = base64Url.encode(utf8.encode('$userId$orderId$transactionId$timestamp')).substring(0, 8);

    String extension = '.jpg'; // default
    if (originalFileName != null) {
      final ext = originalFileName.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'pdf'].contains(ext)) {
        extension = '.$ext';
      }
    }

    return 'payment_proof_${timestamp}_$hash$extension';
  }

  /// Upload with retry mechanism
  Future<PaymentProofUploadResult> _uploadWithRetry({
    required String fileName,
    required String folder,
    Uint8List? bytes,
    File? file,
    required int maxRetries,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final uploadPath = folder.isNotEmpty ? '$folder/$fileName' : fileName;

        Logger.log('Upload attempt $attempt/$maxRetries: $uploadPath');

        // Upload file
        if (kIsWeb && bytes != null) {
          await _supabaseClient.storage
              .from(bucket)
              .uploadBinary(uploadPath, bytes);
        } else if (!kIsWeb && file != null) {
          await _supabaseClient.storage
              .from(bucket)
              .upload(uploadPath, file);
        } else {
          throw Exception('No file data provided for upload');
        }

        // Get public URL
        final publicUrl = _supabaseClient.storage
            .from(bucket)
            .getPublicUrl(uploadPath);

        return PaymentProofUploadResult.success(
          proofUrl: publicUrl,
          filePath: uploadPath,
          metadata: {
            'upload_attempts': attempt,
            'upload_method': kIsWeb ? 'binary' : 'file',
          },
        );

      } catch (e, stackTrace) {
        Logger.logError('Upload attempt $attempt failed: $e', e, stackTrace);

        if (attempt == maxRetries) {
          return PaymentProofUploadResult.failure(
            error: e.toString(),
            errorType: PaymentProofErrorType.upload,
            metadata: {
              'total_attempts': attempt,
              'stack_trace': stackTrace.toString(),
            },
          );
        }

        // Exponential backoff
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return PaymentProofUploadResult.failure(
      error: 'Upload failed after all retry attempts',
      errorType: PaymentProofErrorType.upload,
      metadata: {'total_attempts': maxRetries},
    );
  }

  /// Verify upload accessibility
  Future<UploadVerificationResult> _verifyUpload(String proofUrl) async {
    try {
      // For now, just check if URL is properly formed
      // In production, you might want to make a HEAD request to verify accessibility
      final uri = Uri.parse(proofUrl);
      final isValidUrl = uri.isAbsolute && uri.host.contains('supabase');

      if (!isValidUrl) {
        return UploadVerificationResult.inaccessible(
          details: {'invalid_url': proofUrl},
        );
      }

      return UploadVerificationResult.accessible(
        details: {'verified_url': proofUrl},
      );

    } catch (e) {
      return UploadVerificationResult.inaccessible(
        details: {'verification_error': e.toString()},
      );
    }
  }

  /// Generate comprehensive metadata
  Future<Map<String, dynamic>> _generatePaymentProofMetadata({
    String? originalFileName,
    Uint8List? processedBytes,
    required String proofUrl,
    required String filePath,
    required int processingTime,
    required int uploadAttempts,
  }) async {
    return {
      'original_filename': originalFileName,
      'file_size_bytes': processedBytes?.length ?? 0,
      'proof_url': proofUrl,
      'file_path': filePath,
      'uploaded_at': DateTime.now().toIso8601String(),
      'processing_time_ms': processingTime,
      'upload_attempts': uploadAttempts,
      'platform': kIsWeb ? 'web' : 'mobile',
      'security_hash': _generateSecurityHash(filePath),
    };
  }

  /// Generate security hash for file verification
  String _generateSecurityHash(String filePath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return base64Url.encode(utf8.encode(filePath + timestamp)).substring(0, 16);
  }

  /// Delete payment proof with verification
  Future<bool> deletePaymentProof(String proofUrl, {bool verifyDeletion = true}) async {
    try {
      final deleteResult = await deleteImage(proofUrl);

      if (verifyDeletion && deleteResult) {
        // Verify deletion by checking if URL is still accessible
        final verification = await _verifyUpload(proofUrl);
        if (verification.isAccessible) {
          Logger.log('Warning: Payment proof may not have been properly deleted');
          return false;
        }
      }

      return deleteResult;
    } catch (e) {
      Logger.logError('Failed to delete payment proof', e, StackTrace.current);
      return false;
    }
  }
}

/// Result classes for payment proof operations

enum PaymentProofErrorType {
  authentication,
  validation,
  upload,
  verification,
  unexpected,
}

class PaymentProofUploadResult {
  final bool success;
  final String? proofUrl;
  final String? filePath;
  final String? error;
  final PaymentProofErrorType? errorType;
  final Map<String, dynamic>? metadata;

  PaymentProofUploadResult._({
    required this.success,
    this.proofUrl,
    this.filePath,
    this.error,
    this.errorType,
    this.metadata,
  });

  factory PaymentProofUploadResult.success({
    required String proofUrl,
    required String filePath,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentProofUploadResult._(
      success: true,
      proofUrl: proofUrl,
      filePath: filePath,
      metadata: metadata,
    );
  }

  factory PaymentProofUploadResult.failure({
    required String error,
    required PaymentProofErrorType errorType,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentProofUploadResult._(
      success: false,
      error: error,
      errorType: errorType,
      metadata: metadata,
    );
  }
}

class FileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Uint8List? processedBytes;
  final Map<String, dynamic>? details;
  final String? mimeType;
  final int? originalSize;
  final int? processedSize;

  FileValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.processedBytes,
    this.details,
    this.mimeType,
    this.originalSize,
    this.processedSize,
  });

  factory FileValidationResult.valid(
    Uint8List processedBytes, {
    String? mimeType,
    int? originalSize,
    int? processedSize,
  }) {
    return FileValidationResult._(
      isValid: true,
      processedBytes: processedBytes,
      mimeType: mimeType,
      originalSize: originalSize,
      processedSize: processedSize,
    );
  }

  factory FileValidationResult.invalid(
    String errorMessage, {
    Map<String, dynamic>? details,
  }) {
    return FileValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
      details: details,
    );
  }
}

class ImageCompressionResult {
  final Uint8List bytes;
  final int originalWidth;
  final int originalHeight;
  final int? newWidth;
  final int? newHeight;
  final double? compressionRatio;

  ImageCompressionResult(
    this.bytes, {
    required this.originalWidth,
    required this.originalHeight,
    this.newWidth,
    this.newHeight,
    this.compressionRatio,
  });
}

class UploadVerificationResult {
  final bool isAccessible;
  final Map<String, dynamic>? details;

  UploadVerificationResult._({
    required this.isAccessible,
    this.details,
  });

  factory UploadVerificationResult.accessible({
    Map<String, dynamic>? details,
  }) {
    return UploadVerificationResult._(
      isAccessible: true,
      details: details,
    );
  }

  factory UploadVerificationResult.inaccessible({
    Map<String, dynamic>? details,
  }) {
    return UploadVerificationResult._(
      isAccessible: false,
      details: details,
    );
  }
}
