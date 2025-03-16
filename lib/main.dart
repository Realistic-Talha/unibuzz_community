import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unibuzz_community/firebase_options.dart';
import 'package:unibuzz_community/providers/theme_provider.dart';
import 'package:unibuzz_community/providers/auth_provider.dart';
import 'package:unibuzz_community/screens/auth/login_screen.dart';
import 'package:unibuzz_community/screens/home/home_screen.dart';
import 'package:unibuzz_community/theme/app_theme.dart';
import 'package:unibuzz_community/app_lifecycle_observer.dart';
import 'package:unibuzz_community/services/shared_prefs.dart';
import 'package:unibuzz_community/screens/auth/signup_screen.dart';
import 'package:unibuzz_community/screens/welcome/welcome_screen.dart';
import 'package:unibuzz_community/screens/auth/forgot_password_screen.dart';
import 'package:unibuzz_community/screens/auth/signup_welcome_screen.dart';
import 'package:unibuzz_community/screens/events/events_screen.dart';
import 'package:unibuzz_community/screens/lost_found/lost_found_screen.dart';
import 'package:unibuzz_community/screens/events/event_details_screen.dart';
import 'package:unibuzz_community/screens/lost_found/item_details_screen.dart';
import 'package:unibuzz_community/screens/posts/create_post_screen.dart';
import 'package:unibuzz_community/models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/screens/settings/settings_screen.dart';
import 'package:unibuzz_community/widgets/search/post_search_delegate.dart';
import 'package:unibuzz_community/screens/profile/edit_profile_screen.dart';
import 'package:unibuzz_community/models/user_model.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:unibuzz_community/screens/settings/blocked_users_screen.dart';
import 'package:unibuzz_community/screens/profile/public_profile_screen.dart';
import 'package:unibuzz_community/services/migration_service.dart';
import 'package:unibuzz_community/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences early
  final prefs = await SharedPrefs.instance;

  // Track initialization status
  bool firebaseInitialized = false;
  bool appCheckInitialized = false;
  bool databaseInitialized = false;

  try {
    // Initialize Supabase first and separately
    await SupabaseService.initialize();
    debugPrint('Supabase initialization completed successfully');

    // Force-delete any existing Firebase app instances to prevent duplicate app errors
    try {
      Firebase.app().delete();
      debugPrint('Existing Firebase app deleted');
    } catch (e) {
      debugPrint('No existing Firebase app to delete: $e');
    }

    // Clear any cached credentials that might have expired
    try {
      // Clear any cached shared preferences related to auth
      prefs.remove('auth_token');
      prefs.remove('refresh_token');
      // Add any other authentication-related cached items to clear
    } catch (e) {
      debugPrint('Error clearing cached credentials: $e');
    }

    // Initialize Firebase with fresh instance
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('New Firebase app initialized successfully');
      firebaseInitialized = true;
    } catch (firebaseError) {
      debugPrint('Firebase initialization error: $firebaseError');
    }

    // Only attempt database config if Firebase initialized successfully
    if (firebaseInitialized) {
      try {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
        FirebaseDatabase.instance.setLoggingEnabled(false);
        databaseInitialized = true;
        debugPrint('Firebase Database configured successfully');
      } catch (dbError) {
        debugPrint('Firebase Database configuration error: $dbError');
      }

      // Try App Check only if Firebase is working
      try {
        await FirebaseAppCheck.instance.activate(
          // Use debug provider during development
          androidProvider: AndroidProvider.debug,
          // For production use:
          // androidProvider: AndroidProvider.playIntegrity,
        );
        appCheckInitialized = true;
        debugPrint('Firebase App Check activated successfully');
      } catch (appCheckError) {
        debugPrint('Firebase App Check error: $appCheckError');
      }

      // Test Firestore access
      try {
        debugPrint('Testing Firestore access...');
        FirebaseFirestore.instance
            .collection('test_access')
            .add({
              'timestamp': FieldValue.serverTimestamp(),
              'test': 'Checking access'
            })
            .then((_) => debugPrint('✅ Firestore write access confirmed'))
            .catchError(
                (error) => debugPrint('❌ Firestore write error: $error'));

        // Check read access too
        FirebaseFirestore.instance
            .collection('test_access')
            .limit(1)
            .get()
            .then((_) => debugPrint('✅ Firestore read access confirmed'))
            .catchError(
                (error) => debugPrint('❌ Firestore read error: $error'));
      } catch (e) {
        debugPrint('Error while testing Firestore access: $e');
      }
    }

    // Run migrations if Firebase is available
    if (firebaseInitialized) {
      try {
        await MigrationService().migrateUsernamesToLowercase();
        await MigrationService().migrateUserData();
        debugPrint('Migrations completed successfully');
      } catch (migrationError) {
        debugPrint('Migration error: $migrationError');
      }
    }

    // Re-authenticate the user if needed
    if (firebaseInitialized) {
      try {
        // Get the AuthProvider instance and force a token refresh
        final authProvider = AuthProvider();
        await authProvider.refreshAuthStatus();
        debugPrint('User authentication refreshed');
      } catch (authError) {
        debugPrint('Error refreshing authentication: $authError');
      }
    }

    // Launch the app regardless of Firebase status
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const UniBuzzApp(),
      ),
    );

    // Log initialization status for debugging
    debugPrint('Initialization summary:');
    debugPrint(
        '- Firebase core: ${firebaseInitialized ? "SUCCESS" : "FAILED"}');
    debugPrint(
        '- Firebase database: ${databaseInitialized ? "SUCCESS" : "FAILED"}');
    debugPrint(
        '- Firebase app check: ${appCheckInitialized ? "SUCCESS" : "FAILED"}');
  } catch (e) {
    debugPrint('Error during app initialization: $e');
    // Handle initialization error appropriately
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize app. Please try again.'),
        ),
      ),
    ));
  }
}

class UniBuzzApp extends StatefulWidget {
  const UniBuzzApp({super.key});

  @override
  State<UniBuzzApp> createState() => _UniBuzzAppState();
}

class _UniBuzzAppState extends State<UniBuzzApp> {
  final _lifecycleObserver = AppLifecycleObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'UniBuzz Community',
          theme: lightThemeData,
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF1A1C1E),
            cardColor: const Color(0xFF2C2F33),
            dividerColor: const Color(0xFF3E4246),
          ),
          themeMode: themeProvider.themeMode,
          // Add routes
          initialRoute: '/',
          routes: {
            // Auth routes
            '/': (context) => Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    // Check if welcome screen should be shown
                    return FutureBuilder<bool>(
                      future: SharedPrefs.instance.then(
                        (prefs) => prefs.getBool('has_seen_welcome') ?? false,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final hasSeenWelcome = snapshot.data ?? false;
                        if (!hasSeenWelcome) {
                          return const WelcomeScreen();
                        }

                        return authProvider.isAuthenticated
                            ? const HomeScreen()
                            : const LoginScreen();
                      },
                    );
                  },
                ),
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/signup-welcome': (context) => const SignupWelcomeScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),

            // Main feature routes
            '/events': (context) => const EventsScreen(),
            '/event-details': (context) {
              final String eventId =
                  ModalRoute.of(context)!.settings.arguments as String;
              return EventDetailsScreen(
                event: Event(
                  id: eventId,
                  title: '',
                  description: '',
                  dateTime: DateTime.now(),
                  location: '',
                  category: '',
                  organizerId: '',
                  coordinates: const GeoPoint(0, 0),
                ),
              );
            },
            '/lost-found': (context) => const LostFoundScreen(),
            '/item-details': (context) {
              final String itemId =
                  ModalRoute.of(context)!.settings.arguments as String;
              return ItemDetailsScreen(itemId: itemId);
            },
            '/create-post': (context) => const CreatePostScreen(),
            '/profile/:userId': (context) {
              final userId =
                  ModalRoute.of(context)!.settings.arguments as String;
              return PublicProfileScreen(userId: userId);
            },

            // Settings and support routes
            '/settings': (context) => const SettingsScreen(),
            '/blocked-users': (context) => const BlockedUsersScreen(),
            '/edit-profile': (context) {
              debugPrint('Edit profile route called');
              final args = ModalRoute.of(context)?.settings.arguments;
              debugPrint('Route arguments: $args');

              if (args is! UserModel) {
                debugPrint('Invalid user data type: ${args.runtimeType}');
                return const Scaffold(
                  body: Center(child: Text('Invalid user data')),
                );
              }
              return EditProfileScreen(userModel: args);
            },
          },
          onGenerateRoute: (settings) {
            // Handle dynamic routes here if needed
            return null;
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
