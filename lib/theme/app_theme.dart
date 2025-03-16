import 'package:flutter/material.dart';

final lightColorScheme = ColorScheme.light(
  // Main colors from login screen
  primary: const Color(0xFFFF9500),      // Orange accent color
  onPrimary: Colors.white,
  primaryContainer: const Color(0xFFFFE5B4),  // Light orange for buttons
  onPrimaryContainer: const Color(0xFF2D3142),  // Dark text on light orange
  
  // Secondary colors
  secondary: const Color(0xFF2D3142),     // Dark navy
  onSecondary: Colors.white,
  secondaryContainer: Colors.white,
  onSecondaryContainer: const Color(0xFF2D3142),
  
  // Background colors
  background: Colors.white,
  onBackground: const Color(0xFF2D3142),
  surface: Colors.white,
  onSurface: const Color(0xFF2D3142),
  
  // Other colors
  error: const Color(0xFFDC3545),
  outline: Color(0xFFE0E0E0),    // Grey for borders
  surfaceVariant: Color(0xFFF5F5F5),  // Light grey for cards
);

final darkColorScheme = ColorScheme.dark(
  // Base colors
  primary: const Color(0xFF7289DA),      // Discord-inspired blurple
  onPrimary: Colors.white,
  primaryContainer: const Color(0xFF4E5D94),
  onPrimaryContainer: Colors.white,
  
  // Secondary colors
  secondary: const Color(0xFF86B9F5),    // Soft blue
  onSecondary: Colors.black,
  secondaryContainer: const Color(0xFF2C5282),
  onSecondaryContainer: Colors.white,
  
  // Background colors
  background: const Color(0xFF1A1C1E),   // Rich dark background
  onBackground: Colors.white,
  surface: const Color(0xFF2C2F33),      // Slightly lighter surface
  onSurface: Colors.white,
  
  // Error colors
  error: const Color(0xFFEF5350),        // Soft red
  onError: Colors.white,
  errorContainer: const Color(0xFF842029),
  onErrorContainer: Colors.white,
  
  // Additional colors
  tertiary: const Color(0xFF70A4C7),     // Muted blue
  onTertiary: Colors.white,
  tertiaryContainer: const Color(0xFF2D4A5E),
  onTertiaryContainer: Colors.white,
  
  // Surface colors
  surfaceVariant: const Color(0xFF383B3F),
  onSurfaceVariant: const Color(0xFFE1E3E5),
  outline: const Color(0xFF767A7F),
  outlineVariant: const Color(0xFF44474C),
  
  // Inverse colors
  inverseSurface: const Color(0xFFE4E6E8),
  onInverseSurface: const Color(0xFF1A1C1E),
  inversePrimary: const Color(0xFF4E5D94),
  
  // Shadow
  shadow: const Color(0xFF000000),
  scrim: const Color(0xFF000000),
  
  // Surface tint
  surfaceTint: const Color(0xFF7289DA),
);

final lightThemeData = ThemeData(
  colorScheme: lightColorScheme,
  useMaterial3: true,
  
  // Text Theme
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: lightColorScheme.onBackground,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: lightColorScheme.onBackground,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: lightColorScheme.onBackground,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: lightColorScheme.onBackground,
    ),
  ),
  
  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lightColorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lightColorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lightColorScheme.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  
  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightColorScheme.primaryContainer,
      foregroundColor: lightColorScheme.onPrimaryContainer,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  
  // Outlined Button Theme
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: lightColorScheme.onBackground,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      side: BorderSide(color: lightColorScheme.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  
  // Card Theme
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: Colors.white,
  ),
  
  // Checkbox Theme
  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
    side: BorderSide(color: lightColorScheme.outline),
  ),
);
