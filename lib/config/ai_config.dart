class AIConfig {
  // DO NOT hardcode tokens directly in source code
  // Use environment variables or secure local storage instead
  static String getHuggingFaceToken() {
    // Return token from secure storage or environment
    return const String.fromEnvironment('HUGGING_FACE_TOKEN', defaultValue: '');
  }

  static const String baseUrl = 'https://api-inference.huggingface.co/models';

  // Text classification for post categorization
  static const String textClassificationModel = 'facebook/bart-large-mnli';

  // Text similarity for lost & found matching
  static const String textSimilarityModel =
      'sentence-transformers/all-MiniLM-L6-v2';

  // Tag generation from text
  static const String tagGenerationModel = 'facebook/bart-large-cnn';

  static Map<String, String> get headers => {
        'Authorization': 'Bearer ${getHuggingFaceToken()}',
        'Content-Type': 'application/json',
      };
}
