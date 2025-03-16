import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/lost_found_service.dart';
import 'package:unibuzz_community/services/ai_service.dart';
import 'package:unibuzz_community/utils/location_utils.dart';  // Add this import

class ItemMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LostFoundService _lostFoundService = LostFoundService();
  final AIService _aiService = AIService();

  Future<void> processNewItem(String itemId) async {
    final itemDoc = await _firestore.collection('lost_items').doc(itemId).get();
    if (!itemDoc.exists) return;

    final item = itemDoc.data()!;
    final potentialMatches = await _lostFoundService.findPotentialMatches(itemId);

    for (final matchDoc in potentialMatches) {
      final matchData = matchDoc.data() as Map<String, dynamic>;
      
      // Calculate similarity score using AI
      final similarityScore = await _calculateSimilarity(
        item['description'],
        matchData['description'],
        item['tags'] as List<String>,
        List<String>.from(matchData['tags'] ?? []),
      );

      if (similarityScore > 0.7) {  // Threshold for potential match
        await _createMatchNotification(
          itemId,
          matchDoc.id,
          similarityScore,
        );
      }
    }
  }

  Future<double> _calculateSimilarity(
    String description1,
    String description2,
    List<String> tags1,
    List<String> tags2,
  ) async {
    // Implementation
    return 0.0;
  }

  double _calculateLocationSimilarity(GeoPoint location1, GeoPoint location2) {
    final distance = LocationUtils.calculateDistance(location1, location2);
    // Convert distance to similarity score (0-1)
    // Assuming items within 100m are very similar (1.0)
    // and items 5km apart are completely dissimilar (0.0)
    const maxDistance = 5.0; // 5km
    return (1.0 - (distance / maxDistance)).clamp(0.0, 1.0);
  }

  double _calculateBasicSimilarity(List<String> tags1, List<String> tags2) {
    final commonTags = tags1.where((tag) => tags2.contains(tag)).length;
    final totalTags = tags1.length + tags2.length;
    return totalTags > 0 ? (2 * commonTags / totalTags) : 0.0;
  }

  Future<void> _createMatchNotification(
    String itemId1,
    String itemId2,
    double similarityScore,
  ) async {
    await _firestore.collection('match_notifications').add({
      'itemId1': itemId1,
      'itemId2': itemId2,
      'similarityScore': similarityScore,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'viewed': false,
    });
  }

  Stream<QuerySnapshot> getMatchNotificationsStream(String userId) {
    return _firestore
        .collection('match_notifications')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
