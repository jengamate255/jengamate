import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/models/chat_room_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/widgets/avatar_widget.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/components/jm_skeleton.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Please log in to see your chats.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _dbService.streamChatRoomsForUser(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AdaptivePadding(
              child: ListView.separated(
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.md),
                itemBuilder: (context, index) => const JMCard(
                  child: Row(
                    children: [
                      CircleAvatar(radius: 20),
                      SizedBox(width: JMSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            JMSkeleton(height: 16, width: 160),
                            SizedBox(height: JMSpacing.xs),
                            JMSkeleton(height: 14, width: 220),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const AdaptivePadding(
              child: Center(
                child: Text(
                  'No conversations yet.\nStart a chat from a product or inquiry.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final chatRooms = snapshot.data!;

          return AdaptivePadding(
            child: ListView.separated(
              itemCount: chatRooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.sm),
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                final otherUserId = chatRoom.participants
                    .firstWhere((id) => id != currentUser.uid, orElse: () => '');

                if (otherUserId.isEmpty) {
                  return const SizedBox.shrink(); // Or some error widget
                }

                return FutureBuilder<UserModel?>(
                  future: _dbService.getUser(otherUserId),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const JMCard(
                        child: Row(
                          children: [
                            CircleAvatar(radius: 20),
                            SizedBox(width: JMSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  JMSkeleton(height: 16, width: 160),
                                  SizedBox(height: JMSpacing.xs),
                                  JMSkeleton(height: 14, width: 220),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final otherUser = userSnapshot.data!;
                    final lastMessageTime = chatRoom.lastMessageTimestamp ?? chatRoom.createdAt;

                    return ListTile(
                      leading: AvatarWidget(
                        photoUrl: otherUser.photoUrl,
                        displayName: otherUser.displayName,
                        radius: 20,
                      ),
                      title: Text(otherUser.displayName),
                      subtitle: Text(
                        chatRoom.lastMessage ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        DateFormat('hh:mm a').format(lastMessageTime),
                      ),
                      onTap: () {
                        context.go(
                          AppRouteBuilders.chatConversationPath(chatRoom.id),
                          extra: {
                            'chatRoomId': chatRoom.id,
                            'otherUserName': otherUser.displayName,
                            'otherUserId': otherUser.uid,
                            'currentUserId': currentUser.uid,
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}