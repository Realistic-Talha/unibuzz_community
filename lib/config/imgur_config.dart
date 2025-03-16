class ImgurConfig {
  // Note: In production, these should be loaded from environment variables
  static const String clientId = 'ac2330d439fed64';
  static const String clientSecret = '8ac1fc648f2f98b0296f1dd8ab4cf3d34d040ae9';
  static const String uploadEndpoint = 'https://api.imgur.com/3/image';
  
  static Map<String, String> get headers => {
    'Authorization': 'Client-ID $clientId',
    'Content-Type': 'application/json',
  };
}
