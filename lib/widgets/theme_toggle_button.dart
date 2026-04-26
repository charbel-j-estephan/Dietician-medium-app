// This file contains the theme toggle button widget.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// The ThemeToggleButton widget is a stateless widget that displays a button to toggle the theme.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme provider from the context.
    final themeProvider = Provider.of<AppThemeProvider>(context);

    // Determine the icon to display based on the current theme mode.
    IconData iconData;
    switch (themeProvider.themeMode) {
      case ThemeMode.dark:
        iconData = Icons.dark_mode;
        break;
      case ThemeMode.light:
        iconData = Icons.light_mode;
        break;
      case ThemeMode.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        iconData = brightness == Brightness.dark
            ? Icons.brightness_auto
            : Icons.brightness_auto_outlined;
        break;
    }

    // Return an IconButton that toggles the theme when pressed.
    return IconButton(
      icon: Icon(iconData),
      onPressed: () {
        ThemeMode nextMode;
        switch (themeProvider.themeMode) {
          case ThemeMode.light:
            nextMode = ThemeMode.dark;
            break;
          case ThemeMode.dark:
            nextMode = ThemeMode.system;
            break;
          case ThemeMode.system:
            nextMode = ThemeMode.light;
            break;
        }
        themeProvider.setThemeMode(nextMode);
      },
    );
  }
}
