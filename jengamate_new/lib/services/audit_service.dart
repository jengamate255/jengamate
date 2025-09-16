import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/utils/logger.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'audit_logs';

  Future<void> logEvent(AuditLogModel log, {Map<String, dynamic>? oldData, Map<String, dynamic>? newData}) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();
      String details = log.details;
      Map<String, dynamic> metadata = log.metadata ?? {};

      if (oldData != null && newData != null) {
        final changes = <String, dynamic>{};
        newData.forEach((key, newValue) {
          final oldValue = oldData[key];
          if (oldValue.toString() != newValue.toString()) { // Simple comparison, can be enhanced
            changes[key] = {'old': oldValue, 'new': newValue};
          }
        });

        if (changes.isNotEmpty) {
          details += ' Changes: ';
          changes.forEach((key, value) {
            details += ' $key: ${value['old']} -> ${value['new']};';
          });
          metadata['changes'] = changes;
        }
      }

      final auditLog = log.copyWith(uid: docRef.id, details: details, metadata: metadata); // Ensure UID, details, and metadata are set
      await docRef.set(auditLog.toMap());
      Logger.log('Audit log created: ${auditLog.action} - ${auditLog.targetType}:${auditLog.targetId}');
    } catch (e, s) {
      Logger.logError('Error creating audit log', e, s);
      rethrow;
    }
  }

  Stream<List<AuditLogModel>> streamAuditLogs({int limit = 50}) {
    return _firestore
        .collection(_collectionName)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLogModel.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id))
            .toList());
  }

  Future<List<AuditLogModel>> getAuditLogs({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => AuditLogModel.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id))
          .toList();
    } catch (e, s) {
      Logger.logError('Error getting audit logs', e, s);
      rethrow;
    }
  }
}
