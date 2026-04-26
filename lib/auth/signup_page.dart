// This file contains the signup page of the application.

import 'package:calories_tracking/main.dart';
import 'package:calories_tracking/widgets/theme_toggle_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The SignupPage widget is a stateful widget that displays the signup form.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Global key for the form.
  final _formKey = GlobalKey<FormState>();
  // Controllers for the text fields.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _weightController = TextEditingController();
  final _muscleController = TextEditingController();
  final _fatController = TextEditingController();
  final _waterController = TextEditingController();

  // State variables for sex, loading, and password visibility.
  String? _selectedSex;
  bool _loading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    // Dispose the controllers when the widget is disposed.
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _weightController.dispose();
    _muscleController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  // Signs up the user with the provided information.
  Future<void> _signup() async {
    // Validate the form.
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Check if the sex is selected.
    if (_selectedSex == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select your sex.")));
      return;
    }

    setState(() => _loading = true);

    // Parse the weight, muscle, fat, and water values.
    final double? weightKg = double.tryParse(_weightController.text.trim());
    final double? muscleKg = double.tryParse(_muscleController.text.trim());
    final double? fatKg = double.tryParse(_fatController.text.trim());
    final double? waterKg = double.tryParse(_waterController.text.trim());

    // Check if the weight, muscle, fat, and water values are valid numbers.
    if (weightKg == null ||
        muscleKg == null ||
        fatKg == null ||
        waterKg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Weight, muscle, fat, and water must be valid numbers.",
          ),
        ),
      );
      setState(() => _loading = false);
      return;
    }







    try {
      // Create a new user with email and password using Firebase Auth.
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final String uid = userCredential.user!.uid;

      // Add the user's data to Firestore.
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "sex": _selectedSex,
        "role": "client",
      });

      // Add the user's initial weight to Firestore.
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("weights")
          .add({
            'timestamp': Timestamp.now(),
            'weight': weightKg,
            'fat': fatKg,
            'muscle': muscleKg,
            'water': waterKg,
          });

      // Save the user's weight and has_completed_first_login_setup to shared preferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('weight', weightKg);
      await prefs.setBool('has_completed_first_login_setup', true);

      // Navigate to the home page if the widget is still mounted.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CaloriesApp()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Handle different authentication errors.
      String msg = "An error occurred. Please try again.";
      if (e.code == "email-already-in-use") {
        msg = "This email is already registered.";
      }
      if (e.code == "invalid-email") {
        msg = "Please enter a valid email address.";
      }
      if (e.code == "weak-password") {
        msg = "Password is too weak (min. 6 characters).";
      }

      // Show a snackbar with the error message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 32),
                _buildTextFormField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (val) =>
                      val?.isEmpty ?? true ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) =>
                      val?.isEmpty ?? true ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildConfirmPasswordField(),
                const SizedBox(height: 16),
                _buildDropdown(theme),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextFormField(
                        controller: _fatController,
                        label: 'Fat (kg)',
                        icon: Icons.show_chart,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        controller: _muscleController,
                        label: 'Muscle (kg)',
                        icon: Icons.fitness_center,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextFormField(
                        controller: _waterController,
                        label: 'Water (kg)',
                        icon: Icons.water_drop_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSignupButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds the header of the signup page.
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          "Let’s Get Started",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Set up your tracker in less than a minute.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  // Builds a text form field with the given controller, label, icon, validator, and keyboard type.
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
      ),
      validator: validator,
    );
  }

  // Builds the password text field.
  Widget _buildPasswordField() {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
      ),
      validator: (val) => (val?.length ?? 0) < 6
          ? 'Password must be at least 6 characters'
          : null,
    );
  }

  // Builds the confirm password text field.
  Widget _buildConfirmPasswordField() {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () => setState(
            () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
      ),
      validator: (val) =>
          val != _passwordController.text ? 'Passwords do not match' : null,
    );
  }

  // Builds the sex dropdown.
  Widget _buildDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedSex,
      decoration: InputDecoration(
        labelText: 'Sex',
        prefixIcon: const Icon(Icons.wc_outlined, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
      ),
      items: ["Male", "Female"]
          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
          .toList(),
      onChanged: (value) => setState(() => _selectedSex = value),
      validator: (value) => value == null ? 'Please select your sex' : null,
    );
  }

  // Builds the signup button.
  Widget _buildSignupButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _loading ? null : _signup,
      style: theme.elevatedButtonTheme.style,
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text("Create Account"),
    );
  }
}
