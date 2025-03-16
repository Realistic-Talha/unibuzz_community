import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:unibuzz_community/config/imgur_config.dart';
import 'package:flutter/foundation.dart';

class ImageHostingService {
  static final ImageHostingService _instance = ImageHostingService._internal();
  factory ImageHostingService() => _instance;
  ImageHostingService._internal();

  Future<String> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(ImgurConfig.uploadEndpoint),
        headers: ImgurConfig.headers,
        body: jsonEncode({
          'image': base64Image,
          'type': 'base64',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to upload image: ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final imageUrl = responseData['data']['link'];
      debugPrint('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<String>> uploadMultipleImages(
    List<File> images, {
    void Function(double)? onProgress,
  }) async {
    final List<String> urls = [];
    for (int i = 0; i < images.length; i++) {
      try {
        final url = await uploadImage(images[i]);
        urls.add(url);
        
        if (onProgress != null) {
          final progress = (i + 1) / images.length;
          onProgress(progress);
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
        // Continue with remaining images even if one fails
      }
    }
    return urls;
  }
}
