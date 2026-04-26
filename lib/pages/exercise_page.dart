// This page allows users to track their exercise and calculate the calories burned.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// The ExercisePage widget is a stateful widget that displays the exercise page.
class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  // Controllers for the text fields.
  final TextEditingController _exerciseController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // State variables for calories burned, user weight, and user sex.
  double _caloriesBurned = 0.0;
  double _userWeightKg = 70.0;
  String? _userSex;

  // A map of exercises and their MET values.
  final Map<String, double> exerciseMET = {
    "walking": 3.2,
    "jogging": 7.0,
    "running": 10.0,
    "cycling": 8.0,
    "swimming": 6.0,
    "weightlifting": 3.5,
    "jump rope": 12.3,
  };

  @override
  void initState() {
    super.initState();
    // Load the user's data when the widget is initialized.
    _loadUserData();
  }

  // Loads the user's data from Firestore.
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _userSex = doc.data()?['sex'];
          _userWeightKg = doc.data()?['weight'] ?? 70.0;
        });
      }
    }
  }

  // Calculates the calories burned based on the exercise, duration, and user's data.
  void _calculateCalories() {
    FocusScope.of(context).unfocus();

    final duration = double.tryParse(_durationController.text) ?? 0.0;
    final exercise = _exerciseController.text.trim().toLowerCase();
    final met = exerciseMET[exercise] ?? 3.2;

    double calories;
    if (_userSex != null) {
      double bmr = (_userSex == 'Male')
          ? (15.057 * _userWeightKg) + 692.2
          : (14.818 * _userWeightKg) + 486.6;

      calories = (bmr / 24) * met * (duration / 60);
    } else {
      calories = (duration * met * 3.5 * _userWeightKg) / 200;
    }

    setState(() => _caloriesBurned = calories);
  }

  // Resets the calculation.
  void _resetCalculation() {
    _exerciseController.clear();
    _durationController.clear();
    setState(() => _caloriesBurned = 0.0);
  }

  // Saves the diary entry to Firestore.
  Future<void> _saveDiaryEntry(String name, double calories) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final entry = {
      "name": name,
      "calories": calories,
      "type": "exercise",
      "duration_min": double.tryParse(_durationController.text) ?? 0.0,
      "timestamp": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('diary')
        .add(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildInputCard(context),
            if (_caloriesBurned > 0) ...[
              const SizedBox(height: 28),
              _buildResultsCard(context),
            ],
          ],
        ),
      ),
    );
  }

  // Builds the input card for the exercise and duration.
  Widget _buildInputCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22.0),
      ),
      color: isDarkMode
          ? Colors.grey[900]!.withOpacity(0.85)
          : Colors.white.withOpacity(0.85),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Track Your Exercise",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            _styledInput("Exercise Name", _exerciseController),
            const SizedBox(height: 16),
            _styledInput("Duration (minutes)", _durationController),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateCalories,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  backgroundColor: const Color(0xFF009688), // your teal
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: const Text(
                  'Calculate Calories Burned',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a styled input field.
  Widget _styledInput(String label, TextEditingController controller) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[400];

    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor!, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  // Builds the results card that displays the calories burned.
  Widget _buildResultsCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22.0),
      ),
      color: isDarkMode
          ? Colors.grey[900]!.withOpacity(0.85)
          : Colors.white.withOpacity(0.85),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _exerciseController.text.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),

            const SizedBox(height: 20),
            Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calories Burned', style: theme.textTheme.titleMedium),
                Text(
                  '${_caloriesBurned.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _saveDiaryEntry(
                          _exerciseController.text, _caloriesBurned);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Exercise added to diary!')),
                      );

                      _resetCalculation();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: const Text(
                      "Add to Diary",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _resetCalculation,
                  style: TextButton.styleFrom(
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: const Text("Cancel", style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
