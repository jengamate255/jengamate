import 'package:flutter/material.dart';
// import 'package:jengamate/models/enums/message_enums.dart';
import 'package:jengamate/models/chat_message_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/supabase_chat_service.dart'; // Add this import
import 'package:jengamate/widgets/avatar_widget.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/product_model.dart'; // Add this import
import 'package:jengamate/ui/design_system/tokens/spacing.dart'; // Add this import
import 'package:jengamate/ui/design_system/components/jm_card.dart'; // Add this import

class ChatConversationScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String otherUserId;
  final String currentUserId; // The ID of the currently logged-in user
  final ProductModel? product;

  const ChatConversationScreen({
    Key? key,
    required this.chatRoomId,
    required this.otherUserName,
    required this.otherUserId,
    required this.currentUserId,
    this.product,
  }) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final SupabaseChatService _supabaseChatService = SupabaseChatService(); // Add this line
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

    final message = ChatMessage(
      uid: '',
      chatRoomId: widget.chatRoomId,
      senderId: currentUser.uid ?? '',
      senderName: currentUser.displayName, // Assuming senderName is available
      content: _messageController.text.trim(),
      messageType: 'text',
      timestamp: DateTime.now(),
      isRead: false,
    );

    await _supabaseChatService.addMessage(message); // Modified line
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;

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
          if (widget.product != null) _buildProductDetailsCard(widget.product!),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _supabaseChatService.streamMessages(widget.chatRoomId), // Modified line
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
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blue.shade200
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(message.content,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a')
                                  .format(message.timestamp.toLocal()),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black54),
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  heroTag: "chatConversationSend",
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

  Widget _buildProductDetailsCard(ProductModel product) {
    return JMCard(
      margin: const EdgeInsets.all(JMSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.sm),
        child: Row(
          children: [
            if (product.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(JMSpacing.xxs), // Changed JMSpacing.xs to JMSpacing.xxs
                child: Image.network(
                  product.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: JMSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: JMSpacing.xxs),
                  Text(
                    'TSH ${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
