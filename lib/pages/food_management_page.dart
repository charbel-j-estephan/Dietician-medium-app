import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calories_tracking/pages/edit_food_page.dart'; // Added import

// Reusing the AddFoodPage content
class _AddFoodForm extends StatefulWidget {
  final VoidCallback onFoodAdded;
  const _AddFoodForm({required this.onFoodAdded});

  @override
  State<_AddFoodForm> createState() => _AddFoodFormState();
}

class _AddFoodFormState extends State<_AddFoodForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _arabicNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _servingDescriptionController = TextEditingController();
  final _servingGramsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final foodData = {
          'name': _nameController.text.trim(),
          'arabic_name': _arabicNameController.text.trim(),
          'category': _categoryController.text.trim(),
          'subcategory': _subcategoryController.text.trim(),
          'serving': {
            'description': _servingDescriptionController.text.trim(),
            'grams': double.parse(_servingGramsController.text.trim()),
          },
          'nutrition_per_serving': {
            'calories': double.parse(_caloriesController.text.trim()),
            'carbs': double.parse(_carbsController.text.trim()),
            'protein': double.parse(_proteinController.text.trim()),
            'fat': double.parse(_fatController.text.trim()),
          },
          'tags': [],
        };

        await FirebaseFirestore.instance.collection('foods').add(foodData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food added successfully!')),
          );
          _clearForm();
          widget.onFoodAdded(); // Notify parent to refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add food: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _arabicNameController.clear();
    _categoryController.clear();
    _subcategoryController.clear();
    _servingDescriptionController.clear();
    _servingGramsController.clear();
    _caloriesController.clear();
    _carbsController.clear();
    _proteinController.clear();
    _fatController.clear();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _validateDouble(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required.';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number.';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _arabicNameController.dispose();
    _categoryController.dispose();
    _subcategoryController.dispose();
    _servingDescriptionController.dispose();
    _servingGramsController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Food Name'),
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _arabicNameController,
                    decoration: const InputDecoration(labelText: 'Arabic Name (Optional)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subcategoryController,
                    decoration: const InputDecoration(labelText: 'Subcategory (Optional)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _servingDescriptionController,
                    decoration: const InputDecoration(labelText: 'Serving Description (e.g., "1 cup", "1 piece")'),
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _servingGramsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Serving Grams'),
                    validator: _validateDouble,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nutrition Per Serving',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Calories'),
                    validator: _validateDouble,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Carbohydrates (g)'),
                    validator: _validateDouble,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Protein (g)'),
                    validator: _validateDouble,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Fat (g)'),
                    validator: _validateDouble,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Food',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

// Reusing the ManageFoodsPage content
class _ManageFoodsList extends StatefulWidget {
  final VoidCallback onFoodDeleted;
  const _ManageFoodsList({required this.onFoodDeleted});

  @override
  State<_ManageFoodsList> createState() => _ManageFoodsListState();
}

class _ManageFoodsListState extends State<_ManageFoodsList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteFood(String foodId) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this food item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      try {
        await _firestore.collection('foods').doc(foodId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food deleted successfully!')),
          );
          widget.onFoodDeleted();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete food: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search foods...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('foods').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No foods found.'));
              }

              final filteredDocs = snapshot.data!.docs.where((doc) {
                final foodData = doc.data() as Map<String, dynamic>;
                final foodName = foodData['name']?.toString() ?? '';
                return foodName.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(child: Text('No foods found matching search.'));
              }

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final foodDoc = filteredDocs[index];
                  final foodData = foodDoc.data() as Map<String, dynamic>;
                  final foodName = foodData['name'] ?? 'Unnamed Food';
                  final foodId = foodDoc.id;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(foodName),
                      subtitle: Text(foodData['category'] ?? ''),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditFoodPage(
                              foodId: foodId,
                              foodData: foodData,
                            ),
                          ),
                        );
                        // No explicit refresh needed here because StreamBuilder handles it.
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFood(foodId),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class FoodManagementPage extends StatefulWidget {
  const FoodManagementPage({super.key});

  @override
  State<FoodManagementPage> createState() => _FoodManagementPageState();
}

class _FoodManagementPageState extends State<FoodManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0); // Set initialIndex to 0 for Manage Foods
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFoodAction() {
    // This can be used to trigger a rebuild of the list if needed,
    // though StreamBuilder handles it automatically.
    // For now, it just prints a message.
    debugPrint('Food action performed (added or deleted).');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Manage Foods', icon: Icon(Icons.list)), // Swapped order
            Tab(text: 'Add Food', icon: Icon(Icons.add_circle)), // Swapped order
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ManageFoodsList(onFoodDeleted: _onFoodAction), // Swapped order
          _AddFoodForm(onFoodAdded: _onFoodAction), // Swapped order
        ],
      ),
    );
  }
}