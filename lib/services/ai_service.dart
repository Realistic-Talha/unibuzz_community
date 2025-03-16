import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:unibuzz_community/config/ai_config.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  Future<String> categorizePost(String content) async {
    try {
      final response = await http.post(
        Uri.parse('${AIConfig.baseUrl}/${AIConfig.textClassificationModel}'),
        headers: AIConfig.headers,
        body: json.encode({
          'inputs': content,
          'parameters': {
            'candidate_labels': [
              'General',
              'Academic',
              'Events',
              'Lost & Found',
              'Help Needed'
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['labels'][0] as String;
      }
      return 'General';
    } catch (e) {
      print('Error categorizing post: $e');
      return 'General';
    }
  }

  Future<List<String>> generateTags(String content) async {
    try {
      final response = await http.post(
        Uri.parse('${AIConfig.baseUrl}/${AIConfig.tagGenerationModel}'),
        headers: AIConfig.headers,
        body: json.encode({
          'inputs': 'Generate keywords for: $content',
          'parameters': {
            'max_length': 60,
            'num_return_sequences': 1,
          }
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> generated = json.decode(response.body);
        final String rawTags = generated[0]['generated_text'] as String;
        return rawTags
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .take(5)  // Limit to 5 tags
            .toList();
      }
      return [];
    } catch (e) {
      print('Error generating tags: $e');
      return [];
    }
  }

  Future<double> calculateItemSimilarity(String item1, String item2) async {
    try {
      final response = await http.post(
        Uri.parse('${AIConfig.baseUrl}/${AIConfig.textSimilarityModel}'),
        headers: AIConfig.headers,
        body: json.encode({
          'inputs': {
            'source_sentence': item1,
            'sentences': [item2]
          }
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> scores = json.decode(response.body);
        return scores[0] as double;
      }
      return 0.0;
    } catch (e) {
      print('Error calculating similarity: $e');
      return 0.0;
    }
  }
}
