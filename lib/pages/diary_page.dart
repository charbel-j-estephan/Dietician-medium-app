// This file contains the main diary page of the application.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/fatsecret_service.dart';
import 'entry_detail_page.dart';

// The DiaryPage widget is a stateful widget that displays the diary entries.
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  // A ValueNotifier to hold the selected date.
  final ValueNotifier<DateTime> _selectedDate = ValueNotifier<DateTime>(
    DateTime.now(),
  );

  // The collection reference for the diary.
  late final CollectionReference _diaryCollection;

  // A list of diary entries.
  List<Map<String, dynamic>> _diary = [];
  // A boolean to indicate if the data is loading.
  bool _isLoading = true;

  // The total calories, carbs, protein, fat, and calories burned.
  double _totalCalories = 0.0;
  double _totalCarbs = 0.0;
  double _totalProtein = 0.0;
  double _totalFat = 0.0;
  double _caloriesBurned = 0.0;

  @override
  void initState() {
    super.initState();

    // Get the current user's ID.
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }

    // Initialize the diary collection reference.
    _diaryCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('diary');

    // Add a listener to the selected date to load the diary entries.
    _selectedDate.addListener(_loadDiary);
    // Load the diary entries for the selected date.
    _loadDiary();
  }

  @override
  void dispose() {
    // Remove the listener from the selected date.
    _selectedDate.removeListener(_loadDiary);
    // Dispose the selected date.
    _selectedDate.dispose();
    super.dispose();
  }

  // Utility to safely parse Firestore numeric values.
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Backward-compatible getter for macro values.
  double _getMacro(Map<String, dynamic> data, String macro) {
    switch (macro) {
      case 'carbs':
        return _parseDouble(data['carbs'] ?? data['carbohydrates_total_g']);
      case 'protein':
        return _parseDouble(data['protein'] ?? data['protein_g']);
      case 'fat':
        return _parseDouble(data['fat'] ?? data['fat_total_g']);
      default:
        return 0.0;
    }
  }

  // Loads the diary entries for the selected date.
  Future<void> _loadDiary() async {
    setState(() {
      _isLoading = true;
    });

    final selected = _selectedDate.value;
    final startOfDay = DateTime(selected.year, selected.month, selected.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await _diaryCollection
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .get();

      if (!mounted) return;

      final Map<String, Map<String, dynamic>> mergedFood = {};
      final List<Map<String, dynamic>> exercises = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final entry = {...data, 'id': doc.id};
        final type = entry['type'] as String?;

        if (type == 'food') {
          final name = entry['name'] as String? ?? 'Unnamed Food';
          if (mergedFood.containsKey(name)) {
            final existing = mergedFood[name]!;
            existing['calories'] =
                _parseDouble(existing['calories']) +
                _parseDouble(entry['calories']);
            existing['carbs'] =
                _getMacro(existing, 'carbs') + _getMacro(entry, 'carbs');
            existing['protein'] =
                _getMacro(existing, 'protein') + _getMacro(entry, 'protein');
            existing['fat'] =
                _getMacro(existing, 'fat') + _getMacro(entry, 'fat');
          } else {
            mergedFood[name] = entry;
          }
        } else if (type == 'exercise') {
          exercises.add(entry);
        }
      }

      final diaryEntries = [...mergedFood.values, ...exercises];
      diaryEntries.sort((a, b) {
        final tsA = a['timestamp'] as Timestamp? ?? Timestamp.now();
        final tsB = b['timestamp'] as Timestamp? ?? Timestamp.now();
        return tsB.compareTo(tsA);
      });

      double cals = 0.0, carbs = 0.0, protein = 0.0, fat = 0.0, burned = 0.0;
      for (final entry in diaryEntries) {
        final calories = _parseDouble(entry['calories']);
        if (entry['type'] == 'exercise') {
          burned += calories;
        } else {
          cals += calories;
          carbs += _getMacro(entry, 'carbs');
          protein += _getMacro(entry, 'protein');
          fat += _getMacro(entry, 'fat');
        }
      }

      setState(() {
        _diary = diaryEntries;
        _totalCalories = cals;
        _totalCarbs = carbs;
        _totalProtein = protein;
        _totalFat = fat;
        _caloriesBurned = burned;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load diary entries: $e')),
      );
    }
  }

  // Recalculates the totals.
  void _recalculateTotals() {
    double cals = 0.0;
    double carbs = 0.0;
    double protein = 0.0;
    double fat = 0.0;
    double burned = 0.0;

    for (final entry in _diary) {
      final calories = _parseDouble(entry['calories']);
      if (entry['type'] == 'exercise') {
        burned += calories;
      } else {
        cals += calories;
        carbs += _getMacro(entry, 'carbs');
        protein += _getMacro(entry, 'protein');
        fat += _getMacro(entry, 'fat');
      }
    }

    _totalCalories = cals;
    _totalCarbs = carbs;
    _totalProtein = protein;
    _totalFat = fat;
    _caloriesBurned = burned;
  }

  // Adds a new entry to the diary.
  Future<void> _addEntry(Map<String, dynamic> newEntry) async {
    Navigator.of(context, rootNavigator: true).maybePop();

    if (newEntry['type'] == 'food') {
      await _handleFoodEntry(newEntry);
    } else if (newEntry['type'] == 'exercise') {
      await _handleExerciseEntry(newEntry);
    }

    await _loadDiary();
  }

  // Handles a new food entry.
  Future<void> _handleFoodEntry(Map<String, dynamic> newEntry) async {
    final existingIndex = _diary.indexWhere(
      (entry) =>
          entry['type'] == 'food' &&
          entry['food_id'] == newEntry['food_id'] &&
          entry['serving_id'] == newEntry['serving_id'],
    );

    if (existingIndex != -1) {
      final existing = _diary[existingIndex];

      final newQuantity =
          ((existing['quantity'] as num?) ?? 0).toDouble() +
          ((newEntry['quantity'] as num?) ?? 0).toDouble();

      final newCalories =
          _parseDouble(existing['calories']) +
          _parseDouble(newEntry['calories']);
      final newCarbs =
          _getMacro(existing, 'carbs') + _getMacro(newEntry, 'carbs');
      final newProtein =
          _getMacro(existing, 'protein') + _getMacro(newEntry, 'protein');
      final newFat = _getMacro(existing, 'fat') + _getMacro(newEntry, 'fat');

      try {
        await _diaryCollection.doc(existing['id']).update({
          'quantity': newQuantity,
          'calories': newCalories,
          'carbs': newCarbs,
          'protein': newProtein,
          'fat': newFat,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update entry: $e')));
      }
    } else {
      try {
        await _diaryCollection.add({
          ...newEntry,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save entry: $e')));
      }
    }
  }

  // Normalizes the exercise name.
  String? _normalizedExerciseName(dynamic name) {
    if (name == null) return null;
    return name.toString().trim().toLowerCase();
  }

  // Handles a new exercise entry.
  Future<void> _handleExerciseEntry(Map<String, dynamic> newEntry) async {
    await _loadDiary();

    final newName = _normalizedExerciseName(newEntry['name']);

    final existingIndex = _diary.indexWhere((entry) {
      if (entry['type'] != 'exercise') return false;
      final existingName = _normalizedExerciseName(entry['name']);
      return existingName == newName;
    });

    if (existingIndex != -1) {
      final existing = _diary[existingIndex];

      final newDuration =
          ((existing['duration_min'] as num?) ?? 0).toDouble() +
          ((newEntry['duration_min'] as num?) ?? 0).toDouble();

      final newCalories =
          ((existing['calories'] as num?) ?? 0).toDouble() +
          ((newEntry['calories'] as num?) ?? 0).toDouble();

      try {
        await _diaryCollection.doc(existing['id']).update({
          'duration_min': newDuration,
          'calories': newCalories,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercise entry updated!')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update exercise: $e')),
        );
      }
    } else {
      try {
        await _diaryCollection.add({
          ...newEntry,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save exercise: $e')));
      }
    }
  }

  // Removes an entry from the diary.
  Future<void> _removeEntry(String id) async {
    final index = _diary.indexWhere((e) => e['id'] == id);
    if (index == -1) return;

    final removedEntry = _diary[index];

    setState(() {
      _diary.removeAt(index);
      _recalculateTotals();
    });

    try {
      await _diaryCollection.doc(id).delete();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete entry: $e')));

      setState(() {
        _diary.insert(index, removedEntry);
        _recalculateTotals();
      });
    }
  }

  // Shows the date picker.
  Future<void> _showDatePicker() async {
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

  // Shows the add food bottom sheet.
  void _showAddFoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddFoodSheet(onFoodAdded: _addEntry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: ValueListenableBuilder<DateTime>(
          valueListenable: _selectedDate,
          builder: (context, date, _) {
            String title;
            final today = DateTime.now();
            if (DateUtils.isSameDay(date, today)) {
              title = 'Today';
            } else if (DateUtils.isSameDay(
              date,
              today.subtract(const Duration(days: 1)),
            )) {
              title = 'Yesterday';
            } else {
              title = DateFormat.yMMMd().format(date);
            }

            return InkWell(
              onTap: _showDatePicker,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, size: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDiaryContent(),
      floatingActionButton: ValueListenableBuilder<DateTime>(
        valueListenable: _selectedDate,
        builder: (context, date, child) {
          final today = DateTime.now();
          final isSameDay = DateUtils.isSameDay(date, today);
          final isBeforeToday = date.isBefore(
            DateTime(today.year, today.month, today.day),
          );

          final bool isEnabled = isSameDay || !isBeforeToday;

          return Opacity(
            opacity: isEnabled ? 1.0 : 0.4,
            child: FloatingActionButton(
              onPressed: isEnabled ? _showAddFoodSheet : null,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  // Builds the diary content.
  Widget _buildDiaryContent() {
    final foodEntries = _diary.where((e) => e['type'] != 'exercise').toList();
    final exerciseEntries = _diary
        .where((e) => e['type'] == 'exercise')
        .toList();

    return RefreshIndicator(
      onRefresh: _loadDiary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTotalsCard(),
            ),
          ),
          if (foodEntries.isEmpty && exerciseEntries.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No entries for this day.\nTap the + button to add something!',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (foodEntries.isNotEmpty) _buildSectionHeader('Food'),
          if (foodEntries.isNotEmpty) _buildEntryList(foodEntries),
          if (exerciseEntries.isNotEmpty) _buildSectionHeader('Exercise'),
          if (exerciseEntries.isNotEmpty) _buildEntryList(exerciseEntries),
        ],
      ),
    );
  }

  // Builds the totals card.
  Widget _buildTotalsCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _totalItem(
              theme,
              'Calories',
              (_totalCalories - _caloriesBurned).toStringAsFixed(0),
              'kcal',
            ),
            _totalItem(theme, 'Carbs', _totalCarbs.toStringAsFixed(0), 'g'),
            _totalItem(theme, 'Protein', _totalProtein.toStringAsFixed(0), 'g'),
            _totalItem(theme, 'Fat', _totalFat.toStringAsFixed(0), 'g'),
          ],
        ),
      ),
    );
  }

  // Builds a total item.
  Widget _totalItem(ThemeData theme, String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(unit, style: theme.textTheme.bodySmall),
      ],
    );
  }

  // Builds a section header.
  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Builds the entry list.
  Widget _buildEntryList(List<Map<String, dynamic>> entries) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entry = entries[index];
        final isExercise = entry['type'] == 'exercise';

        return Dismissible(
          key: ValueKey(entry['id']),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _removeEntry(entry['id']),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: _buildDiaryItemCard(entry, isExercise),
        );
      }, childCount: entries.length),
    );
  }

  // Builds a diary item card.
  Widget _buildDiaryItemCard(Map<String, dynamic> entry, bool isExercise) {
    final theme = Theme.of(context);
    final calorieColor = isExercise ? Colors.green : theme.colorScheme.primary;
    final caloriePrefix = isExercise ? '-' : '+';

    final titleText = entry['name']?.toString() ?? 'Unnamed Entry';
    String subtitleText = '';

    if (isExercise) {
      final duration = (entry['duration_min'] as num?)?.toDouble();
      subtitleText = duration != null
          ? '${duration.toStringAsFixed(0)} min'
          : '';
    } else {
      final quantity = (entry['quantity'] as num?);
      final servingDescription = entry['serving_description'] as String?;
      if (quantity != null && servingDescription != null) {
        final isInt = quantity == quantity.truncateToDouble();
        final quantityText = isInt
            ? quantity.toStringAsFixed(0)
            : quantity.toStringAsFixed(1);
        subtitleText = '$quantityText x $servingDescription';
      } else if (servingDescription != null) {
        subtitleText = servingDescription;
      }
    }

    final calories =
        double.tryParse(entry['calories']?.toString() ?? '') ?? 0.0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EntryDetailPage(entry: entry, onDelete: _removeEntry),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: calorieColor.withOpacity(0.1),
            child: Icon(
              isExercise ? Icons.fitness_center : Icons.restaurant,
              color: calorieColor,
            ),
          ),
          title: Text(
            titleText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitleText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          trailing: Text(
            '$caloriePrefix${calories.toStringAsFixed(0)} kcal',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: calorieColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// An enum to represent the two views of the add food bottom sheet.
enum _FoodSheetView { search, detail }

// The _AddFoodSheet widget is a stateful widget that displays the add food bottom sheet.
class _AddFoodSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> foodData) onFoodAdded;

  const _AddFoodSheet({required this.onFoodAdded});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  // Controllers for the text fields.
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  // An instance of the FatsecretService.
  final _fatsecretService = FatsecretService();

  // The current view of the bottom sheet.
  _FoodSheetView _currentView = _FoodSheetView.search;
  // A boolean to indicate if the data is loading.
  bool _isLoading = false;

  // A list of search results.
  List<dynamic> _searchResults = [];
  // The selected food details.
  Map<String, dynamic>? _selectedFoodDetails;
  // The selected serving.
  Map<String, dynamic>? _selectedServing;

  @override
  void dispose() {
    // Dispose the controllers when the widget is disposed.
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Returns the height of the bottom sheet.
  double get _sheetHeight {
    return MediaQuery.of(context).size.height *
        (_currentView == _FoodSheetView.search ? 0.8 : 0.6);
  }

  // Searches for foods
  Future<void> _searchFoods() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    // 1. Search Firestore first
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection('foods').get();

    List<dynamic> firestoreResults = [];
    if (querySnapshot.docs.isNotEmpty) {
      firestoreResults = querySnapshot.docs
          .where((doc) => doc.data()['name'].toString().toLowerCase().contains(query))
          .map((doc) {
            final data = doc.data();
            return {
              'food_name': data['name'],
              'brand_name': data['category'], // Using category as brand_name
              'food_id': doc.id,
              'is_from_firestore': true,
              'firestore_data': data, // Keep original data
            };
          }).toList();
    }

    // 2. If no results from Firestore, search Fatsecret API
    if (firestoreResults.isEmpty) {
      final apiResults = await _fatsecretService.searchFoods(_searchController.text.trim());
      if (mounted) {
        setState(() {
          _searchResults = apiResults.map((result) {
            if (result is Map<String, dynamic>) {
              return {
                ...result,
                'is_from_firestore': false,
              };
            }
            return result;
          }).toList();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _searchResults = firestoreResults;
          _isLoading = false;
        });
      }
    }
  }

  // Gets the food details for the selected food.
  Future<void> _getFoodDetails(String foodId) async {
    setState(() {
      _isLoading = true;
      _selectedFoodDetails = null;
    });

    final details = await _fatsecretService.getFood(foodId);

    if (!mounted) return;

    if (details.containsKey('error')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(details['error'])));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final servingsRaw = details['servings']?['serving'];
    final List<dynamic> servings = servingsRaw is List
        ? servingsRaw
        : [servingsRaw];

    setState(() {
      _selectedFoodDetails = details;
      _selectedServing = servings.isNotEmpty ? servings[0] : null;
      _currentView = _FoodSheetView.detail;
      _isLoading = false;
    });
  }

  // Adds the selected food to the diary.
  void _addToDiary() {
    if (_selectedFoodDetails == null || _selectedServing == null) return;

    final quantity = double.tryParse(_quantityController.text) ?? 1.0;

    final calories = _parseServingValue(_selectedServing!['calories']);
    final carbs = _parseServingValue(_selectedServing!['carbohydrate']);
    final protein = _parseServingValue(_selectedServing!['protein']);
    final fat = _parseServingValue(_selectedServing!['fat']);

    final foodData = {
      'food_id': _selectedFoodDetails!['food_id'],
      'serving_id': _selectedServing!['serving_id'],
      'name': _selectedFoodDetails!['food_name'],
      'type': 'food',
      'calories': calories * quantity,
      'carbs': carbs * quantity,
      'protein': protein * quantity,
      'fat': fat * quantity,
      'quantity': quantity,
      'serving_description': _selectedServing!['serving_description'],
    };

    widget.onFoodAdded(foodData);
  }

  // Parses the serving value.
  double _parseServingValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Goes back to the search view.
  void _goBackToSearch() {
    setState(() {
      _currentView = _FoodSheetView.search;
      _selectedFoodDetails = null;
      _selectedServing = null;
      _searchResults = [];
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _sheetHeight,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildCurrentView(),
      ),
    );
  }

  // Builds the current view.
  Widget _buildCurrentView() {
    switch (_currentView) {
      case _FoodSheetView.search:
        return _buildSearchView();
      case _FoodSheetView.detail:
        return _buildDetailView();
    }
  }

  // Builds the search view.
  Widget _buildSearchView() {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('searchView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add Food',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "e.g., 'Apple' or 'Big Mac'",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searchFoods,
            ),
          ),
          onSubmitted: (_) => _searchFoods(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _searchResults.isEmpty
              ? const Center(child: Text('Search for a food to get started.'))
              : _buildSearchResultsList(),
        ),
      ],
    );
  }

  // Builds the search results list.
  Widget _buildSearchResultsList() {
    if (_searchResults.isNotEmpty &&
        _searchResults.first is Map &&
        _searchResults.first.containsKey('error')) {
      return Center(child: Text(_searchResults.first['error'].toString()));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(food['food_name']?.toString() ?? 'Unnamed Food'),
            subtitle: Text(food['brand_name']?.toString() ?? 'Generic'),
            onTap: () {
              if (food['is_from_firestore'] == true) {
                // Handle Firestore result
                setState(() {
                  final firestoreData = food['firestore_data'];
                  _selectedFoodDetails = {
                    'food_name': food['food_name'],
                    'food_id': food['food_id'],
                    'servings': {
                      'serving': [
                        {
                          'serving_description': firestoreData['serving']['description']?.toString() ?? '1 serving',
                          'calories': firestoreData['nutrition_per_serving']['calories']?.toString() ?? '0',
                          'carbohydrate': firestoreData['nutrition_per_serving']['carbs']?.toString() ?? '0',
                          'protein': firestoreData['nutrition_per_serving']['protein']?.toString() ?? '0',
                          'fat': firestoreData['nutrition_per_serving']['fat']?.toString() ?? '0',
                          'serving_id': 'firestore_${food['food_id']}',
                        }
                      ]
                    }
                  };
                  _selectedServing = _selectedFoodDetails!['servings']['serving'][0];
                  _currentView = _FoodSheetView.detail;
                });
              } else {
                // Handle Fatsecret API result
                _getFoodDetails(food['food_id']);
              }
            },
          ),
        );
      },
    );
  }

  // Builds the detail view.
  Widget _buildDetailView() {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (_selectedFoodDetails == null) {
      return const Center(
        child: Text('Something went wrong. Please try again.'),
      );
    }

    final foodName = _selectedFoodDetails!['food_name'];

    final servingsRaw = _selectedFoodDetails!['servings']?['serving'];
    final List<dynamic> servings = servingsRaw is List
        ? servingsRaw
        : [servingsRaw];

    return SingleChildScrollView(
      key: const ValueKey('detailView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToSearch,
              ),
              Expanded(
                child: Text(
                  foodName,
                  style: theme.textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: screenWidth * 0.55,
                child: DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedServing,
                  isExpanded: true,
                  items: servings.map<DropdownMenuItem<Map<String, dynamic>>>((
                    s,
                  ) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: s,
                      child: Text(
                        s['serving_description']?.toString() ?? 'Unknown Serving',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedServing = newValue;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Serving Size'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_selectedServing != null) _buildNutritionPreview(theme),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _goBackToSearch,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addToDiary,
                child: const Text('Add to Diary'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds the nutrition preview.
  Widget _buildNutritionPreview(ThemeData theme) {
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;

    final calories = _parseServingValue(_selectedServing!['calories']);
    final carbs = _parseServingValue(_selectedServing!['carbohydrate']);
    final protein = _parseServingValue(_selectedServing!['protein']);
    final fat = _parseServingValue(_selectedServing!['fat']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNutritionItem('Calories', calories * quantity, 'kcal'),
            _buildNutritionItem('Carbs', carbs * quantity, 'g'),
            _buildNutritionItem('Protein', protein * quantity, 'g'),
            _buildNutritionItem('Fat', fat * quantity, 'g'),
          ],
        ),
      ),
    );
  }

  // Builds a nutrition item.
  Widget _buildNutritionItem(String label, double value, String unit) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(0),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(unit, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
