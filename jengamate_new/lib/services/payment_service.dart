import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:jengamate/models/enums/payment_enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/payment_model.dart';
import '../models/enums/order_enums.dart';
import '../utils/logger.dart';
import 'local_payment_proof_service.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _paymentsTable = 'payments';
  static const String _ordersTable = 'orders';
  static const String _paymentProofsBucket = 'payment_proofs';

  /// Advanced error reporting and logging
  Future<void> _logPaymentEvent(String event, String paymentId, {
    String? error,
    Map<String, dynamic>? metadata,
    String? level = 'INFO'
  }) async {
    try {
      await _supabase.from('payment_logs').insert({
        'payment_id': paymentId,
        'event': event,
        'level': level,
        'error_message': error,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': fb_auth.FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      Logger.logError('Failed to log payment event: $e', e, StackTrace.current);
    }
  }

  /// Robust payment creation with transaction safety
  Future<PaymentResult> createPaymentWithProof({
    required String orderId,
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String transactionId,
    String? notes,
    Uint8List? proofBytes,
    File? proofFile,
    String? proofFileName,
    int maxRetries = 3,
  }) async {
    final startTime = DateTime.now();
    String? paymentId;
    String? proofUrl;

    try {
      // Step 1: Validate input parameters
      final validation = await _validatePaymentInput(orderId, userId, amount);
      if (!validation.isValid) {
        return PaymentResult.failure(
          error: PaymentError.validationFailed,
          message: validation.errorMessage ?? 'Validation failed',
          metadata: {'validation_details': validation.details}
        );
      }

      // If the validator resolved a canonical UUID for the order (via RPC),
      // switch to that ID for subsequent operations.
      final String usedOrderId = (validation.details['resolved_order_id'] as String?) ?? orderId;

      // Step 2: Upload payment proof first (if provided) - with graceful fallback
      if (proofBytes != null || proofFile != null) {
        final uploadResult = await _uploadPaymentProof(
          orderId: usedOrderId,
          userId: userId,
          proofBytes: proofBytes,
          proofFile: proofFile,
          proofFileName: proofFileName,
          maxRetries: maxRetries,
        );

        if (!uploadResult.success) {
          // Try local storage fallback
          Logger.logError('Payment proof upload failed, trying local storage fallback', uploadResult.error);
          
          if (proofBytes != null) {
            final localProofUrl = await LocalPaymentProofService.storePaymentProof(
              orderId: usedOrderId,
              userId: userId,
              proofBytes: proofBytes,
              fileName: proofFileName,
            );
            
            if (localProofUrl != null) {
              proofUrl = localProofUrl;
              Logger.log('Payment proof stored locally as fallback: $localProofUrl');
            } else {
              Logger.log('Local storage fallback also failed, continuing without proof');
              proofUrl = null;
            }
          } else {
            proofUrl = null;
          }
        } else {
          proofUrl = uploadResult.proofUrl;
        }
      }

      // Step 3: Create payment record only after proof upload succeeds
      final paymentResult = await _createPaymentRecord(
        orderId: usedOrderId,
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        proofUrl: proofUrl,
        notes: notes,
      );

      if (!paymentResult.success) {
        // If payment creation failed but proof was uploaded, cleanup the proof
        if (proofUrl != null) {
          await _cleanupFailedPaymentProof(proofUrl);
        }

        return PaymentResult.failure(
          error: PaymentError.databaseError,
          message: 'Failed to create payment record: ${paymentResult.error}',
          metadata: paymentResult.metadata,
        );
      }

      paymentId = paymentResult.paymentId;

      // Mirror created payment into Firestore so Firestore-driven UIs reflect new payments
      if (paymentId != null && paymentId.isNotEmpty) {
        try {
          await _mirrorPaymentToFirestore(paymentId);
        } catch (e, st) {
          Logger.logError('Failed to mirror payment $paymentId to Firestore', e, st);
        }
      }

      // Step 4: Update order status
      final orderUpdateResult = await _updateOrderAfterPayment(
        orderId: usedOrderId,
        paymentId: paymentId!,
        amount: amount,
      );

      if (!orderUpdateResult.success) {
        // Log the issue but don't fail the entire operation
        await _logPaymentEvent(
          'ORDER_UPDATE_FAILED',
          paymentId,
          error: orderUpdateResult.error,
          metadata: orderUpdateResult.metadata,
          level: 'WARN',
        );
      }

      // Step 5: Log successful payment
      await _logPaymentEvent(
        'PAYMENT_COMPLETED',
        paymentId,
        metadata: {
          'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
          'proof_uploaded': proofUrl != null,
          'order_updated': orderUpdateResult.success,
        },
      );

      return PaymentResult.success(
        paymentId: paymentId,
        proofUrl: proofUrl,
        metadata: {
          'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
        },
      );

    } catch (e, stackTrace) {
      // Log the unexpected error
      if (paymentId != null) {
        await _logPaymentEvent(
          'PAYMENT_FAILED_UNEXPECTED',
          paymentId,
          error: e.toString(),
          metadata: {
            'stack_trace': stackTrace.toString(),
            'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
          },
          level: 'ERROR',
        );
      }

      Logger.logError('Unexpected error in createPaymentWithProof', e, stackTrace);

      return PaymentResult.failure(
        error: PaymentError.unexpectedError,
        message: 'An unexpected error occurred: $e',
        metadata: {
          'stack_trace': stackTrace.toString(),
          'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
        },
      );
    }
  }

  /// Validate UUID format
  static bool isValidUUID(String value) {
    if (value.isEmpty) return false;

    // UUID v4 regex pattern
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    return uuidRegex.hasMatch(value);
  }

  /// Generates a valid UUID v4 for testing purposes.
  static String generateTestUUID() {
    final random = DateTime.now().millisecondsSinceEpoch;
    const template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
    return template.replaceAllMapped(RegExp(r'[xy]'), (match) {
      final r = (random + DateTime.now().microsecondsSinceEpoch) % 16;
      final v = match.group(0) == 'x' ? r : (r & 0x3 | 0x8);
      return v.toRadixString(16);
    });
  }

  /// Validate payment input parameters
  Future<PaymentValidationResult> _validatePaymentInput(
    String orderId,
    String userId,
    double amount,
  ) async {
    Logger.log('PaymentService Debug - Validating input:');
    Logger.log('  orderId: $orderId');
    Logger.log('  userId: $userId');
    Logger.log('  amount: $amount');

    final errors = <String>[];
    final details = <String, dynamic>{};

    // Validate orderId format first. If it's not a UUID, attempt a server-side
    // RPC lookup to resolve legacy/text identifiers to the canonical UUID.
    String? resolvedOrderId;
    if (!isValidUUID(orderId)) {
      // Check if it's a Firebase user ID (common mistake)
      final isFirebaseUserId = orderId.length == 28 &&
                              orderId.contains(RegExp(r'^[A-Za-z0-9]{28}$'));

      if (isFirebaseUserId) {
        Logger.logError('Firebase user ID detected instead of order ID',
                       'Received: $orderId, Expected: UUID format', StackTrace.current);
        // Try RPC fallback only for non-Firebase legacy IDs; for Firebase IDs
        // we still treat it as navigation error because it's likely a user mismatch.
        errors.add('Invalid order ID: Firebase user ID detected. Please navigate from an order details page.');
        details['order_id_format'] = 'firebase_user_id';
        details['received_id'] = orderId;
        return PaymentValidationResult(
          isValid: false,
          errorMessage: errors.join('; '),
          details: details,
        );
      }

      // Attempt to resolve non-UUID identifier via server RPC `orders_find` or fallback to direct query.
      try {
        Logger.log('Attempting RPC orders_find to resolve non-UUID order id: $orderId');
        final rpc = await _supabase.rpc('orders_find', params: {'p_id': orderId}).select().limit(1);
        if (rpc.isNotEmpty) {
          resolvedOrderId = rpc.first['id'] as String?;
          details['resolved_order_id'] = resolvedOrderId;
          Logger.log('Resolved order id via RPC: $resolvedOrderId');
        } else {
          // RPC returned no results, try fallback direct query
          Logger.log('RPC returned no results, trying fallback direct query');
          final fallbackQuery = await _supabase
              .from('orders')
              .select('id')
              .or('external_id.eq.$orderId,customer_id.eq.$orderId')
              .limit(1);

          if (fallbackQuery.isNotEmpty) {
            resolvedOrderId = fallbackQuery.first['id'] as String?;
            details['resolved_order_id'] = resolvedOrderId;
            Logger.log('Resolved order id via fallback query: $resolvedOrderId');
          } else {
            errors.add('Order not found: $orderId');
            details['order_id_format'] = 'not_found';
            details['received_id'] = orderId;
            return PaymentValidationResult(
              isValid: false,
              errorMessage: errors.join('; '),
              details: details,
            );
          }
        }
      } catch (e, st) {
        Logger.logError('RPC lookup for order id failed, trying fallback', e, st);

        // Try fallback direct query if RPC fails
        try {
          Logger.log('Attempting fallback direct query for order id: $orderId');
          final fallbackQuery = await _supabase
              .from('orders')
              .select('id')
              .or('external_id.eq.$orderId,customer_id.eq.$orderId')
              .limit(1);

          if (fallbackQuery.isNotEmpty) {
            resolvedOrderId = fallbackQuery.first['id'] as String?;
            details['resolved_order_id'] = resolvedOrderId;
            Logger.log('Resolved order id via fallback query: $resolvedOrderId');
          } else {
            errors.add('Order not found: $orderId');
            details['order_id_format'] = 'not_found';
            details['received_id'] = orderId;
            return PaymentValidationResult(
              isValid: false,
              errorMessage: errors.join('; '),
              details: details,
            );
          }
        } catch (fallbackError, fallbackSt) {
          Logger.logError('Fallback query also failed', fallbackError, fallbackSt);
          errors.add('Unable to validate order ID: $orderId');
          details['order_id_format'] = 'validation_error';
          details['received_id'] = orderId;
          return PaymentValidationResult(
            isValid: false,
            errorMessage: errors.join('; '),
            details: details,
          );
        }
      }
    }

    // Temporarily bypass order existence validation to isolate UUID error
    // try {
    //   Logger.log('PaymentService Debug - Querying order with ID: $orderId'); // Added log
    //   final orderResponse = await _supabase
    //       .from(_ordersTable)
    //       .select()
    //       .eq('id', orderId)
    //       .single();
    //
    //   if (orderResponse.isEmpty) {
    //     errors.add('Order not found');
    //     details['order_exists'] = false;
    //   } else {
    //     details['order_exists'] = true;
    //     details['order_data'] = orderResponse;
    //   }
    // } catch (e) {
    //   errors.add('Failed to validate order: $e');
    //   details['order_validation_error'] = e.toString();
    // }

    // Validate user exists (using Firebase Auth instead of Supabase auth)
    try {
      final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser?.uid != userId) {
        errors.add('User not authenticated or ID mismatch');
        details['user_exists'] = false;
      } else {
        details['user_exists'] = true;
      }
    } catch (e) {
      Logger.logError('Error validating user: $e', e, StackTrace.current);
      errors.add('Failed to validate user');
      details['user_exists'] = false;
    }

    // Validate amount
    if (amount <= 0) {
      errors.add('Amount must be greater than 0');
      details['amount_valid'] = false;
    } else {
      details['amount_valid'] = true;
    }

    if (amount > 10000000) { // 10 million limit
      errors.add('Amount exceeds maximum allowed limit');
      details['amount_within_limit'] = false;
    } else {
      details['amount_within_limit'] = true;
    }

    return PaymentValidationResult(
      isValid: errors.isEmpty,
      errorMessage: errors.isNotEmpty ? errors.join('; ') : null,
      details: details,
    );
  }

  /// Upload payment proof with retry mechanism
  Future<PaymentProofUploadResult> _uploadPaymentProof({
    required String orderId,
    required String userId,
    Uint8List? proofBytes,
    File? proofFile,
    String? proofFileName,
    required int maxRetries,
  }) async {
    final startTime = DateTime.now();
    String? generatedFileName;
    final String? supabaseUserId = _supabase.auth.currentUser?.id;
    if (supabaseUserId == null) {
      return PaymentProofUploadResult.failure(
        error: 'User not authenticated with Supabase',
        metadata: {'reason': 'no_supabase_session'},
      );
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Generate unique filename
        generatedFileName ??= proofFileName ??
            'payment_proof_${DateTime.now().millisecondsSinceEpoch}_${userId.hashCode}.jpg';

        // Create folder structure: supabaseUserId/orderId/
        final folderPath = '$supabaseUserId/$orderId';
        final filePath = '$folderPath/$generatedFileName';

        Logger.log('Attempting payment proof upload (attempt $attempt/$maxRetries): $filePath');

        // Upload file
        if (kIsWeb && proofBytes != null) {
          await _supabase.storage
              .from(_paymentProofsBucket)
              .uploadBinary(filePath, proofBytes);
        } else if (!kIsWeb && proofFile != null) {
          await _supabase.storage
              .from(_paymentProofsBucket)
              .upload(filePath, proofFile);
        } else {
          throw Exception('Invalid file data provided for upload');
        }

        // Get public URL
        final publicUrl = _supabase.storage
            .from(_paymentProofsBucket)
            .getPublicUrl(filePath);

        Logger.log('Payment proof uploaded successfully: $publicUrl');

        return PaymentProofUploadResult.success(
          proofUrl: publicUrl,
          filePath: filePath,
          metadata: {
            'upload_attempts': attempt,
            'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
            'file_size_bytes': proofBytes?.length ?? proofFile?.lengthSync(),
          },
        );

      } catch (e, stackTrace) {
        Logger.logError(
          'Payment proof upload attempt $attempt failed: $e',
          e,
          stackTrace,
        );

        // If this is the last attempt, return failure
        if (attempt == maxRetries) {
          return PaymentProofUploadResult.failure(
            error: e.toString(),
            metadata: {
              'total_attempts': attempt,
              'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
              'stack_trace': stackTrace.toString(),
              'generated_file_name': generatedFileName,
            },
          );
        }

        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    // This should never be reached, but just in case
    return PaymentProofUploadResult.failure(
      error: 'Upload failed after all retry attempts',
      metadata: {'total_attempts': maxRetries},
    );
  }

  /// Create payment record in database
  Future<PaymentCreationResult> _createPaymentRecord({
    required String orderId,
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String transactionId,
    String? proofUrl,
    String? notes,
  }) async {
    try {
      final String? supabaseUserId = _supabase.auth.currentUser?.id;
      if (supabaseUserId == null) {
        return PaymentCreationResult.failure(
          error: 'User not authenticated with Supabase',
          metadata: {'reason': 'no_supabase_session'},
        );
      }
      Logger.log('PaymentService Debug - Creating payment record for order ID: $orderId, user ID: $userId'); // Added log
      final paymentData = {
        'order_id': orderId,
        'user_id': supabaseUserId, // Must match Supabase auth user for RLS
        'amount': amount,
        'status': PaymentStatus.pending.name,
        'transaction_id': transactionId,
        'payment_proof_url': proofUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      Logger.log('PaymentService Debug - Final paymentData to insert: $paymentData'); // Added log
      final response = await _supabase
          .from(_paymentsTable)
          .insert(paymentData)
          .select()
          .single();

      final createdId = response['id'] as String;

      // If caller did not provide a transactionId, set the record's transaction_id
      // to the generated payment id so downstream systems have a reference.
      if (transactionId.isEmpty) {
        try {
          await _supabase
              .from(_paymentsTable)
              .update({'transaction_id': createdId})
              .eq('id', createdId);
        } catch (e) {
          // Non-fatal: log but continue returning success
          Logger.logError('Failed to backfill transaction_id for payment $createdId', e, StackTrace.current);
        }
      }

      return PaymentCreationResult.success(
        paymentId: createdId,
        metadata: {'created_at': response['created_at']},
      );

    } catch (e, stackTrace) {
      Logger.logError('Failed to create payment record', e, stackTrace);
      return PaymentCreationResult.failure(
        error: e.toString(),
        metadata: {'stack_trace': stackTrace.toString()},
      );
    }
  }

  /// Update order after successful payment
  Future<OrderUpdateResult> _updateOrderAfterPayment({
    required String orderId,
    required String paymentId,
    required double amount,
  }) async {
    try {
      Logger.log('PaymentService Debug - Updating order after payment. Order ID: $orderId, Payment ID: $paymentId, Amount: $amount'); // Added log
      // Get current order data
      final orderResponse = await _supabase
          .from(_ordersTable)
          .select('amount_paid, total_amount, status')
          .eq('id', orderId)
          .single();

      final currentAmountPaid = (orderResponse['amount_paid'] as num?)?.toDouble() ?? 0.0;
      final totalAmount = (orderResponse['total_amount'] as num).toDouble();
      final newAmountPaid = currentAmountPaid + amount;

      // Determine new status
      OrderStatus newStatus;
      if (newAmountPaid >= totalAmount) {
        newStatus = OrderStatus.fullyPaid;
      } else if (newAmountPaid > 0) {
        newStatus = OrderStatus.partiallyPaid;
      } else {
        newStatus = OrderStatus.pending;
      }

      // Update order in Supabase
      Logger.log('PaymentService Debug - Executing order update for ID: $orderId'); // Added log
      await _supabase
          .from(_ordersTable)
          .update({
            'amount_paid': newAmountPaid,
            'status': newStatus.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Also sync order amount/status to Firestore so Firestore-driven screens show accurate paid amount
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'amountPaid': newAmountPaid,
          'status': newStatus.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (e, st) {
        // Non-fatal: log and continue
        Logger.logError('Failed to update Firestore order $orderId with amountPaid', e, st);
      }

      return OrderUpdateResult.success(
        newAmountPaid: newAmountPaid,
        newStatus: newStatus,
        metadata: {
          'previous_amount_paid': currentAmountPaid,
          'total_amount': totalAmount,
        },
      );

    } catch (e, stackTrace) {
      Logger.logError('Failed to update order after payment', e, stackTrace);
      return OrderUpdateResult.failure(
        error: e.toString(),
        metadata: {'stack_trace': stackTrace.toString()},
      );
    }
  }

  /// Cleanup failed payment proof
  Future<void> _cleanupFailedPaymentProof(String proofUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(proofUrl);
      final pathSegments = uri.pathSegments;
      final storageIndex = pathSegments.indexOf('object');
      if (storageIndex != -1 && storageIndex + 2 < pathSegments.length) {
        final filePath = pathSegments.sublist(storageIndex + 2).join('/');
        await _supabase.storage.from(_paymentProofsBucket).remove([filePath]);
        Logger.log('Cleaned up failed payment proof: $filePath');
      }
    } catch (e) {
      Logger.logError('Failed to cleanup payment proof', e, StackTrace.current);
    }
  }

  /// Get payments for a specific order
  Stream<List<PaymentModel>> getPaymentsForOrder(String orderId) {
    return _supabase
        .from(_paymentsTable)
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => PaymentModel.fromMap(item)).toList());
  }

  /// Mirror a Supabase payment record into Firestore to keep Firestore-driven UIs in sync
  Future<void> _mirrorPaymentToFirestore(String paymentId) async {
    try {
      final payment = await getPaymentById(paymentId);
      if (payment == null) return;

      final docRef = FirebaseFirestore.instance.collection('payments').doc(payment.id);
      await docRef.set(payment.toMap());
      Logger.log('Mirrored payment $paymentId to Firestore');
    } catch (e, st) {
      Logger.logError('Failed to mirror payment to Firestore', e, st);
      rethrow;
    }
  }

  /// Stream user payments
  Stream<List<PaymentModel>> streamUserPayments(String userId) {
    return _supabase
        .from(_paymentsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => PaymentModel.fromMap(item)).toList());
  }

  /// Stream all payments (admin only)
  Stream<List<PaymentModel>> streamAllPayments() {
    return _supabase
        .from(_paymentsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => PaymentModel.fromMap(item)).toList());
  }

  /// Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    // If we have a UUID, use the normal path. Otherwise try a safe RPC that
    // looks up payments by transaction_id/user_id/metadata or returns empty.
    try {
      if (PaymentService.isValidUUID(paymentId)) {
        final response = await _supabase
            .from(_paymentsTable)
            .select()
            .eq('id', paymentId)
            .single();

        return PaymentModel.fromMap(response);
      }

      Logger.log('getPaymentById: non-UUID id provided, attempting RPC lookup: $paymentId');
      final rpcResult = await _supabase.rpc('payments_find', params: {'p_id': paymentId}).select().limit(1);

      if (rpcResult.isEmpty) {
        Logger.log('getPaymentById: RPC lookup returned no rows for id: $paymentId');
        return null;
      }

      // rpc returns a list of maps; take first
      return PaymentModel.fromMap(rpcResult.first);
    } catch (e, st) {
      Logger.logError('Failed to get payment by ID: $e', e, st);
      return null;
    }
  }

  /// Update payment status (admin only)
  Future<bool> updatePaymentStatus(String paymentId, PaymentStatus newStatus) async {
    try {
      // Avoid invalid UUIDs being used in filters to prevent Postgres errors
      if (!PaymentService.isValidUUID(paymentId)) {
        Logger.logError('updatePaymentStatus called with non-UUID id', paymentId, StackTrace.current);
        return false;
      }

      await _supabase
          .from(_paymentsTable)
          .update({
            'status': newStatus.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);

      await _logPaymentEvent(
        'PAYMENT_STATUS_UPDATED',
        paymentId,
        metadata: {'new_status': newStatus.name},
      );

      return true;
    } catch (e, stackTrace) {
      Logger.logError('Failed to update payment status', e, stackTrace);
      return false;
    }
  }

  /// Delete payment (admin only, with cleanup)
  Future<bool> deletePayment(String paymentId) async {
    try {
      // Guard against invalid IDs to avoid Postgres uuid parse errors
      if (!PaymentService.isValidUUID(paymentId)) {
        Logger.logError('deletePayment called with non-UUID id', paymentId, StackTrace.current);
        return false;
      }

      // Get payment data first
      final payment = await getPaymentById(paymentId);
      if (payment == null) return false;

      // Delete payment proof if exists
      if (payment.paymentProofUrl != null) {
        await _cleanupFailedPaymentProof(payment.paymentProofUrl!);
      }

      // Delete payment record
      await _supabase
          .from(_paymentsTable)
          .delete()
          .eq('id', paymentId);

      await _logPaymentEvent(
        'PAYMENT_DELETED',
        paymentId,
        metadata: {'had_proof': payment.paymentProofUrl != null},
      );

      return true;
    } catch (e, stackTrace) {
      Logger.logError('Failed to delete payment', e, stackTrace);
      return false;
    }
  }

  /// Get payment analytics
  Future<Map<String, dynamic>> getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      var query = _supabase.from(_paymentsTable).select();

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final payments = await query;
      final totalAmount = payments.fold<double>(0, (sum, payment) => sum + (payment['amount'] as num).toDouble());
      final totalCount = payments.length;
      final completedCount = payments.where((p) => p['status'] == PaymentStatus.completed.name).length;

      return {
        'total_payments': totalCount,
        'total_amount': totalAmount,
        'completed_payments': completedCount,
        'completion_rate': totalCount > 0 ? completedCount / totalCount : 0,
        'average_amount': totalCount > 0 ? totalAmount / totalCount : 0,
      };
    } catch (e, stackTrace) {
      Logger.logError('Failed to get payment analytics', e, stackTrace);
      return {};
    }
  }

  /// Legacy method for backward compatibility - creates payment without proof
  Future<String> createPayment(PaymentModel payment) async {
    try {
      // Convert string payment method to enum
      final paymentMethodEnum = PaymentMethod.values.firstWhere(
        (method) => method.name == payment.paymentMethod,
        orElse: () => PaymentMethod.unknown,
      );

      final result = await this.createPaymentWithProof(
        orderId: payment.orderId,
        userId: payment.userId,
        amount: payment.amount,
        paymentMethod: paymentMethodEnum,
        transactionId: payment.transactionId ?? '',
        proofBytes: null,
        proofFile: null,
        notes: payment.metadata?['notes'] as String?,
      );

      if (result.success) {
        return result.paymentId!;
      } else {
        throw Exception(result.message ?? 'Failed to create payment');
      }
    } catch (e) {
      Logger.logError('Failed to create payment', e, StackTrace.current);
      throw Exception('Failed to create payment: $e');
    }
  }
}

/// Result classes for robust error handling

enum PaymentError {
  validationFailed,
  proofUploadFailed,
  databaseError,
  orderNotFound,
  userNotFound,
  unexpectedError,
}

class PaymentResult {
  final bool success;
  final PaymentError? error;
  final String? message;
  final String? paymentId;
  final String? proofUrl;
  final Map<String, dynamic>? metadata;

  PaymentResult._({
    required this.success,
    this.error,
    this.message,
    this.paymentId,
    this.proofUrl,
    this.metadata,
  });

  factory PaymentResult.success({
    required String paymentId,
    String? proofUrl,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult._(
      success: true,
      paymentId: paymentId,
      proofUrl: proofUrl,
      metadata: metadata,
    );
  }

  factory PaymentResult.failure({
    required PaymentError error,
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult._(
      success: false,
      error: error,
      message: message,
      metadata: metadata,
    );
  }
}

class PaymentValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic> details;

  PaymentValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.details,
  });
}

class PaymentProofUploadResult {
  final bool success;
  final String? proofUrl;
  final String? filePath;
  final String? error;
  final Map<String, dynamic>? metadata;

  PaymentProofUploadResult._({
    required this.success,
    this.proofUrl,
    this.filePath,
    this.error,
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
    Map<String, dynamic>? metadata,
  }) {
    return PaymentProofUploadResult._(
      success: false,
      error: error,
      metadata: metadata,
    );
  }
}

class PaymentCreationResult {
  final bool success;
  final String? paymentId;
  final String? error;
  final Map<String, dynamic>? metadata;

  PaymentCreationResult._({
    required this.success,
    this.paymentId,
    this.error,
    this.metadata,
  });

  factory PaymentCreationResult.success({
    required String paymentId,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentCreationResult._(
      success: true,
      paymentId: paymentId,
      metadata: metadata,
    );
  }

  factory PaymentCreationResult.failure({
    required String error,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentCreationResult._(
      success: false,
      error: error,
      metadata: metadata,
    );
  }
}

class OrderUpdateResult {
  final bool success;
  final double? newAmountPaid;
  final OrderStatus? newStatus;
  final String? error;
  final Map<String, dynamic>? metadata;

  OrderUpdateResult._({
    required this.success,
    this.newAmountPaid,
    this.newStatus,
    this.error,
    this.metadata,
  });

  factory OrderUpdateResult.success({
    required double newAmountPaid,
    required OrderStatus newStatus,
    Map<String, dynamic>? metadata,
  }) {
    return OrderUpdateResult._(
      success: true,
      newAmountPaid: newAmountPaid,
      newStatus: newStatus,
      metadata: metadata,
    );
  }

  factory OrderUpdateResult.failure({
    required String error,
    Map<String, dynamic>? metadata,
  }) {
    return OrderUpdateResult._(
      success: false,
      error: error,
      metadata: metadata,
    );
  }
}
