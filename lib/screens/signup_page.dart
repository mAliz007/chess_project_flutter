// Location: lib/screens/signup_page.dart

import 'package:flutter/material.dart'; // Flutter UI package
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import '../controllers/auth_controller.dart'; // Custom Auth controller

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState(); // Create state for the page
}

class _SignupPageState extends State<SignupPage> {
  final AuthController _authController = AuthController(); // Instance of AuthController

  // Controllers for input fields
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _loading = false; // Loading state for signup process

  // Function to show temporary messages at the bottom of the screen
  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), // Message text
        backgroundColor: isError ? Colors.redAccent : Colors.greenAccent, // Color based on error or success
      ),
    );
  }

  // --- FIXED SIGNUP FUNCTION ---
  Future<void> _handleSignup() async {
    // Check if passwords match
    if (_passwordController.text != _confirmController.text) {
      _showMessage("Passwords do not match", isError: true);
      return;
    }

    setState(() => _loading = true); // Set loading state to true
    try {
      // Call signup function from AuthController
      await _authController.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      
      // Navigate to Home page on successful signup
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
      
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific signup errors
      _showMessage(e.message ?? "Signup failed", isError: true);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      // Handle any other errors
      _showMessage("An unexpected error occurred", isError: true);
      if (mounted) setState(() => _loading = false);
    } 
  }

  // --- FIXED GOOGLE SIGNUP FUNCTION ---
  Future<void> _handleGoogleSignup() async {
    setState(() => _loading = true); // Set loading state
    try {
      await _authController.signInWithGoogle(); // Call Google sign-in
      
      // Navigate to Home page on success
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
      
    } catch (e) {
      _showMessage("Google Sign-In failed", isError: true); // Show error message
      if (mounted) setState(() => _loading = false);
    } 
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor; // Get theme primary color

    return Stack(
      children: [
        // 1. BACKGROUND IMAGE
        Positioned.fill(
          child: Image.asset(
            'assets/images/chess_bg.jpg', // Background image
            fit: BoxFit.cover, // Cover entire screen
          ),
        ),

        // 2. PURPLE OVERLAY
        Positioned.fill(
          child: Container(
            color: Color(0xFF120E29).withOpacity(0.85), // Dark semi-transparent overlay
          ),
        ),

        // 3. THE FORM
        Scaffold(
          backgroundColor: Colors.transparent, // Make scaffold transparent
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white), // Back icon
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'), // Navigate back to login
            ),
            backgroundColor: Colors.transparent, // Transparent app bar
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10), // Form padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  // QUEEN LOGO
                  Container(
                    height: 100, // Container height
                    width: 100, // Container width
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1), // Slightly transparent white
                      shape: BoxShape.circle, // Circle shape
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2), // Border
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.5), // Shadow color
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "♛", // Queen chess symbol
                        style: TextStyle(
                          fontSize: 60,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 10.0, color: Colors.black45, offset: Offset(2.0, 2.0)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20), // Spacing
                  
                  Text(
                    "JOIN THE ARENA", // Headline
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                  ),
                  Text(
                    "Create your Grandmaster account", // Subheadline
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  SizedBox(height: 30), // Spacing

                  // INPUTS
                  _buildTextField("Email Address", _emailController, false), // Email input
                  SizedBox(height: 16), // Spacing
                  _buildTextField("Password", _passwordController, true), // Password input
                  SizedBox(height: 16), // Spacing
                  _buildTextField("Confirm Password", _confirmController, true), // Confirm password
                  
                  SizedBox(height: 30), // Spacing

                  // BUTTONS
                  _loading
                      ? CircularProgressIndicator(color: Colors.white) // Show loader if loading
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: _handleSignup, // Signup button
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, 
                                foregroundColor: primaryColor, 
                              ),
                              child: Text("CREATE ACCOUNT"),
                            ),
                            SizedBox(height: 16), // Spacing
                            
                            ElevatedButton.icon(
                              onPressed: _handleGoogleSignup, // Google signup button
                              icon: Image.asset(
                                'assets/images/google_logo.jpg', // Google logo
                                height: 24,
                              ),
                              label: Text("Sign up with Google"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 2,
                              ),
                            ),
                            SizedBox(height: 24), // Spacing

                            // LOGIN LINK
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Already have an account?", style: TextStyle(color: Colors.white70)),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'), // Navigate to login
                                  child: Text(
                                    "Login", 
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
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

  // Function to build reusable text fields
  Widget _buildTextField(String label, TextEditingController controller, bool isObscure) {
    return TextField(
      controller: controller, // Controller for the field
      obscureText: isObscure, // Hide text if password
      style: TextStyle(color: Colors.white), // Text style
      decoration: InputDecoration(
        labelText: label, // Field label
        labelStyle: TextStyle(color: Colors.white70), // Label color
        fillColor: Colors.black.withOpacity(0.3), // Background color
        filled: true, // Enable filled background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), // Rounded corners
          borderSide: BorderSide.none, // No border line
        ),
      ),
    );
  }
}
