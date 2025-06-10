import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String message;
  final String messageType;
  final String senderId;
  final String receiverId;
  final bool isRead;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.message,
    required this.messageType,
    required this.senderId,
    required this.receiverId,
    required this.isRead,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      message: map['message'] ?? '',
      messageType: map['messageType'] ?? 'text',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'messageType': messageType,
      'senderId': senderId,
      'receiverId': receiverId,
      'isRead': isRead,
      'timestamp': timestamp,
    };
  }

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle timestamp safely
    DateTime timestamp;
    try {
      timestamp = data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now();
    } catch (e) {
      timestamp = DateTime.now();
    }

    return Message(
      id: doc.id,
      message: data['message'] ?? '',
      messageType: data['messageType'] ?? 'text',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      isRead: data['isRead'] ?? false,
      timestamp: timestamp,
    );
  }
}

class Conversation {
  final String userId;
  final String userName;
  final String userImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool unread;
  final List<Message> messages;

  Conversation({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unread,
    required this.messages,
  });

  static Future<List<Conversation>> getConversations() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final conversations = <Conversation>[];

    try {
      // Get all admin_chats documents
      final QuerySnapshot chatsSnapshot =
          await firestore.collection('admin_chats').get();

      for (var chatDoc in chatsSnapshot.docs) {
        final userId = chatDoc.id;

        // Get user details
        final userDoc = await firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() ?? {};

        // Get messages subcollection
        final messagesSnapshot = await chatDoc.reference
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .get();

        final messages = messagesSnapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList();

        if (messages.isNotEmpty) {
          conversations.add(
            Conversation(
              userId: userId,
              userName: userData['name'] ?? 'Unknown User',
              userImage:
                  userData['profileImage'] ?? 'https://via.placeholder.com/150',
              lastMessage: messages.first.message,
              lastMessageTime: messages.first.timestamp,
              unread: messages
                  .any((msg) => !msg.isRead && msg.receiverId == 'admin'),
              messages: messages,
            ),
          );
        }
      }

      // Sort conversations by last message time
      conversations
          .sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return conversations;
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }
}
