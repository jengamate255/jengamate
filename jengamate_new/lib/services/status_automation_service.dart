import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/invoice_model.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/services/invoice_service.dart';
import 'package:jengamate/services/notification_service.dart';
import 'package:jengamate/services/email_service.dart';
import 'package:jengamate/models/email_template.dart';
import 'package:jengamate/models/enums/payment_enums.dart';
import '../utils/logger.dart' as utils_logger;

/// Core service for automated invoice status management and intelligent reminders
class StatusAutomationService {
  static final StatusAutomationService _instance =
      StatusAutomationService._internal();
  factory StatusAutomationService() => _instance;
  StatusAutomationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InvoiceService _invoiceService = InvoiceService();
  final NotificationService _notificationService = NotificationService();
  final EmailService _emailService = EmailService();

  static const String _collectionName = 'invoices';
  static const String _statusHistoryCollection = 'invoice_status_history';
  static const String _automationLogCollection = 'automation_logs';

  /// Rule definitions for automatic status transitions
  static const Map<String, Map<String, dynamic>> _statusRules = {
    'due_date_passed': {
      'conditions': ['sent', 'partially_paid'],
      'new_status': 'overdue',
      'trigger_type': 'due_date_check',
      'priority': 1,
    },
    'payment_confirmed': {
      'conditions': ['sent', 'partially_paid', 'overdue'],
      'new_status': 'paid',
      'trigger_type': 'payment',
      'priority': 2,
    },
    'partial_payment': {
      'conditions': ['sent', 'overdue'],
      'new_status': 'partially_paid',
      'trigger_type': 'payment',
      'priority': 3,
    },
  };

  /// Reminder configuration
  static const Map<String, Map<String, dynamic>> _reminderRules = {
    'early_reminder': {
      'days_before_due': 7,
      'status_required': ['sent'],
      'template_type': EmailTemplateType.reminder,
      'notification_type': 'reminder',
      'priority': 'low',
    },
    'urgent_reminder': {
      'days_before_due': 3,
      'status_required': ['sent'],
      'template_type': EmailTemplateType.reminder,
      'notification_type': 'reminder',
      'priority': 'medium',
    },
    'urgent_overdue': {
      'days_after_due': 1,
      'status_required': ['overdue'],
      'template_type': EmailTemplateType.overdue,
      'notification_type': 'alert',
      'priority': 'high',
    },
    'critical_overdue': {
      'days_after_due': 7,
      'status_required': ['overdue'],
      'template_type': EmailTemplateType.overdue,
      'notification_type': 'alert',
      'priority': 'critical',
    },
    'final_notice': {
      'days_after_due': 30,
      'status_required': ['overdue'],
      'template_type': EmailTemplateType.overdue,
      'notification_type': 'alert',
      'priority': 'critical',
    },
  };

  /// Main entry point - process all invoices for automated rules
  Future<void> processAutomatedRules() async {
    try {
      utils_logger.Logger.log(
          '🚀 Starting automated invoice status processing...');

      final invoices = await _getInvoicesNeedingAutomation();
      int processed = 0;
      int updates = 0;
      int notifications = 0;

      for (final invoice in invoices) {
        final result = await _processInvoiceRules(invoice);
        processed++;

        if (result['status_changed'] == true) updates++;
        if (result['notification_sent'] == true) notifications++;

        if (processed % 10 == 0) {
          utils_logger.Logger.log('   📊 Processed $processed invoices...');
        }
      }

      utils_logger.Logger.log(
          '✅ Automation complete: $updates status updates, $notifications notifications');

      // Log automation results
      await _logAutomationResults(processed, updates, notifications);
    } catch (e, s) {
      utils_logger.Logger.logError('Error in processAutomatedRules: $e', e, s);
    }
  }

  /// Process all rules for a single invoice
  Future<Map<String, dynamic>> _processInvoiceRules(
      InvoiceModel invoice) async {
    final results = {
      'status_changed': false,
      'notification_sent': false,
      'rules_applied': <String>[]
    };

    try {
      // 1. Check for status transition rules
      final statusResult = await _applyStatusRules(invoice);
      if (statusResult['status_changed'] == true) {
        results['status_changed'] = true;
        final appliedRules = statusResult['rules_applied'] as List<String>;
        results['rules_applied'] = [
          ...results['rules_applied'],
          ...appliedRules
        ];
      }

      // 2. Check for reminder rules (use updated status if changed)
      final reminderInvoice = statusResult['updated_invoice'] ?? invoice;
      final reminderResult = await _applyReminderRules(reminderInvoice);
      if (reminderResult['notification_sent'] == true) {
        results['notification_sent'] = true;
        final appliedRules = reminderResult['rules_applied'] as List<String>;
        results['rules_applied'] = [
          ...results['rules_applied'],
          ...appliedRules
        ];
      }

      return results;
    } catch (e, s) {
      utils_logger.Logger.logError(
          'Error processing rules for invoice ${invoice.id}: $e', e, s);
      return results;
    }
  }

  /// Apply status transition rules
  Future<Map<String, dynamic>> _applyStatusRules(InvoiceModel invoice) async {
    final results = {
      'status_changed': false,
      'rules_applied': <String>[],
      'updated_invoice': null
    };

    // Check for due date passed
    if (_shouldMarkAsOverdue(invoice)) {
      await _updateInvoiceStatus(
          invoice, 'overdue', 'automated_overdue_trigger');
      results['status_changed'] = true;
      results['rules_applied'].add('due_date_passed');
      results['updated_invoice'] = invoice.copyWith(status: 'overdue');
    }

    return results;
  }

  /// Apply reminder rules
  Future<Map<String, dynamic>> _applyReminderRules(InvoiceModel invoice) async {
    final results = {'notification_sent': false, 'rules_applied': <String>[]};

    final now = DateTime.now();
    final daysUntilDue = invoice.dueDate.difference(now).inDays;
    final daysPastDue = now.difference(invoice.dueDate).inDays;

    for (final rule in _reminderRules.entries) {
      final ruleConfig = rule.value;

      if (!_shouldSendReminder(invoice, ruleConfig, daysUntilDue, daysPastDue))
        continue;

      if (await _sendReminder(invoice, ruleConfig, daysPastDue)) {
        results['notification_sent'] = true;
        results['rules_applied'].add(rule.key);

        // Mark reminder as sent in database
        await _recordReminderSent(invoice, rule.key);

        // Only send one reminder per run to avoid spam
        break;
      }
    }

    return results;
  }

  /// Trigger specific rule manually
  Future<bool> triggerRule(String ruleName, InvoiceModel invoice,
      {Map<String, dynamic> additionalData = const {}}) async {
    try {
      utils_logger.Logger.log(
          '🎯 Manually triggering rule: $ruleName for invoice ${invoice.id}');

      switch (ruleName) {
        case 'payment_confirmed':
          final newStatus = additionalData['payment_full'] == true
              ? 'paid'
              : 'partially_paid';
          await _updateInvoiceStatus(invoice, newStatus, 'payment_triggered');
          return true;

        case 'due_date_passed':
          await _updateInvoiceStatus(
              invoice, 'overdue', 'manual_due_date_trigger');
          return true;

        case 'urgent_reminder':
          final urgentConfig = _reminderRules['urgent_reminder']!;
          await _sendReminder(invoice, urgentConfig, 0);
          return true;

        case 'overdue_notice':
          final overdueConfig = _reminderRules['urgent_overdue']!;
          await _sendReminder(invoice, overdueConfig, 1);
          return true;

        default:
          return false;
      }
    } catch (e, s) {
      utils_logger.Logger.logError('Error triggering rule $ruleName: $e', e, s);
      return false;
    }
  }

  /// Handle payment confirmations
  Future<void> handlePaymentConfirmation(String invoiceId, String paymentId,
      {required bool isFullPayment, String? paymentMethod}) async {
    try {
      final invoice = await _invoiceService.getInvoice(invoiceId);
      if (invoice == null) return;

      final result = await triggerRule('payment_confirmed', invoice,
          additionalData: {
            'payment_full': isFullPayment,
            'payment_method': paymentMethod
          });

      if (result) {
        utils_logger.Logger.log('💰 Payment confirmed for invoice $invoiceId');
      }
    } catch (e, s) {
      utils_logger.Logger.logError(
          'Error handling payment confirmation: $e', e, s);
    }
  }

  /// Private helper methods

  Future<List<InvoiceModel>> _getInvoicesNeedingAutomation() async {
    final now = DateTime.now();
    final dueDateThreshold =
        now.add(const Duration(days: 30)); // Look ahead 30 days
    final overdueThreshold =
        now.subtract(const Duration(days: 60)); // Look back 60 days

    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(overdueThreshold))
        .where('dueDate',
            isLessThanOrEqualTo: Timestamp.fromDate(dueDateThreshold))
        .where('status', whereIn: ['sent', 'partially_paid', 'overdue']).get();

    return querySnapshot.docs
        .map((doc) => InvoiceModel.fromFirestore(doc))
        .toList();
  }

  bool _shouldMarkAsOverdue(InvoiceModel invoice) {
    if (invoice.status == 'overdue' ||
        invoice.status == 'paid' ||
        invoice.status == 'cancelled') {
      return false;
    }

    final now = DateTime.now();
    return now.isAfter(invoice.dueDate.add(const Duration(days: 1)));
  }

  bool _shouldSendReminder(InvoiceModel invoice,
      Map<String, dynamic> ruleConfig, int daysUntilDue, int daysPastDue) {
    final requiredStatuses = ruleConfig['status_required'] as List<String>;
    if (!requiredStatuses.contains(invoice.status)) return false;

    final isWithinWindow =
        _isWithinReminderWindow(ruleConfig, daysUntilDue, daysPastDue);
    if (!isWithinWindow) return false;

    return !_hasReminderBeenSentWithinPeriod(invoice, ruleConfig);
  }

  bool _isWithinReminderWindow(
      Map<String, dynamic> ruleConfig, int daysUntilDue, int daysPastDue) {
    if (ruleConfig.containsKey('days_before_due')) {
      final targetDays = ruleConfig['days_before_due'] as int;
      return daysUntilDue <= targetDays && daysUntilDue >= 0;
    }

    if (ruleConfig.containsKey('days_after_due')) {
      final targetDays = ruleConfig['days_after_due'] as int;
      return daysPastDue >= targetDays;
    }

    return false;
  }

  bool _hasReminderBeenSentWithinPeriod(
      InvoiceModel invoice, Map<String, dynamic> ruleConfig) {
    // In a real implementation, you'd check a reminder history collection
    // For now, we'll use a simple time-based check
    final reminderKey =
        '${invoice.id}_${ruleConfig['days_before_due'] ?? ruleConfig['days_after_due']}';
    final lastSent = _getLastReminderTime(reminderKey);
    if (lastSent == null) return false;

    // Don't send same reminder within 7 days
    return lastSent.isAfter(DateTime.now().subtract(const Duration(days: 7)));
  }

  Future<void> _updateInvoiceStatus(
      InvoiceModel invoice, String newStatus, String reason) async {
    try {
      // Validate invoice ID is not null or empty
      if (invoice.id == null || invoice.id!.isEmpty) {
        utils_logger.Logger.logError(
            'Cannot update status: invoice ID is null or empty', null);
        return;
      }

      await _invoiceService.updateInvoiceStatus(invoice.id, newStatus);
      await _recordStatusChange(invoice, newStatus, reason);

      utils_logger.Logger.log(
          '📊 Status updated: ${invoice.id} → $newStatus (reason: $reason)');
    } catch (e, s) {
      utils_logger.Logger.logError('Error updating invoice status: $e', e, s);
    }
  }

  Future<bool> _sendReminder(InvoiceModel invoice,
      Map<String, dynamic> ruleConfig, int daysPastDue) async {
    try {
      // Generate reminder content
      final emailTemplate =
          _generateReminderTemplate(invoice, ruleConfig, daysPastDue);

      // Send email notification
      final emailSent = await _sendEmailReminder(invoice, emailTemplate);

      // Send in-app notification
      final notificationSent = await _sendInAppReminder(invoice, ruleConfig);

      return emailSent || notificationSent;
    } catch (e, s) {
      utils_logger.Logger.logError('Error sending reminder: $e', e, s);
      return false;
    }
  }

  Map<String, dynamic> _generateReminderTemplate(
      InvoiceModel invoice, Map<String, dynamic> ruleConfig, int daysPastDue) {
    final templateType = ruleConfig['template_type'] as EmailTemplateType;

    return {
      'invoice_number': invoice.invoiceNumber,
      'customer_name': invoice.customerName,
      'invoice_total': invoice.formatCurrency(invoice.totalAmount),
      'due_date': invoice.dueDate.toString().split(' ')[0],
      'days_overdue': daysPastDue > 0 ? daysPastDue : 0,
      'template_type': templateType,
    };
  }

  Future<bool> _sendEmailReminder(
      InvoiceModel invoice, Map<String, dynamic> templateData) async {
    try {
      // Validate invoice data
      if (invoice.id == null ||
          invoice.id!.isEmpty ||
          invoice.customerEmail.isEmpty) {
        utils_logger.Logger.logError(
            'Cannot send email reminder: missing invoice ID or customer email',
            null);
        return false;
      }

      final templateType = templateData['template_type'] as EmailTemplateType;
      final template = await _emailService.getDefaultTemplate(templateType);

      if (template == null) {
        utils_logger.Logger.logError(
            'No email template found for $templateType', null);
        return false;
      }

      // Use existing email service to send
      return await _emailService.sendInvoiceEmail(
        template: template,
        invoice: invoice,
        recipientEmail: invoice.customerEmail,
      );
    } catch (e) {
      utils_logger.Logger.logError('Email reminder failed: $e', e);
      return false;
    }
  }

  Future<bool> _sendInAppReminder(
      InvoiceModel invoice, Map<String, dynamic> ruleConfig) async {
    try {
      // Validate invoice data
      if (invoice.id == null || invoice.id!.isEmpty) {
        utils_logger.Logger.logError(
            'Cannot send in-app reminder: missing invoice ID', null);
        return false;
      }

      final title = _getReminderNotificationTitle(ruleConfig);
      final message = _getReminderNotificationMessage(invoice, ruleConfig);

      // Send push notification
      await _notificationService.showNotification(
        title: title,
        body: message,
        payload: 'invoice/${invoice.id}',
      );

      // Note: For now, we're only sending push notifications
      // The database record creation would need to be added to NotificationService

      return true;
    } catch (e) {
      utils_logger.Logger.logError('In-app reminder failed: $e', e);
      return false;
    }
  }

  String _getReminderNotificationTitle(Map<String, dynamic> ruleConfig) {
    switch (ruleConfig['priority']) {
      case 'critical':
        return '⚠️ URGENT: Invoice Action Required';
      case 'high':
        return '🚨 Invoice Overdue Notice';
      case 'medium':
        return '🔔 Payment Reminder';
      default:
        return '💰 Invoice Reminder';
    }
  }

  String _getReminderNotificationMessage(
      InvoiceModel invoice, Map<String, dynamic> ruleConfig) {
    final amount = invoice.formatCurrency(invoice.totalAmount);
    final days = ruleConfig['days_before_due'] ?? ruleConfig['days_after_due'];

    if (ruleConfig['days_before_due'] != null) {
      return 'Invoice ${invoice.invoiceNumber} (TSh ${invoice.totalAmount.toStringAsFixed(2)}) is due in $days days. Please ensure prompt payment.';
    } else {
      return 'Invoice ${invoice.invoiceNumber} (TSh ${invoice.totalAmount.toStringAsFixed(2)}) is $days days overdue. Immediate action required.';
    }
  }

  Future<void> _recordStatusChange(
      InvoiceModel invoice, String newStatus, String reason) async {
    try {
      // Validate invoice data
      if (invoice.id == null || invoice.id!.isEmpty) {
        utils_logger.Logger.logError(
            'Cannot record status change: missing invoice ID', null);
        return;
      }

      await _firestore.collection(_statusHistoryCollection).add({
        'invoiceId': invoice.id,
        'previousStatus': invoice.status,
        'newStatus': newStatus,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'automated': true,
        'userId': invoice.customerId,
      });
    } catch (e) {
      utils_logger.Logger.logError('Error recording status change: $e', e);
    }
  }

  Future<void> _recordReminderSent(
      InvoiceModel invoice, String ruleName) async {
    try {
      // Validate invoice data
      if (invoice.id == null || invoice.id!.isEmpty) {
        utils_logger.Logger.logError(
            'Cannot record reminder: missing invoice ID', null);
        return;
      }

      await _firestore.collection('reminder_history').add({
        'invoiceId': invoice.id,
        'ruleName': ruleName,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': invoice.customerId,
      });
    } catch (e) {
      utils_logger.Logger.logError('Error recording reminder: $e', e);
    }
  }

  Future<void> _logAutomationResults(
      int processed, int updates, int notifications) async {
    try {
      await _firestore.collection(_automationLogCollection).add({
        'timestamp': FieldValue.serverTimestamp(),
        'invoices_processed': processed,
        'status_updates': updates,
        'notifications_sent': notifications,
        'rules_applied': _statusRules.keys.length + _reminderRules.keys.length,
      });
    } catch (e) {
      utils_logger.Logger.logError('Error logging automation results: $e', e);
    }
  }

  DateTime? _getLastReminderTime(String reminderKey) {
    // In a real implementation, you'd query the reminder_history collection
    // For now, return a mock implementation
    return DateTime.now().subtract(const Duration(days: 8));
  }

  /// Public interface for manual operations
  Future<List<InvoiceModel>> getOverdueInvoices() async {
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: 'overdue')
        .get();

    return querySnapshot.docs
        .map((doc) => InvoiceModel.fromFirestore(doc))
        .toList();
  }

  Future<List<InvoiceModel>> getInvoicesNeedingAttention(
      {int daysThreshold = 7}) async {
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));

    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('dueDate', isLessThan: Timestamp.fromDate(thresholdDate))
        .where('status', whereIn: ['sent', 'partially_paid']).get();

    return querySnapshot.docs
        .map((doc) => InvoiceModel.fromFirestore(doc))
        .toList();
  }
}
