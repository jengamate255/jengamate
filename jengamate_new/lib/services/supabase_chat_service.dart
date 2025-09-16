import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/models/chat_room_model.dart';
import 'package:jengamate/models/chat_message_model.dart';

class SupabaseChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates a new chat room and adds participants.
  Future<ChatRoom> createChatRoom(List<String> participantIds) async {
    try {
      final response = await _supabase.from('chat_rooms').insert({
        'participants': participantIds,
        'created_at': DateTime.now().toIso8601String(),
        'last_message_at': DateTime.now().toIso8601String(),
      }).select().single();

      final chatRoom = ChatRoom.fromMap(response);

      // Add participants to the chat_participants table
      await _addParticipantsToChatRoom(chatRoom.uid, participantIds);

      Logger.log('Supabase chat room created: ${chatRoom.uid}');
      return chatRoom;
    } catch (e, st) {
      Logger.logError('Error creating Supabase chat room', e, st);
      rethrow;
    }
  }

  /// Adds participants to the `chat_participants` table.
  Future<void> _addParticipantsToChatRoom(String chatRoomId, List<String> participantIds) async {
    final List<Map<String, dynamic>> participantsData = participantIds.map((userId) => {
      'room_id': chatRoomId,
      'user_id': userId,
      'joined_at': DateTime.now().toIso8601String(),
    }).toList();

    try {
      await _supabase.from('chat_participants').insert(participantsData);
      Logger.log('Supabase chat participants added for room: $chatRoomId');
    } catch (e, st) {
      Logger.logError('Error adding Supabase chat participants', e, st);
      rethrow;
    }
  }

  /// Streams chat rooms for a given user.
  Stream<List<ChatRoom>> streamChatRoomsForUser(String userId) {
    return _supabase
        .from('chat_participants')
        .stream(primaryKey: ['room_id', 'user_id'])
        .eq('user_id', userId)
        .order('joined_at', ascending: false) // Order by latest joined room
        .asyncMap((List<Map<String, dynamic>> participantDataList) async { // Changed map to asyncMap
          final List<String> roomIds = participantDataList.map((data) => data['room_id'] as String).toList();
          if (roomIds.isEmpty) return <ChatRoom>[]; // Explicitly return List<ChatRoom>

          final List<Map<String, dynamic>> roomDataList = await _supabase
              .from('chat_rooms')
              .select()
              .inFilter('id', roomIds) // Changed .in_ to .inFilter
              .order('last_message_at', ascending: false);
              // Removed .execute() here

          return roomDataList.map((data) => ChatRoom.fromMap(data)).toList().cast<ChatRoom>(); // Explicitly cast to List<ChatRoom>
        }).asBroadcastStream();
  }

  /// Streams messages for a given chat room.
  Stream<List<ChatMessage>> streamMessages(String chatRoomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', chatRoomId)
        .order('timestamp', ascending: false)
        .map((data) => data.map((item) => ChatMessage.fromMap(item)).toList());
  }

  /// Adds a message to a chat room.
  Future<void> addMessage(ChatMessage message) async {
    try {
      await _supabase.from('messages').insert({
        'room_id': message.chatRoomId,
        'sender_id': message.senderId,
        'sender_name': message.senderName, // Assuming senderName is available in ChatMessage
        'content': message.content,
        'message_type': message.messageType,
        'timestamp': message.timestamp.toIso8601String(),
        'is_read': message.isRead,
      });

      // Update last_message and last_message_at in chat_rooms
      await _supabase.from('chat_rooms').update({
        'last_message': message.content,
        'last_message_at': message.timestamp.toIso8601String(),
      }).eq('id', message.chatRoomId);

      Logger.log('Supabase chat message added to room: ${message.chatRoomId}');
    } catch (e, st) {
      Logger.logError('Error adding Supabase chat message', e, st);
      rethrow;
    }
  }

  /// Finds an existing chat room between two users for a specific product, or creates one if it doesn't exist.
  Future<ChatRoom?> findOrCreateChatRoom({
    required String userId,
    required String otherUserId,
    String? productId, // Optional product ID to associate with the chat
  }) async {
    try {
      // Ensure consistent ordering of participants for query
      final participants = [userId, otherUserId]..sort();

      // Try to find an existing chat room
      PostgrestFilterBuilder queryBuilder = _supabase
          .from('chat_rooms')
          .select('*') // Explicitly select all columns
          .contains('participants', participants);

      if (productId != null) {
        queryBuilder = queryBuilder.eq('product_id', productId);
      }

      final List<Map<String, dynamic>> existingRooms = await queryBuilder.limit(1); // Removed .execute()

      if (existingRooms.isNotEmpty) {
        Logger.log('Existing chat room found: ${existingRooms.first['id']}');
        return ChatRoom.fromMap(existingRooms.first);
      }

      // If no room found, create a new one
      final newChatRoom = await createChatRoom(participants);
      Logger.log('New chat room created: ${newChatRoom.uid}');

      // If productId is provided, update the new chat room with it
      if (productId != null) {
        await _supabase.from('chat_rooms').update({
          'product_id': productId,
        }).eq('id', newChatRoom.uid);
        return newChatRoom.copyWith(productId: productId);
      }

      return newChatRoom;
    } catch (e, st) {
      Logger.logError('Error finding or creating Supabase chat room', e, st);
      rethrow;
    }
  }
}
