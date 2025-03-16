import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/auth_service.dart';

class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializePresence() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final userStatusRef = _database.child('status/${user.uid}');

    final isOfflineForDatabase = {
      'state': 'offline',
      'lastSeen': ServerValue.timestamp,
    };

    final isOnlineForDatabase = {
      'state': 'online',
      'lastSeen': ServerValue.timestamp,
    };

    _database.child('.info/connected').onValue.listen((event) {
      if (event.snapshot.value == false) return;

      userStatusRef
          .onDisconnect()
          .set(isOfflineForDatabase)
          .then((_) => userStatusRef.set(isOnlineForDatabase));
    });

    // Update Firestore user document
    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Stream<bool> getUserOnlineStatus(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data() as Map<String, dynamic>;
          final lastSeen = data['lastSeen'] as Timestamp?;
          if (lastSeen == null) return false;

          // Consider user online if last seen within last 2 minutes
          return DateTime.now().difference(lastSeen.toDate()).inMinutes < 2;
        });
  }

  Future<void> setTypingStatus(String conversationId, bool isTyping) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    await _database
        .child('typing/$conversationId/${user.uid}')
        .set(isTyping);
  }

  Stream<Map<String, dynamic>> getTypingStatus(String conversationId) {
    return _database
        .child('typing/$conversationId')
        .onValue
        .map((event) => Map<String, dynamic>.from(
            event.snapshot.value as Map? ?? {}));
  }
}
