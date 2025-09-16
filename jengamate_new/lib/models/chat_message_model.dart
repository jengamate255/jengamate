// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class ChatMessage {
  final String uid;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;
  final String messageType; // 'text', 'image', 'file', 'system'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.uid,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.timestamp,
    required this.isRead,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      uid: map['uid'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      messageType: map['messageType'] ?? 'text',
      timestamp: (map['timestamp'] is String)
          ? DateTime.parse(map['timestamp'])
          : _parseOptionalDateTime(map['timestamp']) ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory ChatMessage.fromFirestore(Map<String, dynamic> docData, {required String docId}) {
    return ChatMessage(
      uid: docId,
      chatRoomId: docData['chatRoomId'] ?? '',
      senderId: docData['senderId'] ?? '',
      senderName: docData['senderName'] ?? '',
      content: docData['content'] ?? '',
      messageType: docData['messageType'] ?? 'text',
      timestamp: (docData['timestamp'] is String)
          ? DateTime.parse(docData['timestamp'])
          : _parseOptionalDateTime(docData['timestamp']) ?? DateTime.now(),
      isRead: docData['isRead'] ?? false,
      metadata: docData['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'messageType': messageType,
      'timestamp': timestamp.toIso8601String(), // Convert DateTime to ISO 8601 string
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  ChatMessage copyWith({
    String? uid,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? content,
    String? messageType,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      uid: uid ?? this.uid,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
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
