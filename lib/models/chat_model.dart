import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
  link,
  location,
  voice, // Add voice type
}

extension MessageTypeExtension on MessageType {
  IconData get icon {
    switch (this) {
      case MessageType.text:
        return Icons.message;
      case MessageType.image:
        return Icons.image;
      case MessageType.file:
        return Icons.attach_file;
      case MessageType.link:
        return Icons.link;
      case MessageType.location:
        return Icons.location_on;
      case MessageType.voice:
        return Icons.mic;
    }
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? mediaUrl;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    this.mediaUrl,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    final timestamp = map['timestamp'] as Timestamp?;
    final DateTime messageTime = timestamp?.toDate() ?? DateTime.now();

    print('Parsing timestamp: $messageTime'); // Debug print

    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      timestamp: messageTime,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: map['mediaUrl'],
      isRead: map['isRead'] ?? false, // Make sure this is being set
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(),
      'mediaUrl': mediaUrl,
      'isRead': isRead,
    };
  }
}

class ChatConversation {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;

  ChatConversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    DateTime? lastMessageTime, // Make parameter optional
    required this.unreadCount,
  }) : this.lastMessageTime =
            lastMessageTime ?? DateTime.now(); // Provide default value

  factory ChatConversation.fromMap(Map<String, dynamic> map, String id) {
    return ChatConversation(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)
          ?.toDate(), // Handle null Timestamp
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
    };
  }
}
