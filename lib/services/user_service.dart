import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:unibuzz_community/services/auth_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> updateUserPresence() async {
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
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  Stream<bool> getUserOnlineStatus(String userId) {
    return _database
        .child('status/$userId/state')
        .onValue
        .map((event) => event.snapshot.value == 'online');
  }

  Future<void> updateUserLastSeen(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
