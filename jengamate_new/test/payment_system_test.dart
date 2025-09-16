import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/enums/payment_enums.dart';

void main() {
  group('Payment System Tests', () {
    test('PaymentModel should create with correct Supabase format', () {
      final payment = PaymentModel(
        id: 'test_payment_123',
        orderId: 'order_456',
        userId: 'user_789',
        amount: 50000.0,
        status: PaymentStatus.pending,
        paymentMethod: 'bankTransfer',
        transactionId: 'TXN123456',
        paymentProofUrl: 'https://supabase.com/proof.jpg',
        createdAt: DateTime.now(),
        completedAt: null,
        metadata: {'test': 'data'},
        autoApproved: false,
      );

      // Test toMap() method produces Supabase-compatible format
      final map = payment.toMap();

      expect(map['order_id'], equals('order_456'));
      expect(map['user_id'], equals('user_789'));
      expect(map['payment_method'], equals('bankTransfer'));
      expect(map['payment_proof_url'], equals('https://supabase.com/proof.jpg'));
      expect(map['amount'], equals(50000.0));
      expect(map['status'], equals('pending'));
    });

    test('PaymentModel fromMap should work with Supabase data', () {
      final supabaseData = {
        'id': 'test_payment_123',
        'order_id': 'order_456',
        'user_id': 'user_789',
        'amount': 50000.0,
        'status': 'pending',
        'payment_method': 'bankTransfer',
        'transaction_id': 'TXN123456',
        'payment_proof_url': 'https://supabase.com/proof.jpg',
        'created_at': DateTime.now().toIso8601String(),
        'completed_at': null,
        'metadata': {'test': 'data'},
        'auto_approved': false,
      };

      final payment = PaymentModel.fromMap(supabaseData);

      expect(payment.id, equals('test_payment_123'));
      expect(payment.orderId, equals('order_456'));
      expect(payment.userId, equals('user_789'));
      expect(payment.amount, equals(50000.0));
      expect(payment.status, equals(PaymentStatus.pending));
      expect(payment.paymentMethod, equals('bankTransfer'));
    });

    test('PaymentStatus enum should have all expected values', () {
      expect(PaymentStatus.pending, isNotNull);
      expect(PaymentStatus.completed, isNotNull);
      expect(PaymentStatus.failed, isNotNull);
      expect(PaymentStatus.cancelled, isNotNull);
      expect(PaymentStatus.approved, isNotNull);
      expect(PaymentStatus.rejected, isNotNull);
    });

    test('PaymentMethod enum should have all expected values', () {
      expect(PaymentMethod.bankTransfer, isNotNull);
      expect(PaymentMethod.mobileMoney, isNotNull);
      expect(PaymentMethod.cash, isNotNull);
      expect(PaymentMethod.mpesa, isNotNull);
      expect(PaymentMethod.creditCard, isNotNull);
      expect(PaymentMethod.paypal, isNotNull);
    });

    test('PaymentModel copyWith should work correctly', () {
      final original = PaymentModel(
        id: 'original_id',
        orderId: 'order_123',
        userId: 'user_456',
        amount: 1000.0,
        status: PaymentStatus.pending,
        paymentMethod: 'bankTransfer',
        transactionId: 'TXN001',
        paymentProofUrl: null,
        createdAt: DateTime.now(),
        completedAt: null,
        metadata: null,
        autoApproved: false,
      );

      final updated = original.copyWith(
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
        paymentProofUrl: 'https://example.com/proof.jpg',
      );

      expect(updated.id, equals(original.id));
      expect(updated.status, equals(PaymentStatus.completed));
      expect(updated.completedAt, isNotNull);
      expect(updated.paymentProofUrl, equals('https://example.com/proof.jpg'));
    });
  });
}
