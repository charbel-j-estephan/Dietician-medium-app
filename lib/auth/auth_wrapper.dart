// This widget is a wrapper that handles authentication state and role-based routing.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/home_page.dart';
import '../pages/dietician_home_page.dart';
import 'login_page.dart';

// The AuthWrapper widget checks the user's authentication state and role.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    // Use a StreamBuilder to listen to authentication state changes.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while the connection state is waiting.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the user is authenticated, check their role.
        if (snapshot.hasData) {
          final User user = snapshot.data!;
          // Use a FutureBuilder to get the user's document from Firestore.
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userDocSnapshot) {
              // Show a loading indicator while waiting for the user document.
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // If the user document exists, check the role.
              if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
                final data =
                    userDocSnapshot.data!.data() as Map<String, dynamic>?;
                final role = data?['role'];

                // Navigate to the appropriate home page based on the role.
                if (role == 'dietician') {
                  return const DieticianHomePage();
                } else {
                  return const HomePage();
                }
              }

              // If the user document doesn't exist, navigate to the login page.
              return const LoginPage();
            },
          );
        }

        // If the user is not authenticated, navigate to the login page.
        return const LoginPage();
      },
    );
  }
}
