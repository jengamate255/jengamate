import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import '../models/payment_model.dart';
import '../models/enums/payment_enums.dart';
import '../utils/logger.dart';

/// Comprehensive payment validation and verification service
class PaymentValidationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final PaymentValidationService _instance = PaymentValidationService._internal();
  factory PaymentValidationService() => _instance;
  PaymentValidationService._internal();

  /// Validate complete payment data before processing
  Future<PaymentValidationResult> validatePayment({
    required String orderId,
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String transactionId,
    String? paymentProofUrl,
    Uint8List? proofBytes,
    String? notes,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final validationDetails = <String, dynamic>{};

    try {
      // 1. Validate basic payment parameters
      final basicValidation = await _validateBasicParameters(
        orderId: orderId,
        userId: userId,
        amount: amount,
        transactionId: transactionId,
      );

      errors.addAll(basicValidation.errors);
      warnings.addAll(basicValidation.warnings);
      validationDetails.addAll(basicValidation.details);

      // 2. Validate order-specific constraints
      final orderValidation = await _validateOrderConstraints(
        orderId: orderId,
        userId: userId,
        amount: amount,
      );

      errors.addAll(orderValidation.errors);
      warnings.addAll(orderValidation.warnings);
      validationDetails.addAll(orderValidation.details);

      // 3. Validate payment method constraints
      final methodValidation = _validatePaymentMethod(
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        amount: amount,
      );

      errors.addAll(methodValidation.errors);
      warnings.addAll(methodValidation.warnings);
      validationDetails.addAll(methodValidation.details);

      // 4. Validate payment proof if provided
      if (paymentProofUrl != null || proofBytes != null) {
        final proofValidation = await _validatePaymentProof(
          proofUrl: paymentProofUrl,
          proofBytes: proofBytes,
          orderId: orderId,
          userId: userId,
        );

        errors.addAll(proofValidation.errors);
        warnings.addAll(proofValidation.warnings);
        validationDetails.addAll(proofValidation.details);
      }

      // 5. Validate against business rules
      final businessValidation = await _validateBusinessRules(
        orderId: orderId,
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      errors.addAll(businessValidation.errors);
      warnings.addAll(businessValidation.warnings);
      validationDetails.addAll(businessValidation.details);

      // 6. Check for duplicate payments
      final duplicateCheck = await _checkForDuplicatePayments(
        orderId: orderId,
        transactionId: transactionId,
        userId: userId,
      );

      errors.addAll(duplicateCheck.errors);
      warnings.addAll(duplicateCheck.warnings);
      validationDetails.addAll(duplicateCheck.details);

      return PaymentValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
        details: validationDetails,
        riskLevel: _calculateRiskLevel(errors, warnings),
      );

    } catch (e, stackTrace) {
      Logger.logError('Payment validation failed unexpectedly', e, stackTrace);
      return PaymentValidationResult(
        isValid: false,
        errors: ['Validation system error: $e'],
        warnings: [],
        details: {'validation_error': e.toString()},
        riskLevel: PaymentRiskLevel.critical,
      );
    }
  }

  /// Validate basic payment parameters
  Future<ValidationStepResult> _validateBasicParameters({
    required String orderId,
    required String userId,
    required double amount,
    required String transactionId,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    // Validate order ID format
    if (orderId.isEmpty || orderId.length < 10) {
      errors.add('Invalid order ID format');
      details['order_id_valid'] = false;
    } else {
      details['order_id_valid'] = true;
    }

    // Validate user ID
    if (userId.isEmpty) {
      errors.add('User ID is required');
      details['user_id_valid'] = false;
    } else {
      details['user_id_valid'] = true;
    }

    // Validate amount
    if (amount <= 0) {
      errors.add('Payment amount must be greater than 0');
      details['amount_valid'] = false;
    } else if (amount > 10000000) { // 10M limit
      errors.add('Payment amount exceeds maximum allowed limit');
      details['amount_within_limit'] = false;
    } else {
      details['amount_valid'] = true;
      details['amount_within_limit'] = true;
    }

    // Validate transaction ID
    if (transactionId.trim().isEmpty) {
      errors.add('Transaction ID is required');
      details['transaction_id_valid'] = false;
    } else if (transactionId.trim().length < 3) {
      errors.add('Transaction ID must be at least 3 characters');
      details['transaction_id_valid'] = false;
    } else {
      details['transaction_id_valid'] = true;
    }

    return ValidationStepResult(
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Validate order-specific constraints
  Future<ValidationStepResult> _validateOrderConstraints(
    String orderId,
    String userId,
    double amount,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      // Check if order exists
      final orderResponse = await _supabase
          .from('orders')
          .select('id, total_amount, amount_paid, status, user_id')
          .eq('id', orderId)
          .single();

      if (orderResponse.isEmpty) {
        errors.add('Order not found');
        details['order_exists'] = false;
        return ValidationStepResult(
          errors: errors,
          warnings: warnings,
          details: details,
        );
      }

      details['order_exists'] = true;
      details['order_data'] = orderResponse;

      final orderData = orderResponse;
      final totalAmount = (orderData['total_amount'] as num).toDouble();
      final amountPaid = (orderData['amount_paid'] as num?)?.toDouble() ?? 0.0;
      final orderStatus = orderData['status'] as String;
      final orderUserId = orderData['user_id'] as String;

      // Check if user owns the order
      if (orderUserId != userId) {
        errors.add('You do not have permission to make payments for this order');
        details['user_owns_order'] = false;
      } else {
        details['user_owns_order'] = true;
      }

      // Check order status
      if (orderStatus == 'cancelled') {
        errors.add('Cannot make payments for cancelled orders');
        details['order_status_valid'] = false;
      } else if (orderStatus == 'completed') {
        errors.add('Order is already completed');
        details['order_status_valid'] = false;
      } else {
        details['order_status_valid'] = true;
      }

      // Check payment amount against order total
      final remainingAmount = totalAmount - amountPaid;
      if (amount > remainingAmount + 1000) { // Allow small overpayment tolerance
        warnings.add('Payment amount exceeds remaining order balance by more than TSh 1,000');
        details['amount_exceeds_remaining'] = true;
      }

      if (amount > totalAmount * 1.1) { // 10% overpayment warning
        warnings.add('Payment amount is more than 10% over the total order amount');
        details['significant_overpayment'] = true;
      }

      details['remaining_amount'] = remainingAmount;
      details['total_amount'] = totalAmount;

    } catch (e) {
      errors.add('Failed to validate order: $e');
      details['order_validation_error'] = e.toString();
    }

    return ValidationStepResult(
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Validate payment method constraints
  ValidationStepResult _validatePaymentMethod({
    required PaymentMethod paymentMethod,
    required String transactionId,
    required double amount,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    switch (paymentMethod) {
      case PaymentMethod.bankTransfer:
        // Bank transfers require transaction reference
        if (transactionId.length < 6) {
          warnings.add('Bank transfer transaction references are usually longer than 6 characters');
        }
        break;

      case PaymentMethod.mobileMoney:
        // Mobile money transactions have specific formats
        if (!RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(transactionId)) {
          warnings.add('Mobile money transaction ID format may be incorrect');
        }
        break;

      case PaymentMethod.cash:
        // Cash payments might not have formal transaction IDs
        if (transactionId.length < 4) {
          warnings.add('Cash payment reference should be more descriptive');
        }
        break;

      case PaymentMethod.mpesa:
        // M-Pesa transactions have specific formats
        if (!RegExp(r'^[A-Z0-9]+$').hasMatch(transactionId)) {
          warnings.add('M-Pesa transaction ID format may be incorrect');
        }
        break;

      case PaymentMethod.creditCard:
        // Credit card transactions usually have longer references
        if (transactionId.length < 8) {
          warnings.add('Credit card transaction references are usually longer');
        }
        break;

      case PaymentMethod.paypal:
        // PayPal transactions have specific formats
        if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(transactionId)) {
          warnings.add('PayPal transaction ID format may be incorrect');
        }
        break;

      case PaymentMethod.cheque:
        // Cheque payments have cheque numbers
        if (transactionId.length < 6) {
          warnings.add('Cheque number should be more descriptive');
        }
        break;

      case PaymentMethod.stripe:
      case PaymentMethod.paystack:
      case PaymentMethod.flutterwave:
        // Online payment processors usually have longer transaction IDs
        if (transactionId.length < 10) {
          warnings.add('${paymentMethod.name} transaction IDs are usually longer');
        }
        break;

      case PaymentMethod.unknown:
        warnings.add('Unknown payment method - additional verification recommended');
        break;
    }

    // Validate amount ranges for different methods
    if (paymentMethod == PaymentMethod.mobileMoney && amount > 5000000) {
      warnings.add('Large amounts via mobile money may require additional verification');
    }

    details['payment_method'] = paymentMethod.name;
    details['transaction_id_format_valid'] = true;

    return ValidationStepResult(
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Validate payment proof
  Future<ValidationStepResult> _validatePaymentProof({
    String? proofUrl,
    Uint8List? proofBytes,
    required String orderId,
    required String userId,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    if (proofUrl == null && proofBytes == null) {
      details['proof_provided'] = false;
      return ValidationStepResult(
        errors: errors,
        warnings: warnings,
        details: details,
      );
    }

    details['proof_provided'] = true;

    // If URL is provided, validate it
    if (proofUrl != null) {
      if (!proofUrl.contains('supabase')) {
        warnings.add('Payment proof should be uploaded to secure storage');
        details['proof_url_secure'] = false;
      } else {
        details['proof_url_secure'] = true;
      }

      // Check if URL is accessible (basic validation)
      if (!proofUrl.startsWith('https://')) {
        errors.add('Payment proof URL must use HTTPS');
        details['proof_url_valid'] = false;
      } else {
        details['proof_url_valid'] = true;
      }
    }

    // If bytes are provided, validate file
    if (proofBytes != null) {
      // Check file size (should be reasonable for payment proofs)
      if (proofBytes.length > 10 * 1024 * 1024) { // 10MB
        errors.add('Payment proof file is too large (max 10MB)');
        details['proof_size_valid'] = false;
      } else {
        details['proof_size_valid'] = true;
      }

      // Basic file type detection
      final fileSignature = proofBytes.sublist(0, proofBytes.length > 4 ? 4 : proofBytes.length);

      if (_isImageFile(fileSignature)) {
        details['proof_file_type'] = 'image';
      } else if (_isPdfFile(fileSignature)) {
        details['proof_file_type'] = 'pdf';
      } else {
        warnings.add('Payment proof file type may not be supported');
        details['proof_file_type'] = 'unknown';
      }
    }

    return ValidationStepResult(
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Validate business rules
  Future<ValidationStepResult> _validateBusinessRules({
    required String orderId,
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      // Check user's payment history for suspicious patterns
      final recentPayments = await _supabase
          .from('payments')
          .select('amount, created_at, status')
          .eq('user_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(hours: 24)).toIso8601String())
          .order('created_at', ascending: false)
          .limit(10);

      if (recentPayments.length > 5) {
        warnings.add('Multiple payments detected in the last 24 hours');
        details['high_payment_frequency'] = true;
      }

      // Check for unusually large amounts
      final totalRecentAmount = recentPayments.fold<double>(
        0,
        (sum, payment) => sum + (payment['amount'] as num).toDouble(),
      );

      if (totalRecentAmount + amount > 20000000) { // 20M in 24h
        warnings.add('Total payment amount in last 24 hours exceeds normal threshold');
        details['high_daily_volume'] = true;
      }

      // Validate payment timing (business hours preference)
      final now = DateTime.now();
      if (now.hour < 6 || now.hour > 22) {
        warnings.add('Payment submitted outside normal business hours');
        details['outside_business_hours'] = true;
      }

    } catch (e) {
      // Don't fail validation for business rule errors, just log
      Logger.logError('Business rule validation failed', e, StackTrace.current);
      details['business_rule_validation_error'] = e.toString();
    }

    return ValidationStepResult(
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Check for duplicate payments
  Future<ValidationStepResult> _checkForDuplicatePayments({
    required String orderId,
    required String transactionId,
    required String userId,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      // Check for exact transaction ID match
      final existingPayment = await _supabase
          .from('payments')
          .select('id, status, created_at')
          .eq('transaction_id', transactionId)
          .eq('user_id', userId)
          .single();

      if (existingPayment.isNotEmpty) {
        final paymentData = existingPayment;
        final paymentStatus = paymentData['status'] as String;
        final createdAt = DateTime.parse(paymentData['created_at']);

        if (paymentStatus == 'completed') {
          errors.add('A payment with this transaction ID already exists');
          details['duplicate_transaction'] = true;
        } else if (DateTime.now().difference(createdAt).inHours < 24) {
          warnings.add('A payment with this transaction ID was recently submitted');
          details['recent_duplicate_attempt'] = true;
        }
      }

      // Check for payments to same order in short time frame
      final recentOrderPayments = await _supabase
          .from('payments')
          .select('id, amount, created_at')
          .eq('order_id', orderId)
          .gte('created_at', DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String());

      if (recentOrderPayments.length > 0) {
        warnings.add('Another payment was submitted for this order very recently');
        details['recent_order_payment'] = true;
      }

    } catch (e) {
      // If duplicate check fails, don't block payment but log the issue
      Logger.logError('Duplicate payment check failed', e, StackTrace.current);
      details['duplicate_check_error'] = e.toString();
    }

    return ValidationStepResult(
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Calculate overall risk level
  PaymentRiskLevel _calculateRiskLevel(List<String> errors, List<String> warnings) {
    if (errors.isNotEmpty) {
      return PaymentRiskLevel.critical;
    }

    if (warnings.length > 2) {
      return PaymentRiskLevel.high;
    }

    if (warnings.isNotEmpty) {
      return PaymentRiskLevel.medium;
    }

    return PaymentRiskLevel.low;
  }

  /// Helper methods for file validation
  bool _isImageFile(List<int> signature) {
    if (signature.length < 4) return false;

    // JPEG
    if (signature[0] == 0xFF && signature[1] == 0xD8 && signature[2] == 0xFF) return true;

    // PNG
    if (signature[0] == 0x89 && signature[1] == 0x50 && signature[2] == 0x4E && signature[3] == 0x47) return true;

    // WebP
    if (signature[0] == 0x52 && signature[1] == 0x49 && signature[2] == 0x46 && signature[3] == 0x46) return true;

    return false;
  }

  bool _isPdfFile(List<int> signature) {
    if (signature.length < 4) return false;
    return signature[0] == 0x25 && signature[1] == 0x50 && signature[2] == 0x44 && signature[3] == 0x46;
  }

  /// Generate payment verification hash
  String generatePaymentHash({
    required String orderId,
    required String userId,
    required double amount,
    required String transactionId,
    required DateTime timestamp,
  }) {
    final data = '$orderId$userId$amount$transactionId${timestamp.toIso8601String()}';
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Verify payment integrity
  bool verifyPaymentIntegrity({
    required PaymentModel payment,
    required String expectedHash,
  }) {
    final calculatedHash = generatePaymentHash(
      orderId: payment.orderId,
      userId: payment.userId,
      amount: payment.amount,
      transactionId: payment.transactionId ?? '',
      timestamp: payment.createdAt,
    );

    return calculatedHash == expectedHash;
  }
}

/// Validation result classes
class PaymentValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> details;
  final PaymentRiskLevel riskLevel;

  PaymentValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.details,
    required this.riskLevel,
  });

  String get summary {
    if (!isValid) {
      return 'Payment validation failed: ${errors.join(", ")}';
    }

    if (warnings.isNotEmpty) {
      return 'Payment validated with warnings: ${warnings.join(", ")}';
    }

    return 'Payment validation successful';
  }
}

class ValidationStepResult {
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> details;

  ValidationStepResult({
    required this.errors,
    required this.warnings,
    required this.details,
  });
}

enum PaymentRiskLevel {
  low,
  medium,
  high,
  critical,
}
