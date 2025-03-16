import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/auth_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final _firestore = FirebaseFirestore.instance;

  Future<void> reportPost(String postId, String reason) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    await _firestore.collection('reports').add({
      'postId': postId,
      'reportedBy': currentUser.uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending', // pending, reviewed, resolved
    });
  }
}
