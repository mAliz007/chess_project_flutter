// Location: lib/widgets/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/home_page.dart';
import '../../screens/login_page.dart';

/// Checks if user is logged in, redirects accordingly
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Waiting for Firebase to initialize or check status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, go to Home
        if (snapshot.hasData && snapshot.data != null) {
          return HomePage();
        }

        // Otherwise show Login page
        return LoginPage();
      },
    );
  }
}