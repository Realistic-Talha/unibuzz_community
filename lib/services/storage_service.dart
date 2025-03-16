// This service is deprecated in favor of image_hosting_service.dart
// which uses Imgur instead of Firebase Storage

// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

// class StorageService {
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   Future<String> uploadProfileImage(String userId, File imageFile) async {
//     final ref = _storage
//         .ref()
//         .child('profile_images')
//         .child('$userId.jpg');

//     final metadata = SettableMetadata(
//       contentType: 'image/jpeg',
//       customMetadata: {'userId': userId},
//     );
    
//     await ref.putFile(imageFile, metadata);
//     return await ref.getDownloadURL();
//   }

//   Future<String> uploadEventImage(String eventId, File imageFile) async {
//     final ref = _storage
//         .ref()
//         .child('event_images')
//         .child('$eventId.jpg');

//     await ref.putFile(imageFile);
//     return await ref.getDownloadURL();
//   }

//   Future<void> deleteImage(String url) async {
//     try {
//       final ref = _storage.refFromURL(url);
//       await ref.delete();
//     } catch (e) {
//       // Handle or ignore deletion errors
//     }
//   }
// }
