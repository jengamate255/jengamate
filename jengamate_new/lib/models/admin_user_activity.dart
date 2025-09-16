// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class AdminUserActivity {
  final String id;
  final String userId;
  final String action;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic>? metadata;

  AdminUserActivity({
    required this.id,
    required this.userId,
    required this.action,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
    this.metadata,
  });

  factory AdminUserActivity.fromMap(Map<String, dynamic> map) {
    return AdminUserActivity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      action: map['action'] ?? '',
      timestamp: map['timestamp'] is DateTime
          ? map['timestamp']
          : DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      ipAddress: map['ipAddress'] ?? '',
      userAgent: map['userAgent'] ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory AdminUserActivity.fromFirestore(Map<String, dynamic> docData, {required String docId}) {
    return AdminUserActivity(
      id: docId,
      userId: docData['userId'] ?? '',
      action: docData['action'] ?? '',
      timestamp: (docData['timestamp'] is String) ? DateTime.parse(docData['timestamp']) : _parseOptionalDateTime(docData['timestamp']) ?? DateTime.now(),
      ipAddress: docData['ipAddress'] ?? '',
      userAgent: docData['userAgent'] ?? '',
      metadata: docData['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(), // Convert DateTime to ISO 8601 string
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'metadata': metadata,
    };
  }

  // Helper method to parse timestamps safely from Firestore
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is DateTime) {
      return value;
    }
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return value.toDate(); // This is the key fix!
      } catch (e) {
        print('Error converting Timestamp to DateTime: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Helper method to parse optional timestamps safely from Firestore
  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is DateTime) {
      return value;
    }
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return value.toDate();
      } catch (e) {
        print('Error converting Timestamp to DateTime: $e');
        return null;
      }
    }
    return null;
  }
}
