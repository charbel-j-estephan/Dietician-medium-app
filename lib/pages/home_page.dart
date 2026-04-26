// This page is the home page for clients. It displays a bottom navigation bar with different pages.

import 'package:calories_tracking/widgets/theme_toggle_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_page.dart';
import 'water_page.dart';
import 'exercise_page.dart';
import 'weight_page.dart';

// The HomePage widget is a stateful widget that displays the home page.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // The index of the selected page.
  int _selectedIndex = 0;

  // The list of pages to be displayed in the bottom navigation bar.
  static final List<Widget> _pages = <Widget>[
    DiaryPage(),
    WaterPage(),
    ExercisePage(),
    const WeightPage(),
  ];

  // The list of titles for the pages.
  static const List<String> _titles = <String>[
    'Diary',
    'Water Intake',
    'Exercise',
    'Weight',
  ];

  // A method to handle the tap on a bottom navigation bar item.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // A method to log out the user.
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_first_login_setup', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          const ThemeToggleButton(),
          // The logout button.
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _pages[_selectedIndex],
      // The bottom navigation bar.
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.book),
            icon: Icon(Icons.book_outlined),
            label: 'Diary',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.local_drink),
            icon: Icon(Icons.local_drink_outlined),
            label: 'Water',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.fitness_center),
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Exercise',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.show_chart),
            icon: Icon(Icons.show_chart_outlined),
            label: 'Weight',
          ),
        ],
      ),
    );
  }
}
