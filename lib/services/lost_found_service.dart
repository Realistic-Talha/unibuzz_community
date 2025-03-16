import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/services/image_hosting_service.dart';
import 'dart:io';

class LostFoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageHostingService _imageHosting = ImageHostingService();

  Stream<QuerySnapshot> getLostItemsStream({
    bool? isLost,
    String? category,
    String? status,
  }) {
    Query query = _firestore.collection('lost_items')
        .orderBy('dateReported', descending: true);

    if (isLost != null) {
      query = query.where('isLost', isEqualTo: isLost);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots();
  }

  Future<String> reportItem({
    required String title,
    required String description,
    required String location,
    required GeoPoint coordinates,
    required bool isLost,
    required String? category,
    required List<String> tags,
    required List<File> images,
    DateTime? dateLostFound,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Upload images to Imgur
    final List<String> imageUrls = await _imageHosting.uploadMultipleImages(images);

    final docRef = await _firestore.collection('lost_items').add({
      'userId': user.uid,
      'title': title,
      'description': description,
      'images': imageUrls,
      'location': location,
      'coordinates': coordinates,
      'dateReported': FieldValue.serverTimestamp(),
      'dateLostFound': dateLostFound != null 
          ? Timestamp.fromDate(dateLostFound) 
          : null,
      'isLost': isLost,
      'status': 'open',
      'category': category,
      'tags': tags,
    });

    return docRef.id;
  }

  Future<void> updateItemStatus(String itemId, String status) async {
    await _firestore
        .collection('lost_items')
        .doc(itemId)
        .update({'status': status});
  }

  Future<void> matchItems(String lostItemId, String foundItemId) async {
    final batch = _firestore.batch();
    
    final lostRef = _firestore.collection('lost_items').doc(lostItemId);
    final foundRef = _firestore.collection('lost_items').doc(foundItemId);

    batch.update(lostRef, {
      'status': 'matched',
      'matchedWith': foundItemId,
    });

    batch.update(foundRef, {
      'status': 'matched',
      'matchedWith': lostItemId,
    });

    await batch.commit();
  }

  Future<List<QueryDocumentSnapshot>> searchItems({
    required String query,
    String? category,
    bool? isLost,
  }) async {
    Query searchQuery = _firestore.collection('lost_items');

    if (isLost != null) {
      searchQuery = searchQuery.where('isLost', isEqualTo: isLost);
    }
    if (category != null) {
      searchQuery = searchQuery.where('category', isEqualTo: category);
    }

    final querySnapshot = await searchQuery.get();
    return querySnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = data['title'].toString().toLowerCase();
      final description = data['description'].toString().toLowerCase();
      final tags = List<String>.from(data['tags'] ?? []);
      
      final searchText = query.toLowerCase();
      return title.contains(searchText) ||
          description.contains(searchText) ||
          tags.any((tag) => tag.toLowerCase().contains(searchText));
    }).toList();
  }

  Future<List<QueryDocumentSnapshot>> findPotentialMatches(String itemId) async {
    final itemDoc = await _firestore.collection('lost_items').doc(itemId).get();
    if (!itemDoc.exists) return [];

    final item = itemDoc.data()!;
    final isLost = item['isLost'] as bool;
    
    Query matchQuery = _firestore.collection('lost_items')
        .where('isLost', isEqualTo: !isLost)  // Search for opposite type
        .where('status', isEqualTo: 'open')
        .where('category', isEqualTo: item['category']);

    final querySnapshot = await matchQuery.get();
    return querySnapshot.docs;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getItem(String itemId) {
    return _firestore
        .collection('lost_items')
        .doc(itemId)
        .snapshots();
  }
}
