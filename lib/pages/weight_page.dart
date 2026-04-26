// This page displays the user's weight history and allows them to record new weight entries.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

// A data class for a weight entry.
class WeightEntry {
  final DateTime date;
  final double weight;
  final double fat;
  final double muscle;
  final double water;

  WeightEntry({
    required this.date,
    required this.weight,
    required this.fat,
    required this.muscle,
    required this.water,
  });

  // A factory constructor to create a WeightEntry from a Firestore document.
  factory WeightEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return WeightEntry(
      date:
          (data.containsKey('timestamp')
                  ? data['timestamp'] as Timestamp
                  : data['date'] as Timestamp)
              .toDate(),
      weight:
          (data.containsKey('weight')
                  ? data['weight'] as num? ?? 0.0
                  : data['weightKg'] as num? ?? 0.0)
              .toDouble(),
      fat:
          (data.containsKey('fat')
                  ? data['fat'] as num? ?? 0.0
                  : data['fatKg'] as num? ?? 0.0)
              .toDouble(),
      muscle:
          (data.containsKey('muscle')
                  ? data['muscle'] as num? ?? 0.0
                  : data['muscleKg'] as num? ?? 0.0)
              .toDouble(),
      water:
          (data.containsKey('water')
                  ? data['water'] as num? ?? 0.0
                  : data['waterKg'] as num? ?? 0.0)
              .toDouble(),
    );
  }
}

// The WeightPage widget is a stateful widget that displays the weight page.
class WeightPage extends StatefulWidget {
  final String? clientUid;
  final String? clientName;

  const WeightPage({super.key, this.clientUid, this.clientName});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  // The current user.
  final User? currentUser = FirebaseAuth.instance.currentUser;
  // A list of weight entries.
  List<WeightEntry> _weightData = [];
  // A boolean to indicate if the data is loading.
  bool _isLoading = true;

  // A boolean to indicate if the view is for a dietician.
  bool get isDieticianView => widget.clientUid != null;
  // The target user's ID.
  String get _targetUid => widget.clientUid ?? currentUser!.uid;

  // A map of visible metrics.
  final Map<String, bool> _visibleMetrics = {
    'weight': true,
    'fat': false,
    'muscle': false,
    'water': false,
  };

  // A map of metric colors.
  late Map<String, Color> _metricColors;

  // The collection reference for the weights.
  CollectionReference<Map<String, dynamic>> get weightsRef => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_targetUid)
      .collection('weights');

  @override
  void initState() {
    super.initState();
    // Load the weight data when the widget is initialized.
    _loadWeightData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the metric colors.
    final theme = Theme.of(context);
    _metricColors = {
      'weight': theme.primaryColor,
      'fat': Colors.orange.shade400,
      'muscle': Colors.red.shade400,
      'water': Colors.cyan.shade400,
    };
  }

  // Loads the weight data from Firestore.
  Future<void> _loadWeightData() async {
    if (currentUser == null && !isDieticianView) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    try {
      final querySnapshot = await weightsRef.orderBy('timestamp').get();
      _weightData = querySnapshot.docs
          .map((doc) => WeightEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load weight data: $e')),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }



  // Shows the weight entry form.
  void _showWeightEntryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WeightEntryForm(
        onSave: (weight, fat, muscle, water) async {
          try {
            await weightsRef.add({
              'weight': weight,
              'fat': fat,
              'muscle': muscle,
              'water': water,
              'timestamp': Timestamp.now(),
            });
            Navigator.pop(context);
            _loadWeightData();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save weight: $e')),
              );
            }
          }
        },
      ),
    );
  }

  // Toggles the visibility of a metric.
  void _toggleMetric(String key) {
    setState(() {
      _visibleMetrics[key] = !_visibleMetrics[key]!;
    });
  }

  // Returns a list of active metric keys.
  List<String> get _activeMetricKeys =>
      _visibleMetrics.entries.where((e) => e.value).map((e) => e.key).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPageContent(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showWeightEntryForm,
              icon: const Icon(Icons.add),
              label: const Text('Record Weight'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Builds the content of the page.
  Widget _buildPageContent() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isDieticianView)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                Text(
                  isDieticianView
                      ? "${widget.clientName!.split(' ').first.toUpperCase()}'S WEIGHT HISTORY"
                      : 'Weight History',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isDieticianView ? 18 : null,
                  ),
                ),
                if (isDieticianView) const SizedBox(width: 48),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_weightData.isEmpty)
            Expanded(child: _buildEmptyState())
          else ...[
            _buildLatestStats(entry: _weightData.last),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
                child: LineChart(_buildChartData()),
              ),
            ),
            _buildLegend(),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // Builds the latest stats widget.
  Widget _buildLatestStats({required WeightEntry entry}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Weight', entry.weight, 'kg', _metricColors['weight']!),
          _summaryItem('Fat', entry.fat, 'kg', _metricColors['fat']!),
          _summaryItem('Muscle', entry.muscle, 'kg', _metricColors['muscle']!),
          _summaryItem('Water', entry.water, 'kg', _metricColors['water']!),
        ],
      ),
    );
  }

  // Builds a summary item widget.
  Widget _summaryItem(String label, double value, String unit, Color color) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Builds the legend widget.
  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _visibleMetrics.keys.map((key) {
        return _legendItem(key.capitalize(), _metricColors[key]!, key);
      }).toList(),
    );
  }

  // Builds a legend item widget.
  Widget _legendItem(String text, Color color, String key) {
    final isVisible = _visibleMetrics[key]!;
    return InkWell(
      onTap: () => _toggleMetric(key),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Opacity(
          opacity: isVisible ? 1.0 : 0.6,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the empty state widget.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No weight data yet.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the "Record Weight" button at the bottom to add your first entry!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Builds the chart data.
  LineChartData _buildChartData() {
    final theme = Theme.of(context);
    double minY = double.maxFinite;
    double maxY = 0;

    final visibleKeys = _activeMetricKeys;

    if (visibleKeys.isEmpty) {
      minY = 0;
      maxY = 100;
    } else {
      for (var entry in _weightData) {
        if (visibleKeys.contains('weight')) {
          minY = min(minY, entry.weight);
          maxY = max(maxY, entry.weight);
        }
        if (visibleKeys.contains('fat')) {
          minY = min(minY, entry.fat);
          maxY = max(maxY, entry.fat);
        }
        if (visibleKeys.contains('muscle')) {
          minY = min(minY, entry.muscle);
          maxY = max(maxY, entry.muscle);
        }
        if (visibleKeys.contains('water')) {
          minY = min(minY, entry.water);
          maxY = max(maxY, entry.water);
        }
      }
    }

    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    final padding = (maxY - minY) * 0.15;
    minY = max(0, minY - padding);
    maxY += padding;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: theme.dividerColor,
          strokeWidth: 1,
          dashArray: const [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(0),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: max(1, (_weightData.length / 4).floorToDouble()),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _weightData.length) {
                return const SizedBox();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  DateFormat('d MMM').format(_weightData[index].date),
                  style: theme.textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (_weightData.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: _activeMetricKeys
          .map((key) => _buildLine(key, _metricColors[key]!))
          .toList(),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: theme.dividerColor,
                strokeWidth: 1,
                dashArray: const [4, 4],
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 8,
                    color: barData.color ?? Colors.grey,
                    strokeColor: theme.cardColor,
                    strokeWidth: 2,
                  );
                },
              ),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => theme.cardColor,
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];

            final activeKeys = _activeMetricKeys;

            return touchedSpots
                .map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= _weightData.length) {
                    return null;
                  }
                  final entry = _weightData[index];

                  final barIndex = spot.barIndex;
                  if (barIndex < 0 || barIndex >= activeKeys.length) {
                    return null;
                  }
                  final metricKey = activeKeys[barIndex];

                  double value;
                  switch (metricKey) {
                    case 'weight':
                      value = entry.weight;
                      break;
                    case 'fat':
                      value = entry.fat;
                      break;
                    case 'muscle':
                      value = entry.muscle;
                      break;
                    case 'water':
                      value = entry.water;
                      break;
                    default:
                      value = entry.weight;
                  }

                  return LineTooltipItem(
                    "${metricKey.capitalize()}: ${value.toStringAsFixed(1)} kg",
                    TextStyle(
                      color: _metricColors[metricKey],
                      fontWeight: FontWeight.bold,
                    ),
                  );
                })
                .whereType<LineTooltipItem>()
                .toList();
          },
        ),
      ),
    );
  }

  // Builds a line for the chart.
  LineChartBarData _buildLine(String type, Color color) {
    return LineChartBarData(
      spots: _weightData.asMap().entries.map((entry) {
        double y;
        switch (type) {
          case 'weight':
            y = entry.value.weight;
            break;
          case 'fat':
            y = entry.value.fat;
            break;
          case 'muscle':
            y = entry.value.muscle;
            break;
          case 'water':
            y = entry.value.water;
            break;
          default:
            throw Error();
        }
        return FlSpot(entry.key.toDouble(), y);
      }).toList(),
      isCurved: false,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

// An extension to capitalize the first letter of a string.
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// The _WeightEntryForm widget is a stateful widget that displays the weight entry form.
class _WeightEntryForm extends StatefulWidget {
  final Function(double weight, double fat, double muscle, double water) onSave;

  const _WeightEntryForm({required this.onSave});

  @override
  __WeightEntryFormState createState() => __WeightEntryFormState();
}

class __WeightEntryFormState extends State<_WeightEntryForm> {
  // The global key for the form.
  final _formKey = GlobalKey<FormState>();
  // Controllers for the text fields.
  final _weightController = TextEditingController();
  final _fatController = TextEditingController();
  final _muscleController = TextEditingController();
  final _waterController = TextEditingController();
  // A boolean to indicate if the data is loading.
  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose the controllers when the widget is disposed.
    _weightController.dispose();
    _fatController.dispose();
    _muscleController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  // Submits the weight entry form.
  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final double weight = double.parse(_weightController.text);
      final double fat = double.parse(_fatController.text);
      final double muscle = double.parse(_muscleController.text);
      final double water = double.parse(_waterController.text);

      widget.onSave(weight, fat, muscle, water);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                'Record New Weight',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _weightController,
                label: 'Total Weight (kg)',
                icon: Icons.monitor_weight_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _fatController,
                label: 'Fat (kg)',
                icon: Icons.show_chart,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _muscleController,
                label: 'Muscle (kg)',
                icon: Icons.fitness_center,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _waterController,
                label: 'Water (kg)',
                icon: Icons.water_drop_outlined,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Entry'),
                      style: theme.elevatedButtonTheme.style?.copyWith(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds a text form field.
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Cannot be empty';
        if (double.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }
}
