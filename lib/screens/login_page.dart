// Location: lib/screens/login_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.greenAccent,
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    try {
      await _authController.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Login failed", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);
    try {
      await _authController.signInWithGoogle();
    } catch (e) {
      _showMessage("Google Sign-In failed", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    try {
      await _authController.sendPasswordReset(_emailController.text);
      _showMessage("Reset link sent!");
    } catch (e) {
      _showMessage("Enter a valid email first", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the Indigo Primary Color from AppTheme
    final primaryColor = Theme.of(context).primaryColor;

    return Stack(
      children: [
        // 1. BACKGROUND IMAGE
        Positioned.fill(
          child: Image.asset(
            'assets/images/chess_bg.jpg', 
            fit: BoxFit.cover,
          ),
        ),

        // 2. PURPLE OVERLAY (Darker Midnight)
        Positioned.fill(
          child: Container(
            color: Color(0xFF120E29).withOpacity(0.85), // Dark Midnight overlay
          ),
        ),

        // 3. THE LOGIN FORM
        Scaffold(
          backgroundColor: Colors.transparent, 
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  // --- LOGO SECTION ---
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.5), // Glowing effect
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20), // Rounded corners for the logo
                      child: Image.asset(
                        'assets/images/main_logo.jpg',
                        height: 100, // Adjust size as needed
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  Text(
                    "CHESS MASTER",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    "Ranked Mobile Chess",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  SizedBox(height: 40),

                  // --- INPUTS ---
                  _buildTextField("Email", _emailController, false),
                  SizedBox(height: 16),
                  _buildTextField("Password", _passwordController, true),
                  
                  SizedBox(height: 30),

                  // --- BUTTONS ---
                  _loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Login Button
                            ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, 
                                foregroundColor: primaryColor, 
                              ),
                              child: Text("LOGIN"),
                            ),
                            SizedBox(height: 16),
                            
                            // Google Button
                            ElevatedButton.icon(
                              onPressed: _handleGoogleLogin,
                              icon: Image.asset(
                                'assets/images/google_logo.png', // Ensure this is .png or .jpg
                                height: 24,
                              ),
                              label: Text("Sign in with Google"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 2,
                              ),
                            ),
                            SizedBox(height: 24),

                            // Footer Links
                            TextButton(
                              onPressed: _handleForgotPassword,
                              child: Text(
                                "Forgot Password?", 
                                style: TextStyle(color: Colors.white70)
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("New player?", style: TextStyle(color: Colors.white70)),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                                  child: Text(
                                    "Create Account", 
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

  Widget _buildTextField(String label, TextEditingController controller, bool isObscure) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        fillColor: Colors.black.withOpacity(0.3), 
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}