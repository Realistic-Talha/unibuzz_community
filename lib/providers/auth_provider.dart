import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unibuzz_community/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _initialized = false;

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    _authService.userStream.listen((user) {
      _user = user;
      _initialized = true;
      notifyListeners();
    });
  }

  bool get isAuthenticated => _initialized && _user != null;
  User? get user => _user;

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> refreshAuthStatus() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Force token refresh
        await currentUser.getIdToken(true);

        // Update user
        _user = currentUser;
        _initialized = true;

        // Log successful refresh
        debugPrint(
            'Auth status refreshed: User ${currentUser.uid} is logged in');
      } else {
        _user = null;
        debugPrint('Auth status refreshed: No user is logged in');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing auth status: $e');
      _user = null;
      notifyListeners();
    }
  }
}
