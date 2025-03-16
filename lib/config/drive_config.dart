class DriveConfig {
  // OAuth configuration
  static const String clientId = '188988634421-0njve0gc1s093shgr66t9c5u6fij7ntu.apps.googleusercontent.com';
  static const String androidClientId = '188988634421-0njve0gc1s093shgr66t9c5u6fij7ntu.apps.googleusercontent.com';
  static const String projectId = 'phrasal-truck-446416-a2';
  static const String authUri = 'https://accounts.google.com/o/oauth2/auth';
  static const String tokenUri = 'https://oauth2.googleapis.com/token';
  static const String certUrl = 'https://www.googleapis.com/oauth2/v1/certs';
  
  // API configuration
  static const String baseUrl = 'https://www.googleapis.com/drive/v3';
  static const String uploadUrl = 'https://www.googleapis.com/upload/drive/v3';
  static const String folderId = '1NHXePaw7iopUJXpgLig1-cHqoMBG9tq2';
  
  // OAuth scopes
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.install',
  ];
  
  // Allowed audio mime types
  static const List<String> allowedAudioTypes = [
    'audio/mp3',
    'audio/mpeg',
    'audio/wav',
  ];
  
  // Maximum file size (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;
}
