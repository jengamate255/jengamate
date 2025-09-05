import 'package:cloud_firestore/cloud_firestore.dart';

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
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'messageType': messageType,
      'timestamp': Timestamp.fromDate(timestamp),
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
}
