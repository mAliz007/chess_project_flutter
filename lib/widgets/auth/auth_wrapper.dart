// Location: lib/widgets/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
// Core package for interacting with Firebase Authentication services
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/home_page.dart'; // The screen for logged-in users
import '../../screens/login_page.dart'; // The screen for logged-out users

/// Checks if user is logged in, redirects accordingly
class AuthWrapper extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        // StreamBuilder listens to the stream and rebuilds the UI when the data changes.
        // It expects a User object or null.
        return StreamBuilder<User?>(
            // THE CORE FUNCTION: This stream provides updates on the user's login status.
            // It is the source of truth for authentication in the app.
            stream: FirebaseAuth.instance.authStateChanges(),
            
            // The builder function decides which widget (screen) to show.
            builder: (context, snapshot) {
                
                // 1. LOADING STATE: Check if the connection to Firebase is still establishing.
                if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                        body: Center(
                            child: CircularProgressIndicator(), // Show a spinner
                        ),
                    );
                }

                // 2. LOGGED-IN STATE: Check if the snapshot contains a non-null User object.
                // This means Firebase confirms the user is signed in.
                if (snapshot.hasData && snapshot.data != null) {
                    return HomePage(); // Take them to the main app screen.
                }

                // 3. LOGGED-OUT STATE: If not loading and no user data, they are logged out.
                return LoginPage(); // Take them to the screen where they can sign in.
            },
        );
    }
}