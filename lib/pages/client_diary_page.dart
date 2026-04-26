// This page is for dieticians to view a specific client's diary entries.

import 'package:calories_tracking/widgets/theme_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:collection';

// A data class to hold the calculated daily totals for macros and calories.
class _DailyTotals {
  final double totalCalories;
  final double totalCarbs;
  final double totalProtein;
  final double totalFat;

  _DailyTotals({
    this.totalCalories = 0.0,
    this.totalCarbs = 0.0,
    this.totalProtein = 0.0,
    this.totalFat = 0.0,
  });
}

// An enum to define the available date filter ranges.
enum DateFilter { thisWeek, last14, last30 }

// This widget displays the client's diary page.
class ClientDiaryPage extends StatefulWidget {
  final String clientUid;
  final String clientName;

  const ClientDiaryPage({
    super.key,
    required this.clientUid,
    required this.clientName,
  });

  @override
  State<ClientDiaryPage> createState() => _ClientDiaryPageState();
}

class _ClientDiaryPageState extends State<ClientDiaryPage> {
  // State variables for the date filter and date range.
  DateFilter _selectedFilter = DateFilter.thisWeek;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update the date range when the widget is initialized.
    _updateDateRange();
  }

  // Updates the start and end dates based on the selected filter.
  void _updateDateRange() {
    final now = DateTime.now();
    setState(() {
      switch (_selectedFilter) {
        case DateFilter.thisWeek:
          _startDate = _getStartOfDay(
            now.subtract(Duration(days: now.weekday - 1)),
          );
          _endDate = _getEndOfDay(now);
          break;
        case DateFilter.last14:
          _startDate = _getStartOfDay(now.subtract(const Duration(days: 13)));
          _endDate = _getEndOfDay(now);
          break;
        case DateFilter.last30:
          _startDate = _getStartOfDay(now.subtract(const Duration(days: 29)));
          _endDate = _getEndOfDay(now);
          break;
      }
    });
  }

  // Groups diary entries by date.
  Map<DateTime, List<DocumentSnapshot>> _groupEntriesByDate(
    List<QueryDocumentSnapshot> docs,
  ) {
    // Use a SplayTreeMap to keep the dates sorted automatically.
    final grouped = SplayTreeMap<DateTime, List<DocumentSnapshot>>(
      (a, b) => b.compareTo(a),
    );
    for (var doc in docs) {
      final timestamp = doc['timestamp'] as Timestamp;
      final dateOnly = DateTime(
        timestamp.toDate().year,
        timestamp.toDate().month,
        timestamp.toDate().day,
      );
      grouped.update(dateOnly, (list) => [...list, doc], ifAbsent: () => [doc]);
    }
    return grouped;
  }

  // Utility function to safely parse a value from Firestore into a double.
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Calculates the totals for a given list of diary entries for one day.
  _DailyTotals _calculateTotals(List<DocumentSnapshot> entries) {
    double totalCalories = 0, totalCarbs = 0, totalProtein = 0, totalFat = 0;
    for (var entry in entries) {
      final data = entry.data() as Map<String, dynamic>;
      final calories = _parseDouble(data['calories']);

      if (data['type'] == 'exercise') {
        totalCalories -= calories;
      } else {
        totalCalories += calories;
        totalCarbs += _parseDouble(data['carbs']);
        totalProtein += _parseDouble(data['protein']);
        totalFat += _parseDouble(data['fat']);
      }
    }
    return _DailyTotals(
      totalCalories: totalCalories,
      totalCarbs: totalCarbs,
      totalProtein: totalProtein,
      totalFat: totalFat,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.clientName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          _DateFilterControl(
            selectedFilter: _selectedFilter,
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedFilter = newSelection.first;
                _updateDateRange();
              });
            },
          ),
          Expanded(child: _buildDiaryStream()),
        ],
      ),
    );
  }

  // The main StreamBuilder that listens to Firestore and builds the diary list.
  Widget _buildDiaryStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientUid)
          .collection('diary')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No diary entries for this period.'));
        }

        final groupedEntries = _groupEntriesByDate(snapshot.data!.docs);
        final sortedDates = groupedEntries.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            100,
          ),
          itemCount: sortedDates.length + 1,
          itemBuilder: (context, index) {
            if (index == sortedDates.length) {
              return const _NoMoreEntriesIndicator();
            }
            final date = sortedDates[index];
            final entries = groupedEntries[date]!;
            final totals = _calculateTotals(entries);
            return _DiaryCard(
              date: date,
              entries: entries,
              totals: totals,
              clientUid: widget.clientUid,
            );
          },
        );
      },
    );
  }

  // Returns the start of the day for the given date.
  DateTime _getStartOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  // Returns the end of the day for the given date.
  DateTime _getEndOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);
}

// A styled, reusable segmented button for date filtering.
class _DateFilterControl extends StatelessWidget {
  final DateFilter selectedFilter;
  final Function(Set<DateFilter>) onSelectionChanged;

  const _DateFilterControl({
    required this.selectedFilter,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SegmentedButton<DateFilter>(
          segments: const [
            ButtonSegment(value: DateFilter.thisWeek, label: Text('This Week')),
            ButtonSegment(
              value: DateFilter.last14,
              label: Text('Last 14 Days'),
            ),
            ButtonSegment(
              value: DateFilter.last30,
              label: Text('Last 30 Days'),
            ),
          ],
          selected: {selectedFilter},
          onSelectionChanged: onSelectionChanged,
          style: SegmentedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            backgroundColor: theme.cardColor,
            selectedBackgroundColor: theme.primaryColor.withOpacity(0.15),
            selectedForegroundColor: theme.primaryColor,
          ),
        ),
      ),
    );
  }
}

// A card that holds all diary entries for a single day.
class _DiaryCard extends StatelessWidget {
  final DateTime date;
  final List<DocumentSnapshot> entries;
  final _DailyTotals totals;
  final String clientUid;

  const _DiaryCard({
    required this.date,
    required this.entries,
    required this.totals,
    required this.clientUid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3.0,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: theme.cardColor.withOpacity(0.95),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d, y').format(date),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _WeightAndWaterDisplay(date: date, clientUid: clientUid),
            const Divider(height: 16, thickness: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) => _DiaryItemRow(
                data: entries[index].data() as Map<String, dynamic>,
                onTap: (Map<String, dynamic> p1) {},
              ),
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 8, endIndent: 8),
            ),
            const Divider(height: 16, thickness: 1),
            _TotalsSummary(totals: totals),
          ],
        ),
      ),
    );
  }
}

// Displays the client's weight and water intake for a specific day.
class _WeightAndWaterDisplay extends StatelessWidget {
  final DateTime date;
  final String clientUid;

  const _WeightAndWaterDisplay({required this.date, required this.clientUid});

  DateTime get _dayStart => DateTime(date.year, date.month, date.day);
  DateTime get _dayEnd => DateTime(date.year, date.month, date.day, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        // Weight Chip
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(clientUid)
              .collection('weights')
              .where('timestamp', isGreaterThanOrEqualTo: _dayStart)
              .where('timestamp', isLessThanOrEqualTo: _dayEnd)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }
            final weightData = snapshot.data!.docs.first;
            return Chip(
              avatar: Icon(
                Icons.monitor_weight_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
              label: Text(
                '${weightData['weight']} kg',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondary.withOpacity(0.1),
              side: BorderSide(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ),
            );
          },
        ),
        // Water Chip
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(clientUid)
              .collection('water')
              .where('timestamp', isGreaterThanOrEqualTo: _dayStart)
              .where('timestamp', isLessThanOrEqualTo: _dayEnd)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }
            double totalWater = snapshot.data!.docs.fold(0.0, (
              double sum,
              doc,
            ) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = data['intakeMl'];
              return sum + (amount is num ? amount.toDouble() : 0.0);
            });
            if (totalWater == 0) return const SizedBox.shrink();
            return Chip(
              avatar: Icon(
                Icons.water_drop_outlined,
                color: Colors.blue.shade300,
              ),
              label: Text(
                '${totalWater.toStringAsFixed(0)} ml',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.blue.withOpacity(0.1),
              side: BorderSide(color: Colors.blue.withOpacity(0.2)),
            );
          },
        ),
      ],
    );
  }
}

// A redesigned row for a single diary item (food or exercise).
class _DiaryItemRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onTap;

  const _DiaryItemRow({required this.data, required this.onTap});

  // Utility function to safely parse a value from Firestore into a double.
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExercise = data['type'] == 'exercise';
    final name = data['name'] as String? ?? 'Unknown';
    final calories = _parseDouble(data['calories']);
    final serving = data['servingDescription'] as String?;

    // Determine leading icon and color
    final icon = isExercise ? Icons.fitness_center : Icons.restaurant;
    final itemColor = isExercise
        ? Colors.green.shade400
        : theme.colorScheme.onSurface;

    String subtitleText = '';
    if (isExercise) {
      final duration = (data['duration_min'] as num?)?.toDouble();
      subtitleText = duration != null
          ? '${duration.toStringAsFixed(0)} min'
          : '';
    } else if (serving != null) {
      final quantity = (data['quantity'] as num?);
      if (quantity != null) {
        final isInt = quantity == quantity.truncateToDouble();
        final quantityText = isInt
            ? quantity.toStringAsFixed(0)
            : quantity.toStringAsFixed(1);
        subtitleText = '$quantityText x $serving';
      } else {
        subtitleText = serving;
      }
    }
    final caloriePrefix = isExercise
        ? '−'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        elevation: 1,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: itemColor.withOpacity(0.1),
            child: Icon(icon, color: itemColor),
          ),
          title: Text(
            name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitleText.isNotEmpty
              ? Text(
                  subtitleText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                )
              : null,
          trailing: Text(
            '$caloriePrefix${calories.toStringAsFixed(0)} kcal',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: itemColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () => onTap(data),
        ),
      ),
    );
  }
}

// A redesigned summary box for daily totals.
class _TotalsSummary extends StatelessWidget {
  final _DailyTotals totals;

  const _TotalsSummary({required this.totals});

  // A helper to build each column in the totals summary.
  Widget _buildTotalColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calColor = totals.totalCalories >= 0
        ? theme
              .colorScheme
              .error
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalColumn(
            context,
            label: 'Calories',
            value: totals.totalCalories.toStringAsFixed(0),
            color: calColor,
          ),
          _buildTotalColumn(
            context,
            label: 'Carbs',
            value: '${totals.totalCarbs.toStringAsFixed(0)}g',
            color: theme.colorScheme.secondary,
          ),
          _buildTotalColumn(
            context,
            label: 'Protein',
            value: '${totals.totalProtein.toStringAsFixed(0)}g',
            color: theme.colorScheme.tertiary,
          ),
          _buildTotalColumn(
            context,
            label: 'Fat',
            value: '${totals.totalFat.toStringAsFixed(0)}g',
            color: theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

// A simple, elegant indicator for the end of the list.
class _NoMoreEntriesIndicator extends StatelessWidget {
  const _NoMoreEntriesIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Text(
          'No more entries',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
