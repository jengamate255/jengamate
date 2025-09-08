/// Enum for invoice status
enum InvoiceStatus {
  draft,
  sent,
  viewed,
  paid,
  partiallyPaid,
  overdue,
  cancelled,
}

/// Enum for payment status
enum PaymentStatus {
  pending,
  processing,
  confirmed,
  verified,
  failed,
  cancelled,
  refunded,
}

/// Enum for payment methods
enum PaymentMethod {
  bankTransfer,
  mobileMoney,
  creditCard,
  debitCard,
  cash,
  check,
  digitalWallet,
  other,
}

/// Extension methods for enums
extension InvoiceStatusExtension on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.viewed:
        return 'Viewed';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get color {
    switch (this) {
      case InvoiceStatus.draft:
        return '#6B7280'; // Gray
      case InvoiceStatus.sent:
        return '#3B82F6'; // Blue
      case InvoiceStatus.viewed:
        return '#8B5CF6'; // Purple
      case InvoiceStatus.paid:
        return '#10B981'; // Green
      case InvoiceStatus.partiallyPaid:
        return '#F59E0B'; // Yellow
      case InvoiceStatus.overdue:
        return '#EF4444'; // Red
      case InvoiceStatus.cancelled:
        return '#6B7280'; // Gray
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.confirmed:
        return 'Confirmed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get color {
    switch (this) {
      case PaymentStatus.pending:
        return '#F59E0B'; // Yellow
      case PaymentStatus.processing:
        return '#3B82F6'; // Blue
      case PaymentStatus.confirmed:
        return '#10B981'; // Green
      case PaymentStatus.failed:
        return '#EF4444'; // Red
      case PaymentStatus.cancelled:
        return '#6B7280'; // Gray
      case PaymentStatus.refunded:
        return '#8B5CF6'; // Purple
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'account_balance';
      case PaymentMethod.mobileMoney:
        return 'phone_android';
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.debitCard:
        return 'credit_card';
      case PaymentMethod.cash:
        return 'money';
      case PaymentMethod.check:
        return 'receipt';
      case PaymentMethod.digitalWallet:
        return 'account_balance_wallet';
      case PaymentMethod.other:
        return 'payment';
    }
  }
}