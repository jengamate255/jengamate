import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String uid;
  final String name;
  final String description;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageSender;
  final DateTime? lastMessageAt;
  final String type; // 'direct', 'group', 'support', 'order'
  final String? relatedId; // Order ID, RFQ ID, etc.
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  ChatRoom({
    required this.uid,
    required this.name,
    required this.description,
    required this.participants,
    this.lastMessage,
    this.lastMessageSender,
    this.lastMessageAt,
    required this.type,
    this.relatedId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageSender: map['lastMessageSender'],
      lastMessageAt: map['lastMessageAt'] != null
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      type: map['type'] ?? 'direct',
      relatedId: map['relatedId'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'description': description,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'type': type,
      'relatedId': relatedId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  ChatRoom copyWith({
    String? uid,
    String? name,
    String? description,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSender,
    DateTime? lastMessageAt,
    String? type,
    String? relatedId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatRoom(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Computed properties
  bool get isDirect => type == 'direct';
  bool get isGroup => type == 'group';
  bool get isSupport => type == 'support';
  bool get isOrderRelated => type == 'order';

  int get participantCount => participants.length;

  String get displayName {
    if (name.isNotEmpty) return name;
    if (isDirect && participants.length == 2) {
      return 'Direct Chat';
    }
    return 'Group Chat';
  }

  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';
    if (lastMessage!.length > 50) {
      return '${lastMessage!.substring(0, 50)}...';
    }
    return lastMessage!;
  }

  // Helper methods
  bool hasParticipant(String userId) {
    return participants.contains(userId);
  }

  bool canUserAccess(String userId) {
    return hasParticipant(userId) && isActive;
  }

  ChatRoom addParticipant(String userId) {
    if (!hasParticipant(userId)) {
      return copyWith(participants: [...participants, userId]);
    }
    return this;
  }

  ChatRoom removeParticipant(String userId) {
    return copyWith(
        participants: participants.where((id) => id != userId).toList());
  }

  ChatRoom updateLastMessage({
    required String message,
    required String senderId,
    DateTime? timestamp,
  }) {
    return copyWith(
      lastMessage: message,
      lastMessageSender: senderId,
      lastMessageAt: timestamp ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Static factory methods for common chat room types
  static ChatRoom direct({
    required String userId1,
    required String userId2,
    String? name,
  }) {
    final participants = [userId1, userId2]
      ..sort(); // Sort for consistent room ID
    return ChatRoom(
      uid: '',
      name: name ?? 'Direct Chat',
      description: 'Private conversation',
      participants: participants,
      type: 'direct',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ChatRoom group({
    required String name,
    required String description,
    required List<String> participants,
    String? relatedId,
  }) {
    return ChatRoom(
      uid: '',
      name: name,
      description: description,
      participants: participants,
      type: 'group',
      relatedId: relatedId,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ChatRoom support({
    required String userId,
    required String supportAgentId,
    String? relatedId,
  }) {
    return ChatRoom(
      uid: '',
      name: 'Support Chat',
      description: 'Customer support conversation',
      participants: [userId, supportAgentId],
      type: 'support',
      relatedId: relatedId,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ChatRoom order({
    required String orderId,
    required List<String> participants,
  }) {
    return ChatRoom(
      uid: '',
      name: 'Order #$orderId',
      description: 'Discussion about order #$orderId',
      participants: participants,
      type: 'order',
      relatedId: orderId,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Utility methods for chat room management
  static String generateRoomId(List<String> participants) {
    final sortedParticipants = List<String>.from(participants)..sort();
    return sortedParticipants.join('_');
  }

  static List<ChatRoom> filterByType(List<ChatRoom> rooms, String type) {
    return rooms.where((room) => room.type == type).toList();
  }

  static List<ChatRoom> filterByParticipant(
      List<ChatRoom> rooms, String userId) {
    return rooms.where((room) => room.hasParticipant(userId)).toList();
  }

  static List<ChatRoom> sortByLastMessage(List<ChatRoom> rooms) {
    return List<ChatRoom>.from(rooms)
      ..sort((a, b) {
        if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });
  }

  static ChatRoom? findDirectChat(
      List<ChatRoom> rooms, String userId1, String userId2) {
    return rooms.firstWhere(
      (room) =>
          room.isDirect &&
          room.participants.length == 2 &&
          room.hasParticipant(userId1) &&
          room.hasParticipant(userId2),
      orElse: () => null as ChatRoom,
    );
  }
}
