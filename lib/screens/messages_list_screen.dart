import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import 'message_details_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: ChatService.getAllChats(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (chatSnapshot.hasError) {
            return Center(
              child: Text('Error: ${chatSnapshot.error}'),
            );
          }

          final chats = chatSnapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'No messages yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Sort chats by lastMessageTimestamp in ascending order
          chats.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['lastMessageTimestamp'] as Timestamp?;
            final bTimestamp = bData['lastMessageTimestamp'] as Timestamp?;
            
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            
            return bTimestamp.compareTo(aTimestamp);
          });

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final userId = chatData['userId'] ?? chatDoc.id;

              return StreamBuilder<User?>(
                stream: UserService.getUserById(userId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final user = userSnapshot.data!;
                  final lastMessageTime = chatData['lastMessageTimestamp'] !=
                          null
                      ? (chatData['lastMessageTimestamp'] as Timestamp).toDate()
                      : DateTime.now();

                  final conversation = Conversation(
                    userId: userId,
                    userName: user.name ?? 'Unknown User',
                    userImage:
                        user.profileImage ?? 'https://via.placeholder.com/150',
                    lastMessage: chatData['lastMessage'] ?? '',
                    lastMessageTime: lastMessageTime,
                    unread: (chatData['unreadCount'] ?? 0) > 0,
                    messages: [],
                  );

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageDetailsScreen(
                            conversation: conversation,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(conversation.userImage),
                      radius: 25,
                      onBackgroundImageError: (_, __) {
                        // Handle error loading image
                      },
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(conversation.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                conversation.unread ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: conversation.unread
                                  ? Colors.black87
                                  : Colors.grey,
                              fontWeight: conversation.unread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (conversation.unread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${chatData['unreadCount']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
