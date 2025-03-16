// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:unibuzz_community/services/auth_service.dart';

// class PushNotificationService {
//   static final PushNotificationService _instance = PushNotificationService._internal();
//   factory PushNotificationService() => _instance;
//   PushNotificationService._internal();

//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

//   Future<void> initialize() async {
//     // Request permission
//     final settings = await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       // Initialize local notifications
//       const initializationSettings = InitializationSettings(
//         android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//         iOS: DarwinInitializationSettings(),
//       );

//       await _localNotifications.initialize(
//         initializationSettings,
//         onDidReceiveNotificationResponse: _onNotificationTapped,
//       );

//       // Handle FCM messages
//       FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//       FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapped);
//       FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

//       // Get FCM token
//       final token = await _messaging.getToken();
//       if (token != null) {
//         await _updateFCMToken(token);
//       }

//       // Listen for token refresh
//       _messaging.onTokenRefresh.listen(_updateFCMToken);
//     }
//   }

//   Future<void> _updateFCMToken(String token) async {
//     final user = AuthService().currentUser;
//     if (user != null) {
//       await AuthService().updateUserFCMToken(token);
//     }
//   }

//   void _handleForegroundMessage(RemoteMessage message) {
//     _localNotifications.show(
//       message.hashCode,
//       message.notification?.title,
//       message.notification?.body,
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'default_channel',
//           'Default Channel',
//           importance: Importance.high,
//           priority: Priority.high,
//         ),
//       ),
//       payload: message.data['route'],
//     );
//   }

//   void _onNotificationTapped(NotificationResponse response) {
//     // Handle notification tap
//     if (response.payload != null) {
//       // Navigate to appropriate screen
//     }
//   }

//   Future<void> _handleNotificationTapped(RemoteMessage message) async {
//     if (message.data['route'] != null) {
//       // Navigate to appropriate screen
//     }
//   }
// }

// // This function must be outside the class and top-level
// Future<void> _handleBackgroundMessage(RemoteMessage message) async {
//   // Handle background message
//   print('Handling background message: ${message.messageId}');
// }
