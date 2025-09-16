import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/document_verification.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/services/audit_service.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/models/admin_user_activity.dart'; // Added import for AdminUserActivity
import 'package:jengamate/services/offline_cache_service.dart'; // Added

class DocumentVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();
  final OfflineCacheService _cacheService = OfflineCacheService(); // Added
  static const String _collectionName = 'document_verifications';

  // Method to submit a new document for verification
  Future<void> submitDocument(DocumentVerification document) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();
      final documentToSubmit = document.copyWith(id: docRef.id); // Ensure ID is set
      await docRef.set(documentToSubmit.toMap());

      _auditService.logEvent(AuditLogModel(
        uid: '',
        actorId: documentToSubmit.userId,
        actorName: documentToSubmit.userName, // Assuming userName is available
        action: 'DOCUMENT_SUBMITTED',
        targetType: 'DOCUMENT_VERIFICATION',
        targetId: documentToSubmit.id,
        targetName: documentToSubmit.documentType,
        timestamp: DateTime.now(),
        details: 'Document ${documentToSubmit.documentType} submitted by ${documentToSubmit.userName}',
        metadata: {'status': documentToSubmit.status, 'documentUrl': documentToSubmit.documentUrl},
      ));

      Logger.log('Document submitted for verification: ${documentToSubmit.id}');
    } catch (e, s) {
      Logger.logError('Error submitting document for verification', e, s);
      rethrow;
    }
  }

  // Method to update the status of a document
  Future<void> updateDocumentStatus({
    required String documentId,
    required String status,
    String? reviewedBy,
    String? rejectionReason,
    required String actorId,
    required String actorName,
  }) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(documentId);
      final oldDocumentSnapshot = await docRef.get();
      final oldDocument = oldDocumentSnapshot.exists ? DocumentVerification.fromFirestore(oldDocumentSnapshot.data() as Map<String, dynamic>, docId: oldDocumentSnapshot.id) : null;

      if (oldDocument == null) {
        throw Exception('Document with ID $documentId not found.');
      }

      final Map<String, dynamic> updates = {
        'status': status,
        'reviewedAt': Timestamp.now(),
        'reviewedBy': reviewedBy,
        'rejectionReason': rejectionReason,
      };

      await docRef.update(updates);

      _auditService.logEvent(AuditLogModel(
        uid: '',
        actorId: actorId,
        actorName: actorName,
        action: 'DOCUMENT_STATUS_UPDATE',
        targetType: 'DOCUMENT_VERIFICATION',
        targetId: documentId,
        targetName: oldDocument.documentType,
        timestamp: DateTime.now(),
        details: 'Document ${oldDocument.documentType} status updated from ${oldDocument.status} to $status',
        metadata: {'oldStatus': oldDocument.status, 'newStatus': status, 'reviewedBy': reviewedBy, 'rejectionReason': rejectionReason},
      ));

      Logger.log('Document $documentId status updated to $status');
    } catch (e, s) {
      Logger.logError('Error updating document status', e, s);
      rethrow;
    }
  }

  // Stream to get all pending documents for review
  Stream<List<DocumentVerification>> streamPendingDocuments() {
    // Try to get from cache first
    final cachedData = _cacheService.getListData('pending_documents');
    if (cachedData != null) {
      Logger.log('Pending documents retrieved from cache.');
      return Stream.value(cachedData.map<DocumentVerification>((data) => DocumentVerification.fromMap(data, data['id'] ?? 'unknown')).toList());
    }

    // If not in cache, fetch from Firestore
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final documents = snapshot.docs
          .map((doc) => DocumentVerification.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id))
          .toList();
      // Cache the fetched data
      _cacheService.saveListData('pending_documents', documents.map((doc) => doc.toMap()).toList());
      Logger.log('Pending documents fetched from network and cached.');
      return documents;
    });
  }

  // Stream to get all documents (for admin overview)
  Stream<List<DocumentVerification>> streamAllDocuments() {
    return _firestore
        .collection(_collectionName)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final documents = snapshot.docs
          .map((doc) => DocumentVerification.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id))
          .toList();
      // Cache the list of all documents
      _cacheService.saveListData('all_documents', documents.map((doc) => doc.toMap()).toList());
      return documents;
    });
  }

  Future<DocumentVerification?> getDocumentById(String documentId) async {
    final cacheKey = 'document_$documentId';
    try {
      // 1. Try to get from cache first
      final cachedData = _cacheService.getData(cacheKey);
      if (cachedData != null) {
        Logger.log('Document $documentId retrieved from cache.');
        return DocumentVerification.fromMap(cachedData, documentId);
      }

      // 2. If not in cache, fetch from Firestore
      final doc = await _firestore.collection(_collectionName).doc(documentId).get();
      if (doc.exists) {
        final document = DocumentVerification.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id);
        // 3. Cache the fetched data
        await _cacheService.saveData(cacheKey, document.toMap());
        Logger.log('Document $documentId fetched from network and cached.');
        return document;
      }
      return null;
    } catch (e, s) {
      Logger.logError('Error getting document by ID', e, s);
      rethrow; // Rethrow to maintain existing error handling
    }
  }

  // Optional: Automated approval logic (can be expanded)
  Future<void> autoProcessDocument(String documentId) async {
    try {
      Logger.log('Attempting to auto-process document: $documentId');
      final document = await getDocumentById(documentId);
      if (document == null || document.status != 'pending') {
        Logger.log('Document $documentId not found or not pending.');
        return;
      }

      // Example automated logic:
      // If document type is 'national_id' and a certain external check passes (simulated)
      if (document.documentType == 'national_id') {
        // Simulate an external check or AI verification
        final bool externalCheckPassed = await _simulateExternalVerification(documentId);

        if (externalCheckPassed) {
          await updateDocumentStatus(
            documentId: document.id,
            status: 'verified',
            reviewedBy: 'Automated System',
            actorId: 'system',
            actorName: 'Automated System',
          );
          Logger.log('Document $documentId auto-verified.');
        } else {
          await updateDocumentStatus(
            documentId: document.id,
            status: 'rejected',
            reviewedBy: 'Automated System',
            rejectionReason: 'Failed automated external check',
            actorId: 'system',
            actorName: 'Automated System',
          );
          Logger.log('Document $documentId auto-rejected due to external check failure.');
        }
      } else {
        Logger.log('Document type ${document.documentType} not configured for automated processing.');
      }
    } catch (e, s) {
      Logger.logError('Error during auto-processing document $documentId', e, s);
    }
  }

  // Simulate an external verification service
  Future<bool> _simulateExternalVerification(String documentId) async {
    // In a real application, this would call an external API or AI service.
    // For demonstration, we'll randomly return true/false.
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call delay
    return DateTime.now().second % 2 == 0; // 50% chance of passing
  }

  // Method to get document analytics (total, pending, verified, rejected)
  Stream<Map<String, dynamic>> getDocumentAnalytics() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      int totalDocuments = snapshot.docs.length;
      int pendingDocuments = snapshot.docs.where((doc) => doc['status'] == 'pending').length;
      int verifiedDocuments = snapshot.docs.where((doc) => doc['status'] == 'verified').length;
      int rejectedDocuments = snapshot.docs.where((doc) => doc['status'] == 'rejected').length;

      return {
        'totalDocuments': totalDocuments,
        'pendingDocuments': pendingDocuments,
        'verifiedDocuments': verifiedDocuments,
        'rejectedDocuments': rejectedDocuments,
      };
    });
  }

  // Method to export documents to CSV (placeholder)
  Future<String> exportDocumentsToCSV() async {
    // In a real application, you would fetch all documents and format them as CSV.
    // For now, this is a placeholder.
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return 'id,userId,documentType,status\n1,user123,license,pending';
  }

  // Stream to get user activities for a specific user
  Stream<List<AdminUserActivity>> streamUserActivities({required String userId, int limit = 10}) {
    return _firestore
        .collection('admin_user_activities') // Assuming a collection for admin user activities
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map<AdminUserActivity>((doc) => AdminUserActivity.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id))
            .toList());
  }
}
