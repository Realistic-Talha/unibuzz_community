import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:unibuzz_community/config/drive_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DriveService {
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  DriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: DriveConfig.scopes,
    clientId: DriveConfig.androidClientId,
  );

  Future<String?> uploadAudio(File audioFile) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      
      final auth = await account.authentication;
      
      // Create file metadata with proper sharing settings
      final metadata = {
        'name': 'voice_message_${DateTime.now().millisecondsSinceEpoch}.mp3',
        'parents': [DriveConfig.folderId],
        'permissions': [
          {
            'type': 'anyone',
            'role': 'reader',
            'allowFileDiscovery': false,
            'withLink': true
          }
        ]
      };

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${DriveConfig.uploadUrl}/files?uploadType=multipart&supportsAllDrives=true&fields=id,webContentLink'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${auth.accessToken}',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', 
          audioFile.path,
          filename: metadata['name'] as String
        )
      );

      request.fields['metadata'] = json.encode(metadata);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseJson = json.decode(response.body);

      if (response.statusCode == 200 && responseJson['webContentLink'] != null) {
        return responseJson['webContentLink'] as String;
      }
      return null;
    } catch (e) {
      print('Error uploading audio: $e');
      return null;
    }
  }

  Future<bool> deleteAudio(String fileUrl) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      
      final auth = await account.authentication;
      final fileId = _extractFileIdFromUrl(fileUrl);
      
      final response = await http.delete(
        Uri.parse('${DriveConfig.baseUrl}/files/$fileId'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting audio: $e');
      return false;
    }
  }

  String _extractFileIdFromUrl(String url) {
    // Extract file ID from Google Drive URL
    final RegExp regExp = RegExp(r'/d/([^/]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1) ?? '';
  }
}
