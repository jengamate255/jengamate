import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/audit_log_model.dart';

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference<AuditLogModel> _auditLogRef;

  AuditLogService() {
    _auditLogRef = _firestore.collection('audit_logs').withConverter<AuditLogModel>(
          fromFirestore: (snapshot, _) => AuditLogModel.fromFirestore(snapshot),
          toFirestore: (log, _) => log.toFirestore(),
        );
  }

  Future<void> logAction({
    required String actorId,
    required String actorName,
    required String targetUserId,
    required String targetUserName,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    final logEntry = AuditLogModel(
      id: '', // Firestore will generate this
      actorId: actorId,
      actorName: actorName,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      action: action,
      timestamp: Timestamp.now(),
      details: details,
    );
    await _auditLogRef.add(logEntry);
  }

  Stream<List<AuditLogModel>> streamAuditLogs(String userId) {
    return _auditLogRef
        .where('targetUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
