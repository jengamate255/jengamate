import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jengamate/services/admin_notification_service.dart';
import 'package:jengamate/utils/logger.dart';

enum BulkOperationType {
  userManagement,
  contentModeration,
  dataExport,
}

enum BulkOperationStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled
}

class BulkOperationResult {
  final String id;
  final BulkOperationType type;
  final BulkOperationStatus status;
  final int totalItems;
  final int processedItems;
  final int successfulItems;
  final int failedItems;
  final List<String> errors;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? resultFilePath;
  final Map<String, dynamic>? metadata;

  const BulkOperationResult({
    required this.id,
    required this.type,
    required this.status,
    required this.totalItems,
    required this.processedItems,
    required this.successfulItems,
    required this.failedItems,
    required this.errors,
    required this.startedAt,
    this.completedAt,
    this.resultFilePath,
    this.metadata,
  });

  double get progress => totalItems > 0 ? processedItems / totalItems : 0.0;
  bool get isComplete => status == BulkOperationStatus.completed || status == BulkOperationStatus.failed;
}

class BulkOperationsService {
  static final BulkOperationsService _instance = BulkOperationsService._internal();
  factory BulkOperationsService() => _instance;

  BulkOperationsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminNotificationService _notificationService = AdminNotificationService();

  final StreamController<BulkOperationResult> _operationProgressController = StreamController.broadcast();

  Stream<BulkOperationResult> get operationProgress => _operationProgressController.stream;

  // Bulk User Operations
  Future<String> bulkUserApproval(List<String> userIds, {String? adminNotes}) async {
    final operationId = await _startBulkOperation(
      BulkOperationType.userManagement,
      userIds.length,
      {'operation': 'approve', 'adminNotes': adminNotes},
    );

    _processBulkUserApproval(operationId, userIds, adminNotes);
    return operationId;
  }

  Future<String> bulkUserRejection(List<String> userIds, String reason, {String? adminNotes}) async {
    final operationId = await _startBulkOperation(
      BulkOperationType.userManagement,
      userIds.length,
      {'operation': 'reject', 'reason': reason, 'adminNotes': adminNotes},
    );

    _processBulkUserRejection(operationId, userIds, reason, adminNotes);
    return operationId;
  }

  // Bulk Content Moderation Operations
  Future<String> bulkContentApproval(List<String> contentIds, {String? adminNotes}) async {
    final operationId = await _startBulkOperation(
      BulkOperationType.contentModeration,
      contentIds.length,
      {'operation': 'approve', 'adminNotes': adminNotes},
    );

    _processBulkContentApproval(operationId, contentIds, adminNotes);
    return operationId;
  }

  Future<String> bulkContentRejection(List<String> contentIds, String reason, {String? adminNotes}) async {
    final operationId = await _startBulkOperation(
      BulkOperationType.contentModeration,
      contentIds.length,
      {'operation': 'reject', 'reason': reason, 'adminNotes': adminNotes},
    );

    _processBulkContentRejection(operationId, contentIds, reason, adminNotes);
    return operationId;
  }

  // Data Export Operations
  Future<String> exportUsersData({List<String>? userIds}) async {
    final query = userIds != null && userIds.isNotEmpty
        ? _firestore.collection('users').where(FieldPath.documentId, whereIn: userIds)
        : _firestore.collection('users');

    final operationId = await _startBulkOperation(
      BulkOperationType.dataExport,
      await query.count().get().then((value) => value.count ?? 0),
      {'exportType': 'users'},
    );

    _processUserDataExport(operationId, query);
    return operationId;
  }

  // Private helper methods
  Future<String> _startBulkOperation(BulkOperationType type, int totalItems, Map<String, dynamic>? metadata) async {
    final operationId = _firestore.collection('bulk_operations').doc().id;

    final operation = BulkOperationResult(
      id: operationId,
      type: type,
      status: BulkOperationStatus.pending,
      totalItems: totalItems,
      processedItems: 0,
      successfulItems: 0,
      failedItems: 0,
      errors: [],
      startedAt: DateTime.now(),
      metadata: metadata,
    );

    await _firestore.collection('bulk_operations').doc(operationId).set({
      'type': type.name,
      'status': operation.status.name,
      'totalItems': operation.totalItems,
      'processedItems': operation.processedItems,
      'successfulItems': operation.successfulItems,
      'failedItems': operation.failedItems,
      'errors': operation.errors,
      'startedAt': Timestamp.fromDate(operation.startedAt),
      'metadata': operation.metadata,
    });

    return operationId;
  }

  Future<void> _updateBulkOperation(String operationId, {
    BulkOperationStatus? status,
    int? processedItems,
    int? successfulItems,
    int? failedItems,
    List<String>? errors,
    String? resultFilePath,
  }) async {
    final updateData = <String, dynamic>{};

    if (status != null) updateData['status'] = status.name;
    if (processedItems != null) updateData['processedItems'] = processedItems;
    if (successfulItems != null) updateData['successfulItems'] = successfulItems;
    if (failedItems != null) updateData['failedItems'] = failedItems;
    if (errors != null) updateData['errors'] = errors;
    if (resultFilePath != null) updateData['resultFilePath'] = resultFilePath;

    if (status == BulkOperationStatus.completed || status == BulkOperationStatus.failed) {
      updateData['completedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('bulk_operations').doc(operationId).update(updateData);
  }

  Future<void> _processBulkUserApproval(String operationId, List<String> userIds, String? adminNotes) async {
    int processed = 0;
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    for (final userId in userIds) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': 'admin',
          'adminNotes': adminNotes,
        });

        successful++;
        Logger.log('User approved: $userId');
      } catch (e) {
        failed++;
        errors.add('Failed to approve user $userId: $e');
        Logger.logError('Failed to approve user', e, StackTrace.current);
      }

      processed++;
      await _updateBulkOperation(operationId,
        processedItems: processed,
        successfulItems: successful,
        failedItems: failed,
        errors: errors,
      );
    }

    await _updateBulkOperation(operationId,
      status: BulkOperationStatus.completed,
      processedItems: processed,
      successfulItems: successful,
      failedItems: failed,
      errors: errors,
    );

    await _notificationService.createNotification(
      title: 'Bulk User Approval Completed',
      message: 'Successfully approved $successful out of ${userIds.length} users',
      type: NotificationType.success,
      priority: NotificationPriority.medium,
      category: 'bulk_operation',
      broadcastToAllAdmins: true,
    );
  }

  Future<void> _processBulkUserRejection(String operationId, List<String> userIds, String reason, String? adminNotes) async {
    int processed = 0;
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    for (final userId in userIds) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': 'admin',
          'rejectionReason': reason,
          'adminNotes': adminNotes,
        });

        successful++;
        Logger.log('User rejected: $userId');
        } catch (e) {
        failed++;
        errors.add('Failed to reject user $userId: $e');
        Logger.logError('Failed to reject user', e, StackTrace.current);
      }

      processed++;
      await _updateBulkOperation(operationId,
        processedItems: processed,
        successfulItems: successful,
        failedItems: failed,
        errors: errors,
      );
    }

    await _updateBulkOperation(operationId,
      status: BulkOperationStatus.completed,
      processedItems: processed,
      successfulItems: successful,
      failedItems: failed,
        errors: errors,
    );
  }

  Future<void> _processBulkContentApproval(String operationId, List<String> contentIds, String? adminNotes) async {
    int processed = 0;
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    for (final contentId in contentIds) {
      try {
        await _firestore.collection('content_reports').doc(contentId).update({
          'status': 'approved',
          'moderatedAt': FieldValue.serverTimestamp(),
          'moderatedBy': 'admin',
          'adminNotes': adminNotes,
        });

        successful++;
        Logger.log('Content approved: $contentId');
      } catch (e) {
        failed++;
        errors.add('Failed to approve content $contentId: $e');
        Logger.logError('Failed to approve content', e, StackTrace.current);
      }

      processed++;
      await _updateBulkOperation(operationId,
        processedItems: processed,
        successfulItems: successful,
        failedItems: failed,
        errors: errors,
      );
    }

    await _updateBulkOperation(operationId,
      status: BulkOperationStatus.completed,
      processedItems: processed,
      successfulItems: successful,
      failedItems: failed,
      errors: errors,
    );
  }

  Future<void> _processBulkContentRejection(String operationId, List<String> contentIds, String reason, String? adminNotes) async {
    int processed = 0;
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    for (final contentId in contentIds) {
      try {
        await _firestore.collection('content_reports').doc(contentId).update({
          'status': 'rejected',
          'moderatedAt': FieldValue.serverTimestamp(),
          'moderatedBy': 'admin',
          'moderationReason': reason,
          'adminNotes': adminNotes,
        });

        successful++;
        Logger.log('Content rejected: $contentId');
      } catch (e) {
        failed++;
        errors.add('Failed to reject content $contentId: $e');
        Logger.logError('Failed to reject content', e, StackTrace.current);
      }

      processed++;
      await _updateBulkOperation(operationId,
        processedItems: processed,
        successfulItems: successful,
        failedItems: failed,
        errors: errors,
      );
    }

    await _updateBulkOperation(operationId,
      status: BulkOperationStatus.completed,
      processedItems: processed,
      successfulItems: successful,
      failedItems: failed,
      errors: errors,
    );
  }

  Future<void> _processUserDataExport(String operationId, Query query) async {
    try {
      await _updateBulkOperation(operationId, status: BulkOperationStatus.processing);

      final snapshot = await query.get();
      final csvData = <List<dynamic>>[];

      // Header row
      csvData.add(['User ID', 'Email', 'Display Name', 'Phone', 'Status', 'Created At']);

      int processed = 0;
      int successful = 0;

      for (var doc in snapshot.docs) {
        try {
          final userData = doc.data() as Map<String, dynamic>;
          final row = <dynamic>[];

          row.add(doc.id);
          row.add(userData['email'] ?? '');
          row.add(userData['displayName'] ?? '');
          row.add(userData['phone'] ?? '');
          row.add(userData['status'] ?? '');
          row.add((userData['createdAt'] as Timestamp?)?.toDate().toString() ?? '');

          csvData.add(row);
          successful++;
        } catch (e) {
          Logger.logError('Failed to process user data for export', e, StackTrace.current);
        }

        processed++;
        await _updateBulkOperation(operationId,
          processedItems: processed,
          successfulItems: successful,
        );
      }

      // Generate CSV file
      final csvString = const ListToCsvConverter().convert(csvData);
      final fileName = 'users_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = await _saveCsvFile(csvString, fileName);

      await _updateBulkOperation(operationId,
        status: BulkOperationStatus.completed,
        processedItems: processed,
        successfulItems: successful,
        resultFilePath: filePath,
      );

    } catch (e) {
      Logger.logError('Failed to export user data', e, StackTrace.current);
      await _updateBulkOperation(operationId,
        status: BulkOperationStatus.failed,
        errors: ['Export failed: $e'],
      );
    }
  }

  Future<String> _saveCsvFile(String csvData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csvData);
      return filePath;
    } catch (e) {
      Logger.logError('Failed to save CSV file', e, StackTrace.current);
      throw e;
    }
  }

  Future<void> shareFile(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(filePath, name: fileName),
        ], text: 'Bulk operation export: $fileName');
      }
    } catch (e) {
      Logger.logError('Failed to share file', e, StackTrace.current);
    }
  }

  // Get active operations
  Stream<List<BulkOperationResult>> getActiveOperations() {
    return _firestore
        .collection('bulk_operations')
        .where('status', whereIn: ['pending', 'processing'])
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BulkOperationResult(
                  id: doc.id,
                  type: BulkOperationType.values.firstWhere(
                    (e) => e.name == doc.data()['type'],
                    orElse: () => BulkOperationType.userManagement,
                  ),
                  status: BulkOperationStatus.values.firstWhere(
                    (e) => e.name == doc.data()['status'],
                    orElse: () => BulkOperationStatus.pending,
                  ),
                  totalItems: doc.data()['totalItems'] ?? 0,
                  processedItems: doc.data()['processedItems'] ?? 0,
                  successfulItems: doc.data()['successfulItems'] ?? 0,
                  failedItems: doc.data()['failedItems'] ?? 0,
                  errors: List<String>.from(doc.data()['errors'] ?? []),
                  startedAt: (doc.data()['startedAt'] as Timestamp).toDate(),
                  completedAt: doc.data()['completedAt'] != null
                      ? (doc.data()['completedAt'] as Timestamp).toDate()
                      : null,
                  resultFilePath: doc.data()['resultFilePath'],
                  metadata: doc.data()['metadata'],
                ))
            .toList());
  }

  void dispose() {
    _operationProgressController.close();
    Logger.log('Bulk operations service disposed');
  }
}