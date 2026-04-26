import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditFoodPage extends StatefulWidget {
  final String foodId;
  final Map<String, dynamic> foodData;

  const EditFoodPage({super.key, required this.foodId, required this.foodData});

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _arabicNameController;
  late TextEditingController _categoryController;
  late TextEditingController _subcategoryController;
  late TextEditingController _servingDescriptionController;
  late TextEditingController _servingGramsController;
  late TextEditingController _caloriesController;
  late TextEditingController _carbsController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.foodData['name']);
    _arabicNameController = TextEditingController(text: widget.foodData['arabic_name']);
    _categoryController = TextEditingController(text: widget.foodData['category']);
    _subcategoryController = TextEditingController(text: widget.foodData['subcategory']);

    final serving = widget.foodData['serving'] as Map<String, dynamic>?;
    _servingDescriptionController = TextEditingController(text: serving?['description']);
    _servingGramsController = TextEditingController(text: serving?['grams']?.toString());

    final nutritionPerServing = widget.foodData['nutrition_per_serving'] as Map<String, dynamic>?;
    _caloriesController = TextEditingController(text: nutritionPerServing?['calories']?.toString());
    _carbsController = TextEditingController(text: nutritionPerServing?['carbs']?.toString());
    _proteinController = TextEditingController(text: nutritionPerServing?['protein']?.toString());
    _fatController = TextEditingController(text: nutritionPerServing?['fat']?.toString());
  }

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
          'tags': widget.foodData['tags'] ?? [], // Preserve existing tags
        };

        await FirebaseFirestore.instance.collection('foods').doc(widget.foodId).update(foodData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food updated successfully!')),
          );
          Navigator.of(context).pop(); // Go back to the previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update food: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Food'),
      ),
      body: _isLoading
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
                        'Update Food',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
