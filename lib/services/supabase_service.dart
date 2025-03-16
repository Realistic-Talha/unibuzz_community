import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';  // Add this import for debugPrint
import 'dart:io';
import 'package:path/path.dart' as path;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static late final SupabaseClient supabase;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://jorujzpaoqfmpjtwuccd.supabase.co',  // Project URL from Supabase settings
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvcnVqenBhb3FmbXBqdHd1Y2NkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU4NTYxMzEsImV4cCI6MjA1MTQzMjEzMX0.H0Jh4b1zTwXMrm97HEQMP_662YOb1IaQVI-Bs--ejxc',  // Public anon key from project settings
    );
    supabase = Supabase.instance.client;
  }

  SupabaseClient get client => Supabase.instance.client;

  Future<String> uploadVoiceMessage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_voice.m4a';
      
      // Upload with correct file options
      await client.storage
          .from('voice-messages')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              contentType: 'audio/m4a',
              upsert: true,
            ),
          );

      // Get the public URL
      final fileUrl = client.storage
          .from('voice-messages')
          .getPublicUrl(fileName);

      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading voice message to Supabase: $e');
      throw Exception('Failed to upload voice message: $e');
    }
  }
}
