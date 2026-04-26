// This page displays the details of a diary entry.

import 'package:calories_tracking/widgets/theme_toggle_button.dart';
import 'package:flutter/material.dart';

// The EntryDetailPage widget is a stateless widget that displays the details of a diary entry.
class EntryDetailPage extends StatelessWidget {
  final Map<String, dynamic> entry;
  final Function(String) onDelete;

  const EntryDetailPage({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExercise = entry['type'] == 'exercise';
    final String title = entry['name'] as String? ?? 'Entry Details';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        actions: [
          const ThemeToggleButton(),
          // The delete button.
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, title, isExercise),
            const SizedBox(height: 28),
            _buildNutritionCard(context, isExercise),
            const SizedBox(height: 20),
            // Display the serving size if it's a food entry.
            if (!isExercise &&
                (entry['servingDescription'] != null &&
                    entry['servingDescription'].isNotEmpty))
              _buildInfoCard(
                context,
                icon: Icons.pie_chart_outline,
                title: 'Serving Size',
                content: entry['servingDescription'],
              ),
          ],
        ),
      ),
    );
  }

  // Shows a confirmation dialog before deleting an entry.
  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: theme.cardColor,
          title: const Text('Confirm Deletion'),
          content: const Text(
            'Are you sure you want to delete this entry? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: () {
                onDelete(entry['id']);
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  // Builds the header of the entry detail page.
  Widget _buildHeader(BuildContext context, String title, bool isExercise) {
    final theme = Theme.of(context);
    final calorieColor = isExercise
        ? Colors.green.shade400
        : theme.primaryColor;

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: calorieColor.withOpacity(0.1),
          child: Icon(
            isExercise ? Icons.fitness_center : Icons.restaurant_menu,
            color: calorieColor,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${isExercise ? '-' : '+'}${double.tryParse(entry['calories'].toString())?.toStringAsFixed(0) ?? '0'} kcal',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: calorieColor,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ],
    );
  }

  // Builds the nutrition card.
  Widget _buildNutritionCard(BuildContext context, bool isExercise) {
    if (isExercise) return const SizedBox.shrink();

    final Map<String, dynamic> nutritionData = {
      'Carbs': entry['carbs'],
      'Protein': entry['protein'],
      'Fat': entry['fat'],
    };

    return Card(
      elevation: 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: nutritionData.entries.map((item) {
            return _nutritionItem(
              context,
              item.key,
              item.value,
              _getColorForNutrient(context, item.key),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Returns the color for the given nutrient.
  Color _getColorForNutrient(BuildContext context, String nutrient) {
    switch (nutrient) {
      case 'Carbs':
        return Colors.orange.shade700;
      case 'Protein':
        return Colors.red.shade500;
      case 'Fat':
        return Colors.purple.shade400;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  // Builds a nutrition item.
  Widget _nutritionItem(
    BuildContext context,
    String label,
    dynamic value,
    Color color,
  ) {
    final theme = Theme.of(context);
    final String displayValue =
        (double.tryParse(value.toString())?.toStringAsFixed(1) ?? '0.0');

    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$displayValue g',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  // Builds an info card.
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, color: theme.primaryColor, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
