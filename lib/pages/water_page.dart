// This page allows users to track their water intake.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// The WaterPage widget is a stateful widget that displays the water intake page.
class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  // The current user.
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // State variables for water intake, daily goal, and current weight.
  int _waterIntakeMl = 0;
  double _dailyGoalMl = 0.0;
  double _currentWeightKg = 0.0;

  // A timer for debouncing the save operation.
  Timer? _debounce;

  // A ValueNotifier to hold the selected date.
  final ValueNotifier<DateTime> _selectedDate = ValueNotifier<DateTime>(
    DateTime.now(),
  );

  // The amount of water in a cup in ml.
  static const double cupAmount = 250.0;

  // Returns the date ID for the selected date.
  String get dateId => _selectedDate.value.toIso8601String().split("T").first;

  // The document reference for the water intake.
  DocumentReference<Map<String, dynamic>> get waterDocRef => FirebaseFirestore
      .instance
      .collection("users")
      .doc(currentUser!.uid)
      .collection("water")
      .doc(dateId);

  // The collection reference for the weights.
  CollectionReference<Map<String, dynamic>> get weightsRef => FirebaseFirestore
      .instance
      .collection("users")
      .doc(currentUser!.uid)
      .collection("weights");

  @override
  void initState() {
    super.initState();
    // Add a listener to the selected date to load the water intake for the selected date.
    _selectedDate.addListener(_loadWaterForSelectedDate);
    // Load the water intake for the selected date.
    _loadWaterForSelectedDate();
    // Load the latest weight of the user.
    _loadLatestWeight();
  }

  @override
  void dispose() {
    // Cancel the debounce timer and dispose the selected date.
    _debounce?.cancel();
    _selectedDate.dispose();
    super.dispose();
  }

  // Loads the user's most recent weight to calculate the daily water goal.
  Future<void> _loadLatestWeight() async {
    if (currentUser == null) return;

    try {
      final query = await weightsRef
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        _currentWeightKg = _parseWeight(data);

        setState(() {
          _dailyGoalMl = _currentWeightKg * 33.0;
        });
      }
    } catch (e) {
      _showSnack("Error loading weight: $e");
    }
  }

  // Parses the weight from the given data.
  double _parseWeight(Map<String, dynamic> data) {
    if (data.containsKey('weight')) {
      return (data['weight'] as num?)?.toDouble() ?? 0.0;
    }
    if (data.containsKey('weightKg')) {
      return (data['weightKg'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  // Loads the water intake for the currently selected date from Firestore.
  Future<void> _loadWaterForSelectedDate() async {
    if (currentUser == null) return;

    try {
      final snap = await waterDocRef.get();
      if (!mounted) return;

      if (snap.exists) {
        _waterIntakeMl = (snap.data()?["intakeMl"] as num?)?.toInt() ?? 0;
      } else {
        _waterIntakeMl = 0;
      }

      setState(() {});
    } catch (e) {
      _showSnack("Error loading water intake: $e");
    }
  }

  // Saves the current water intake to Firestore with a debounce.
  void _saveWater() {
    if (!DateUtils.isSameDay(_selectedDate.value, DateTime.now())) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      waterDocRef.set({
        "intakeMl": _waterIntakeMl,
        "timestamp": Timestamp.now(),
      }, SetOptions(merge: true));
    });
  }

  // Increments the water intake.
  void _increment() {
    setState(() => _waterIntakeMl += cupAmount.toInt());
    _saveWater();
  }

  // Decrements the water intake.
  void _decrement() {
    setState(() {
      _waterIntakeMl = max(0, _waterIntakeMl - cupAmount.toInt());
    });
    _saveWater();
  }

  // Shows the date picker.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _selectedDate.value = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Water Intake"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 32),
            _buildProgressRing(),
            const SizedBox(height: 32),
            _buildButtons(),
            const SizedBox(height: 24),
            _buildGoalText(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Builds the date selector.
  Widget _buildDateSelector() {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _selectedDate,
      builder: (context, date, _) {
        String label;
        if (DateUtils.isSameDay(date, DateTime.now())) {
          label = "Today";
        } else if (DateUtils.isSameDay(
          date,
          DateTime.now().subtract(const Duration(days: 1)),
        )) {
          label = "Yesterday";
        } else {
          label = DateFormat("MMMM d, yyyy").format(date);
        }

        return InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }

  // Builds the progress ring.
  Widget _buildProgressRing() {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    final double size = min(screenWidth * 0.75, 300.0);
    final double strokeWidth = size * 0.08;

    final double progress = _dailyGoalMl > 0
        ? (_waterIntakeMl / _dailyGoalMl).clamp(0.0, 1.0)
        : 0.0;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: strokeWidth,
                valueColor: AlwaysStoppedAnimation(
                  theme.colorScheme.surfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (_waterIntakeMl / 1000).toStringAsFixed(2),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: size * 0.18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Liters",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: size * 0.09,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Builds the increment and decrement buttons.
  Widget _buildButtons() {
    bool canModify = DateUtils.isSameDay(_selectedDate.value, DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(Icons.remove, canModify ? _decrement : null),
        const SizedBox(width: 48),
        _circleButton(Icons.add, canModify ? _increment : null),
      ],
    );
  }

  // Builds a circle button.
  Widget _circleButton(IconData icon, VoidCallback? action) {
    final theme = Theme.of(context);
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: action,
        customBorder: const CircleBorder(),
        child: Icon(
          icon,
          size: 36,
          color: action != null
              ? theme.colorScheme.primary
              : theme.disabledColor,
        ),
      ),
    );
  }

  // Builds the goal text.
  Widget _buildGoalText() {
    if (_dailyGoalMl <= 0) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        "Your Daily Goal: ${(_dailyGoalMl / 1000).toStringAsFixed(1)} L",
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Shows a snackbar with the given message.
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
