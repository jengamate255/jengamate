import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:jengamate/models/enums/message_enums.dart';
import 'package:jengamate/models/message_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/widgets/avatar_widget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ChatConversationScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String otherUserId;
  final String currentUserId; // The ID of the currently logged-in user

  const ChatConversationScreen({
    Key? key,
    required this.chatRoomId,
    required this.otherUserName,
    required this.otherUserId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  UserModel? _chatPartner;

  @override
  void initState() {
    super.initState();
    _fetchChatPartner();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchChatPartner() async {
    if (widget.otherUserId.isNotEmpty) {
      _chatPartner = await _dbService.getUser(widget.otherUserId);
      setState(() {}); // Trigger rebuild to display chat partner name
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = context.read<UserModel?>();
    if (_messageController.text.trim().isEmpty || currentUser == null) {
      return;
    }

    final message = Message(
      id: '',
      chatId: widget.chatRoomId,
      senderId: currentUser.uid,
      receiverId: widget.otherUserId,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    await _dbService.addMessage(message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Please log in to chat.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AvatarWidget(
              photoUrl: _chatPartner?.photoUrl,
              displayName: _chatPartner?.displayName ?? widget.otherUserName,
              radius: 16,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _dbService.streamMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Say hello!'));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue.shade200 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(message.content, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(message.timestamp.toLocal()),
                              style: TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 