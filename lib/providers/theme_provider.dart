// This file contains the theme provider for the application.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// The AppThemeProvider class is a ChangeNotifier that provides the theme for the application.
class AppThemeProvider with ChangeNotifier {
  // The current theme mode.
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // The key for the theme mode in shared preferences.
  static const String _themeModeKey = 'themeMode';

  AppThemeProvider();

  // Loads the theme mode from shared preferences.
  Future<void> loadThemeMode() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final theme = prefs.getString(_themeModeKey);
        if (theme != null) {
          _themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == theme,
            orElse: () => ThemeMode.system,
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final theme = prefs.getString(_themeModeKey);
        if (theme != null) {
          _themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == theme,
            orElse: () => ThemeMode.system,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading theme: $e");
    }
  }

  // Sets the theme mode and saves it to shared preferences.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
    } catch (e) {
      debugPrint("Error saving theme: $e");
    }
  }

  // The light theme.
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF00695C),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F5F5),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00695C),
      brightness: Brightness.light,
      background: const Color(0xFFF5F5F5),
      surface: Colors.white,
      onSurface: Colors.black87,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),
    buttonTheme: const ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      buttonColor: Color(0xFF00695C),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleMedium: TextStyle(fontSize: 18, color: Colors.black54),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
    ),
  );

  // The dark theme.
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00897B),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00897B),
      brightness: Brightness.dark,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFE0E0E0),
    ),
    cardTheme: CardThemeData(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),
    buttonTheme: const ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      buttonColor: Color(0xFF00897B),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE0E0E0),
      ),
      titleMedium: TextStyle(fontSize: 18, color: Colors.white70),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
    ),
  );
}
