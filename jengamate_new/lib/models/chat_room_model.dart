// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class ChatRoom {
  final String uid;
  final List<String> participants;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? productId; // Add this line

  ChatRoom({
    required this.uid,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    this.lastMessageAt,
    this.productId,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      uid: map['id'] as String,
      participants: List<String>.from(map['participants']),
      lastMessage: map['last_message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      productId: map['product_id'] as String?,
    );
  }

  factory ChatRoom.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return ChatRoom.fromMap({
      ...data,
      'id': docId,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'participants': participants,
      'last_message': lastMessage,
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'product_id': productId,
    };
  }

  // Add copyWith method
  ChatRoom copyWith({
    String? uid,
    List<String>? participants,
    String? lastMessage,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? productId,
  }) {
    return ChatRoom(
      uid: uid ?? this.uid,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      productId: productId ?? this.productId,
    );
  }
}
