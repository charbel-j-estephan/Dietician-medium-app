// This file contains the login page of the application.

import 'package:calories_tracking/widgets/theme_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'signup_page.dart';
import 'package:calories_tracking/providers/theme_provider.dart';

// The LoginPage widget is a stateful widget that displays the login form.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for the email and password text fields.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // State variables for loading and password visibility.
  bool _loading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // Dispose the controllers when the widget is disposed.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Logs in the user with the provided email and password.
  Future<void> _login() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Sign in with email and password using Firebase Auth.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Handle different authentication errors.
      String msg = "An error occurred. Please try again.";
      if (e.code == "invalid-email") {
        msg = "Please enter a valid email address.";
      }
      if (e.code == "user-not-found" || e.code == "wrong-password") {
        msg = "Invalid credentials. Please check your email and password.";
      }
      if (e.code == "user-disabled") msg = "This account has been disabled.";

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
    final themeProvider = Provider.of<AppThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme, themeProvider),
              const SizedBox(height: 40),
              _buildEmailField(theme),
              const SizedBox(height: 18),
              _buildPasswordField(theme),
              const SizedBox(height: 28),
              _buildLoginButton(theme),
              const SizedBox(height: 18),
              _buildSignupButton(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the header of the login page.
  Widget _buildHeader(ThemeData theme, AppThemeProvider themeProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String assetName = isDarkMode
        ? 'assets/icons/app_icon-dark-mode.png'
        : 'assets/icons/app_icon.png';

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          height: 120, // Increased size
          width: 120, // Increased size
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.scaffoldBackgroundColor, // More theme-dependent color
          ),
          child: ClipOval(
            child: Image.asset(
              assetName,
              height: 120, // Increased size
              width: 120, // Increased size
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Welcome Back",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Log in to keep an eye on your daily calories.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  // Builds the email text field.
  Widget _buildEmailField(ThemeData theme) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email Address',
        prefixIcon: const Icon(Icons.email_outlined, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
      ),
    );
  }

  // Builds the password text field.
  Widget _buildPasswordField(ThemeData theme) {
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
    );
  }

  // Builds the login button.
  Widget _buildLoginButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _loading ? null : _login,
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
          : const Text("Login"),
    );
  }

  // Builds the signup button.
  Widget _buildSignupButton(BuildContext context, ThemeData theme) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupPage()),
        );
      },
      child: Text.rich(
        TextSpan(
          text: "New here? ",
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          children: [
            TextSpan(
              text: "Create an account",
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


