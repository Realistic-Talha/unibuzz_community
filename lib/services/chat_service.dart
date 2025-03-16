import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/models/chat_model.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/services/image_hosting_service.dart';
import 'package:unibuzz_community/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageHostingService _imageHosting = ImageHostingService();

  User? get currentUser => AuthService().currentUser;

  Stream<List<DocumentSnapshot>> getConversations() {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final filteredDocs = <DocumentSnapshot>[];
          for (var doc in snapshot.docs) {
            final participants = List<String>.from(doc['participants']);
            final otherUserId = participants.firstWhere(
              (id) => id != currentUser.uid,
              orElse: () => '',
            );
            final isBlocked = await AuthService().isUserBlocked(otherUserId);
            if (!isBlocked) {
              filteredDocs.add(doc);
            }
          }
          return filteredDocs;
        });
  }

  Stream<List<DocumentSnapshot>> getMessages(String conversationId) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final filteredDocs = <DocumentSnapshot>[];
          for (var doc in snapshot.docs) {
            final senderId = doc['senderId'];
            final isBlocked = await AuthService().isUserBlocked(senderId);
            if (!isBlocked) {
              filteredDocs.add(doc);
            }
          }
          return filteredDocs;
        });
  }

  Future<String> createConversation(List<String> participants) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    // Check if conversation already exists
    final querySnapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (var doc in querySnapshot.docs) {
      final participantsList = List<String>.from(doc['participants']);
      if (participantsList.length == 2 &&
          participantsList.contains(participants[0])) {
        return doc.id;
      }
    }

    // Create new conversation if none exists
    final conversationRef = await _firestore.collection('conversations').add({
      'participants': [currentUser.uid, ...participants],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount': {
        currentUser.uid: 0,
        participants[0]: 0,
      },
      'metadata': {
        'created': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
      },
    });

    return conversationRef.id;
  }

  Future<String> createOrGetConversation(String otherUserId) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if conversation already exists
    final querySnapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .get();

    for (var doc in querySnapshot.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new conversation
    final docRef = await _firestore.collection('conversations').add({
      'participants': [user.uid, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': {
        user.uid: 0,
        otherUserId: 0,
      },
    });

    return docRef.id;
  }

  Future<void> sendMessage(
    String conversationId,
    String content,
    MessageType type, {
    File? mediaFile,
  }) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    // Get conversation details
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final doc = await conversationRef.get();

    if (!doc.exists) throw Exception('Conversation not found');

    // Check if the other participant is blocked
    final chatParticipants = List<String>.from(doc.data()?['participants'] ?? []);
    final otherUserId = chatParticipants.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );

    final isBlocked = await AuthService().isUserBlocked(otherUserId);
    if (isBlocked) {
      throw Exception('Cannot send message to blocked user');
    }

    String? mediaUrl;
    if (mediaFile != null) {
      mediaUrl = await _imageHosting.uploadImage(mediaFile);
    }

    final batch = _firestore.batch();
    final messageRef = conversationRef.collection('messages').doc();

    final unreadCount = Map<String, int>.from(doc.data()?['unreadCount'] ?? {});

    // Update unread count for other participants
    for (final participant in chatParticipants) {
      if (participant != currentUser.uid) {
        unreadCount[participant] = (unreadCount[participant] ?? 0) + 1;
      }
    }

    // Create message content
    final messageData = {
      'senderId': currentUser.uid,
      'content': content,
      'type': type.toString(),
      'timestamp': FieldValue.serverTimestamp(),  // Make sure this is set
      'mediaUrl': mediaUrl,
      'isRead': false,
    };

    batch.set(messageRef, messageData);

    // Set appropriate lastMessage based on message type
    String lastMessage = content;
    if (type == MessageType.image) {
      lastMessage = '📷 Image';
    } else if (type == MessageType.file) {
      lastMessage = '📎 File: $content';
    }

    batch.update(conversationRef, {
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
    });

    await batch.commit();
  }

  Future<void> markAsRead(String conversationId) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    try {
      // First update conversation unread count
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(conversationRef);
        if (!doc.exists) return;

        final unreadCount = Map<String, int>.from(doc.data()?['unreadCount'] ?? {});
        if (unreadCount[currentUser.uid] == 0) return; // Skip if already read

        unreadCount[currentUser.uid] = 0;
        transaction.update(conversationRef, {'unreadCount': unreadCount});
      });

      // Then mark messages as read in batches
      final unreadMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<String> getOtherParticipantName(List<String> participants) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return 'Unknown';

    // Find the other participant's ID directly from the provided participants list
    final otherUserId = participants.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return 'Unknown';

    try {
      final userDoc = await _firestore.collection('users').doc(otherUserId).get();
      if (!userDoc.exists) return 'Unknown';
      return userDoc.data()?['username'] ?? 'Unknown';
    } catch (e) {
      debugPrint('Error getting user name: $e');
      return 'Unknown';
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    final userDoc = await _firestore
        .collection('users')
        .doc(userId)
        .get();

    return userDoc.data();
  }

  Future<void> clearChat(String conversationId) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    // Get all messages
    final messages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();

    // Create batch
    final batch = _firestore.batch();

    // Delete all messages
    for (var message in messages.docs) {
      batch.delete(message.reference);
    }

    // Update conversation
    batch.update(
      _firestore.collection('conversations').doc(conversationId),
      {
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {
          currentUser.uid: 0,
        },
      },
    );

    // Commit batch
    await batch.commit();
  }

  Future<void> updateMessageStatus(String conversationId, String messageId, {required bool isRead}) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'isRead': isRead,
          'readAt': isRead ? FieldValue.serverTimestamp() : null,
        });
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();
    
    // Get the message reference
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    // Delete the message
    batch.delete(messageRef);

    // Update conversation's last message if needed
    final conversation = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (conversation.exists) {
      final lastMessageRef = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(2)  // Get 2 messages to find the previous one
          .get();

      if (lastMessageRef.docs.isNotEmpty) {
        final lastMessage = lastMessageRef.docs
            .where((doc) => doc.id != messageId)
            .firstOrNull;

        if (lastMessage != null) {
          batch.update(conversation.reference, {
            'lastMessage': lastMessage.data()['content'] ?? '',
            'lastMessageTime': lastMessage.data()['timestamp'],
          });
        } else {
          // If no messages left
          batch.update(conversation.reference, {
            'lastMessage': '',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    await batch.commit();
  }

  Future<void> deleteConversation(String conversationId) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();
    
    try {
      // Delete all messages in the conversation
      final messages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      for (var message in messages.docs) {
        batch.delete(message.reference);
      }

      // Delete the conversation document itself
      batch.delete(_firestore.collection('conversations').doc(conversationId));

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      throw Exception('Failed to delete conversation: $e');
    }
  }

  Future<String> createMessage(
    String conversationId,
    String content,
    MessageType type,
  ) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final messageData = {
      'senderId': currentUser.uid,
      'content': content,
      'type': type.toString(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'mediaUrl': null,  // Initialize mediaUrl as null
    };

    await messageRef.set(messageData);
    
    // Update conversation's last message
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': type == MessageType.voice ? '🎤 Voice message' : content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return messageRef.id;
  }

  Future<void> updateMessageMediaUrl(
    String conversationId,
    String messageId,
    String url,
  ) async {
    try {
      debugPrint('Updating message $messageId with URL: $url');
      
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'mediaUrl': url,
      });
      
      debugPrint('Successfully updated message with URL');
    } catch (e) {
      debugPrint('Error updating message media URL: $e');
      throw Exception('Failed to update message media URL: $e');
    }
  }

  Future<String?> _uploadVoiceMessage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${currentUser?.uid ?? ''}.m4a';
      debugPrint('Uploading voice message: $fileName');
      
      // Create bucket if it doesn't exist
      final bucket = SupabaseService.supabase.storage;
      try {
        await bucket.createBucket('voice-messages');
      } catch (e) {
        debugPrint('Bucket might already exist: $e');
      }

      // Upload the file with correct options
      await bucket
          .from('voice-messages')
          .upload(
            fileName,
            file,
            fileOptions: const supabase.FileOptions(
              upsert: true,
              contentType: 'audio/m4a',
            ),
          );

      // Get public URL
      final String url = bucket
          .from('voice-messages')
          .getPublicUrl(fileName);

      debugPrint('Voice message uploaded successfully. URL: $url');
      return url;
    } catch (e, stackTrace) {
      debugPrint('Error uploading voice message: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  Future<void> sendVoiceMessage(
    String conversationId,
    File voiceFile,
  ) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    try {
      debugPrint('Starting voice message upload process');
      
      // First create a pending message
      final messageRef = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
            'senderId': currentUser.uid,
            'content': '🎤 Voice message (uploading...)',
            'type': MessageType.voice.toString(),
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'mediaUrl': null,
            'status': 'uploading',
          });

      // Upload the voice file using SupabaseService directly
      final voiceUrl = await SupabaseService().uploadVoiceMessage(voiceFile);

      // Update the message with the URL
      await messageRef.update({
        'mediaUrl': voiceUrl,
        'content': '🎤 Voice message',
        'status': 'sent',
      });

      // Update conversation's last message
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': '🎤 Voice message',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      debugPrint('Voice message sent successfully with URL: $voiceUrl');
    } catch (e) {
      debugPrint('Error sending voice message: $e');
      throw Exception('Failed to send voice message: $e');
    }
  }
}
