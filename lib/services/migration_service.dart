import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unibuzz_community/services/auth_service.dart';

class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

  Future<void> migrateUsernamesToLowercase() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshots = await FirebaseFirestore.instance
          .collection('users')
          .where('usernameLower', isNull: true)
          .get();

      for (var doc in snapshots.docs) {
        final data = doc.data();
        if (!data.containsKey('usernameLower')) {
          batch.update(doc.reference, {
            'usernameLower': (data['username'] as String?)?.toLowerCase() ?? '',
          });
        }
      }

      if (snapshots.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error during username migration: $e');
    }
  }

  Future<void> migrateUserData() async {
    try {
      await migrateUsernamesToLowercase();
      final authService = AuthService();
      await authService.migrateSearchKeywords();
    } catch (e) {
      debugPrint('Error during user data migration: $e');
    }
  }
}