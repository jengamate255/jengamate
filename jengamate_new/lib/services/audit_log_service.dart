import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/audit_log_model.dart';

class AuditLogService {
  final FirebaseFirestore _firestore;

  AuditLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<AuditLogModel> get _auditLogsCollection =>
      _firestore.collection('audit_logs').withConverter<AuditLogModel>(
            fromFirestore: (snapshot, _) =>
                AuditLogModel.fromMap(snapshot.data()!),
            toFirestore: (log, _) => log.toMap(),
          );

  Future<void> logAction({
    required String actorId,
    required String actorName,
    required String action,
    required String targetType,
    required String targetId,
    required String targetName,
    required String details,
    Map<String, dynamic>? metadata,
  }) async {
    final logEntry = AuditLogModel(
      uid: _firestore.collection('audit_logs').doc().id,
      actorId: actorId,
      actorName: actorName,
      action: action,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      timestamp: DateTime.now(),
      details: details,
      metadata: metadata,
    );

    await _auditLogsCollection.doc(logEntry.uid).set(logEntry);
  }

  Stream<List<AuditLogModel>> getAuditLogs({int limit = 50}) {
    return _auditLogsCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<AuditLogModel>> getAuditLogsForTarget(
    String targetType,
    String targetId, {
    int limit = 50,
  }) async {
    final snapshot = await _auditLogsCollection
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<AuditLogModel>> getAuditLogsForUser(
    String userId, {
    int limit = 50,
  }) async {
    final snapshot = await _auditLogsCollection
        .where('actorId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<AuditLogModel>> streamAuditLogs(String userId,
      {int limit = 100}) {
    Query<AuditLogModel> query = _auditLogsCollection
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (userId.isNotEmpty) {
      query = query.where('actorId', isEqualTo: userId);
    }
    return query.snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> deleteOldLogs(Duration retentionPeriod) async {
    final cutoffDate = DateTime.now().subtract(retentionPeriod);

    final snapshot = await _auditLogsCollection
        .where('timestamp', isLessThan: cutoffDate)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
