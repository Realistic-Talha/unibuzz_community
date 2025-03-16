class AIConfig {
  static const String apiKey = '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';  // Replace with your token
  static const String baseUrl = 'https://api-inference.huggingface.co/models';
  
  // Text classification for post categorization
  static const String textClassificationModel = 'facebook/bart-large-mnli';
  
  // Text similarity for lost & found matching
  static const String textSimilarityModel = 'sentence-transformers/all-MiniLM-L6-v2';
  
  // Tag generation from text
  static const String tagGenerationModel = 'facebook/bart-large-cnn';

  static const Map<String, String> headers = {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };
}
