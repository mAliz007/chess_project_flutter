// Location: lib/screens/login_page.dart

import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication exceptions
import '../controllers/auth_controller.dart'; // Custom controller that handles auth logic

// LoginPage is a StatefulWidget because it manages mutable state (loading, text input)
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState(); // Creates the mutable state object
}

// State class where all logic, controllers, and UI live
class _LoginPageState extends State<LoginPage> {
  final AuthController _authController = AuthController(); // Handles Firebase auth actions

  final TextEditingController _emailController = TextEditingController(); // Controls email TextField
  final TextEditingController _passwordController = TextEditingController(); // Controls password TextField

  bool _loading = false; // Tracks whether a login request is in progress

  // Shows feedback messages (success or error) using SnackBar
  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar( // Accesses Scaffold context
      SnackBar(
        content: Text(msg), // Message text
        backgroundColor: isError ? Colors.redAccent : Colors.greenAccent, // Color based on result
      ),
    );
  }

  // Handles email/password login
  Future<void> _handleLogin() async {
    setState(() => _loading = true); // Show loading indicator

    try {
      await _authController.signInWithEmail( // Calls Firebase email login
        _emailController.text, // Email entered by user
        _passwordController.text, // Password entered by user
      );

      // Navigate to Home only if widget is still mounted
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil( // Clears navigation stack
          '/home', // Destination route
          (route) => false, // Removes all previous routes
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Login failed", isError: true); // Show Firebase error

      if (mounted) setState(() => _loading = false); // Stop loading on failure
    }
  }

  // Handles Google Sign-In login
  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true); // Start loading

    try {
      await _authController.signInWithGoogle(); // Google OAuth login

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil( // Navigate to Home
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      _showMessage("Google Sign-In failed", isError: true); // Generic error message

      if (mounted) setState(() => _loading = false); // Stop loading on failure
    }
  }

  // Sends password reset email
  Future<void> _handleForgotPassword() async {
    try {
      await _authController.sendPasswordReset( // Firebase reset email
        _emailController.text, // Email entered by user
      );
      _showMessage("Reset link sent!"); // Success feedback
    } catch (e) {
      _showMessage("Enter a valid email first", isError: true); // Error feedback
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor; // App theme primary color

    return Stack( // Stack used to layer background + overlay + UI
      children: [
        // BACKGROUND IMAGE
        Positioned.fill(
          child: Image.asset(
            'assets/images/chess_bg.jpg', // Chess-themed background
            fit: BoxFit.cover, // Covers entire screen
          ),
        ),

        // DARK PURPLE OVERLAY
        Positioned.fill(
          child: Container(
            color: const Color(0xFF120E29).withOpacity(0.85), // Dark overlay for contrast
          ),
        ),

        // MAIN LOGIN UI
        Scaffold(
          backgroundColor: Colors.transparent, // Allows background to show
          body: Center(
            child: SingleChildScrollView( // Prevents overflow on small screens
              padding: const EdgeInsets.all(24), // Page padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                children: [
                  // QUEEN LOGO
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1), // Semi-transparent circle
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.5), // Glow effect
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "♛", // Chess queen symbol
                        style: TextStyle(
                          fontSize: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24), // Spacing

                  Text(
                    "CHESS MASTER", // App title
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    "Ranked Mobile Chess", // Subtitle
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),

                  const SizedBox(height: 40), // Spacing

                  // EMAIL INPUT
                  _buildTextField("Email", _emailController, false),
                  const SizedBox(height: 16),

                  // PASSWORD INPUT
                  _buildTextField("Password", _passwordController, true),

                  const SizedBox(height: 30),

                  // LOGIN / LOADING AREA
                  _loading
                      ? const CircularProgressIndicator(color: Colors.white) // Loading spinner
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // EMAIL LOGIN BUTTON
                            ElevatedButton(
                              onPressed: _handleLogin, // Triggers email login
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                              ),
                              child: const Text("LOGIN"),
                            ),

                            const SizedBox(height: 16),

                            // GOOGLE LOGIN BUTTON
                            ElevatedButton.icon(
                              onPressed: _handleGoogleLogin, // Triggers Google login
                              icon: Image.asset(
                                'assets/images/google_logo.jpg', // Google logo
                                height: 24,
                              ),
                              label: const Text("Sign in with Google"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // FORGOT PASSWORD
                            TextButton(
                              onPressed: _handleForgotPassword, // Reset password
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),

                            // SIGN UP LINK
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "New player?",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacementNamed(
                                    context,
                                    '/signup', // Navigate to signup page
                                  ),
                                  child: const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Reusable styled text field widget
  Widget _buildTextField(
    String label, // Field label
    TextEditingController controller, // Controller managing input
    bool isObscure, // Whether text should be hidden
  ) {
    return TextField(
      controller: controller, // Links controller
      obscureText: isObscure, // Hides text for passwords
      style: const TextStyle(color: Colors.white), // Input text color
      decoration: InputDecoration(
        labelText: label, // Floating label
        labelStyle: const TextStyle(color: Colors.white70),
        fillColor: Colors.black.withOpacity(0.3), // Dark background
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), // Rounded edges
          borderSide: BorderSide.none, // No border line
        ),
      ),
    );
  }
}
