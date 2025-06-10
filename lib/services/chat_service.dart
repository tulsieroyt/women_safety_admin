import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _adminChatsCollection =
      _firestore.collection('admin_chats');

  // Get all chat conversations
  static Stream<List<DocumentSnapshot>> getAllChats() {
    return _adminChatsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Get messages for a specific chat
  static Stream<QuerySnapshot> getChatMessages(String userId) {
    return _adminChatsCollection
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get latest message for a chat
  static Future<QuerySnapshot> getLatestMessage(String userId) {
    return _adminChatsCollection
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
  }

  // Send a message
  static Future<void> sendMessage({
    required String userId,
    required String message,
    required String senderId,
    required String receiverId,
    String messageType = 'text',
  }) async {
    try {
      // Reference to the admin chat document and messages subcollection
      final chatRef = _adminChatsCollection.doc(userId);
      final messagesRef = chatRef.collection('messages');

      final timestamp = DateTime.now();

      // Create the chat message
      final chatMessage = {
        'message': message,
        'messageType': messageType,
        'senderId': senderId,
        'receiverId': receiverId,
        'isRead': false,
        'timestamp': timestamp,
      };

      print('Chat message: $chatMessage');

      // Add the message to the messages subcollection
      final doc = await messagesRef.add(chatMessage);
      await messagesRef.doc(doc.id).update({'id': doc.id});

      // Update the main chat document with the last message info
      await chatRef.set({
        'lastMessage': message,
        'lastMessageType': messageType,
        'lastMessageTimestamp': timestamp,
        'lastMessageSenderId': senderId,
        'unreadCount': FieldValue.increment(receiverId == 'admin' ? 1 : 0),
        'updatedAt': timestamp,
        'userId': userId,
      }, SetOptions(merge: true));

      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String userId) async {
    try {
      final chatRef = _adminChatsCollection.doc(userId);

      // Update unread messages in messages subcollection
      final messagesRef = chatRef
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('receiverId', isEqualTo: 'admin');

      final unreadMessages = await messagesRef.get();

      // Use a batch write for better performance
      final batch = _firestore.batch();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Reset unread count in main chat document
      batch.update(chatRef, {
        'unreadCount': 0,
        'updatedAt': DateTime.now(),
      });

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }
}
