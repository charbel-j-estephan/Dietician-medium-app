// This is the main entry point of the application.

import 'package:calories_tracking/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'auth/firebase_options.dart';

import 'auth/auth_wrapper.dart';
import 'package:calories_tracking/pages/food_management_page.dart';

// The main function is the starting point of the app.

Future<void> main() async {
  // Ensure that the Flutter binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables from the .env file.
  await dotenv.load(fileName: ".env");
  // Initialize Firebase with the default options for the current platform.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create a new instance of the AppThemeProvider.
  final themeProvider = AppThemeProvider();
  // Load the saved theme mode from shared preferences.s
  await themeProvider.loadThemeMode();

  // Run the app with the theme provider.
  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const CaloriesApp(),
    ),
  );
}

// The root widget of the application.
class CaloriesApp extends StatelessWidget {
  const CaloriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to get the current theme provider.
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        // Return a MaterialApp with the appropriate theme.
        return MaterialApp(
          title: 'Calories Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppThemeProvider.lightTheme,
          darkTheme: AppThemeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
          routes: {'/food_management': (context) => const FoodManagementPage()},
        );
      },
    );
  }
}
