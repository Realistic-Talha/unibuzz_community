import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import 'package:unibuzz_community/models/user_model.dart';
import 'package:unibuzz_community/models/user_settings.dart'; // Add this import
import 'package:google_sign_in/google_sign_in.dart'; // Add this import

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Generate search keywords
    final List<String> searchKeywords = _generateSearchKeywords(username);

    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': email,
      'username': username,
      'usernameLower': username.toLowerCase(),
      'searchKeywords': searchKeywords,  // Add search keywords
      'createdAt': FieldValue.serverTimestamp(),
      'postsCount': 0,
      'followers': [],
      'following': [],
      'blockedUsers': [],
    });

    return userCredential;  // Add explicit return
  }

  List<String> _generateSearchKeywords(String username) {
    // Convert username to lowercase
    final String lower = username.toLowerCase();
    
    // Generate list of substrings
    final List<String> keywords = [];
    for (int i = 1; i <= lower.length; i++) {
      keywords.add(lower.substring(0, i));
    }
    
    // Add email username part if it's an email
    if (lower.contains('@')) {
      final emailUsername = lower.split('@')[0];
      for (int i = 1; i <= emailUsername.length; i++) {
        keywords.add(emailUsername.substring(0, i));
      }
    }
    
    return keywords;
  }

  // Add migration method for existing users
  Future<void> migrateSearchKeywords() async {
    final querySnapshot = await _firestore.collection('users').get();
    
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('searchKeywords')) {
        final username = data['username'] as String;
        final searchKeywords = _generateSearchKeywords(username);
        batch.update(doc.reference, {
          'searchKeywords': searchKeywords,
        });
      }
    }
    
    await batch.commit();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Initialize GoogleSignIn with proper configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // Add hostedDomain if you want to restrict to specific domain
        // hostedDomain: "example.com",
      );

      // Sign out first to ensure clean state
      await googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign In was aborted by user');
        return null;
      }

      try {
        // Get authentication details
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in with Firebase
        final userCredential = await _auth.signInWithCredential(credential);

        // Create/update user document in Firestore
        if (userCredential.user != null) {
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'email': userCredential.user!.email,
            'username': userCredential.user!.displayName,
            'username_lowercase': userCredential.user!.displayName?.toLowerCase(),
            'profileImageUrl': userCredential.user!.photoURL,
            'lastLoginAt': FieldValue.serverTimestamp(),
            'blockedUsers': [],  // Add this line
          }, SetOptions(merge: true));
        }

        return userCredential;
      } catch (e) {
        debugPrint('Firebase sign in error: $e');
        await googleSignIn.signOut();
        rethrow;
      }
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send reset email: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getUserSettings() async {
    if (currentUser == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    return doc.data();
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    if (currentUser == null) return;

    // Validate and clean social links
    if (settings.containsKey('socialLinks')) {
      final socialLinks = settings['socialLinks'] as Map<String, dynamic>;
      socialLinks.removeWhere((_, value) => value == null || value.toString().isEmpty);
    }

    // Remove null or empty values
    settings.removeWhere((_, value) => value == null || (value is String && value.isEmpty));

    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(settings);
    } catch (e) {
      debugPrint('Error updating user settings: $e');
      throw Exception('Failed to update profile settings');
    }
  }

  Future<void> updateProfile({
    String? username,
    String? photoUrl,
    String? coverPhotoUrl,  // Change from coverPhoto to coverPhotoUrl
    String? profileImageUrl,  // Add this parameter
    String? bio,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final updates = <String, dynamic>{};
    if (username != null && username.isNotEmpty) {
      updates['username'] = username;
      updates['usernameLower'] = username.toLowerCase(); // Update lowercase version
    }
    if (photoUrl != null) {
      updates['photoUrl'] = photoUrl;
      updates['profileImageUrl'] = photoUrl;  // Always update both fields
    }
    if (profileImageUrl != null) {
      updates['photoUrl'] = profileImageUrl;  // Keep both fields in sync
      updates['profileImageUrl'] = profileImageUrl;
    }
    if (coverPhotoUrl != null) updates['coverPhotoUrl'] = coverPhotoUrl;
    if (bio != null) updates['bio'] = bio;

    try {
      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final querySnapshot = await _firestore
        .collection('users')
        .limit(20)
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .where((user) => 
            user.username.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> updateUserFCMToken(String token) async {
    if (currentUser == null) return;
    await _firestore.collection('users').doc(currentUser!.uid).update({
      'fcmToken': token,
    });
  }

  Stream<UserModel?> get userModelStream => _auth.authStateChanges().asyncMap(
        (user) async {
          if (user == null) return null;
          
          // Migrate user data if needed
          await migrateUserPostCounts();
          
          final doc = await _firestore.collection('users').doc(user.uid).get();
          return UserModel.fromMap(doc.data()!, doc.id);
        },
      );

  Future<void> blockUser(String userId) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'blockedUsers': FieldValue.arrayUnion([userId]),
    });

    // Update settings
    final settings = await getUserSettings();
    if (settings != null) {
      final updatedSettings = UserSettings.fromMap(settings).copyWith(
        blockedUsers: [...settings['blockedUsers'] ?? [], userId],
      );
      await updateUserSettings(updatedSettings.toMap());
    }
  }

  Future<void> unblockUser(String userId) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'blockedUsers': FieldValue.arrayRemove([userId]),
    });

    // Update settings
    final settings = await getUserSettings();
    if (settings != null) {
      final currentBlocked = List<String>.from(settings['blockedUsers'] ?? []);
      currentBlocked.remove(userId);
      final updatedSettings = UserSettings.fromMap(settings).copyWith(
        blockedUsers: currentBlocked,
      );
      await updateUserSettings(updatedSettings.toMap());
    }
  }

  Future<bool> isUserBlocked(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final doc = await _firestore.collection('users').doc(currentUser.uid).get();
    final blockedUsers = List<String>.from(doc.data()?['blockedUsers'] ?? []);
    return blockedUsers.contains(userId);
  }

  // Add this new method to migrate existing users
  Future<void> migrateUserPostCounts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final postsRef = _firestore.collection('posts');

    // Get user's posts count
    final posts = await postsRef
        .where('userId', isEqualTo: user.uid)
        .get();

    // Update user document with correct count
    await userRef.set({
      'postsCount': posts.docs.length,
      'posts': posts.docs.map((doc) => doc.id).toList(),
    }, SetOptions(merge: true));
  }
}
