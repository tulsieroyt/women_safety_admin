import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String userId;
  final String lastMessage;
  final String lastMessageType;
  final String lastMessageSenderId;
  final DateTime lastMessageTimestamp;
  final int unreadCount;
  final DateTime updatedAt;

  ChatConversation({
    required this.userId,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageSenderId,
    required this.lastMessageTimestamp,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      userId: map['userId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: map['lastMessageType'] ?? 'text',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTimestamp: map['lastMessageTimestamp'] != null
          ? (map['lastMessageTimestamp'] as Timestamp).toDate()
          : DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTimestamp': lastMessageTimestamp,
      'unreadCount': unreadCount,
      'updatedAt': updatedAt,
    };
  }
}
