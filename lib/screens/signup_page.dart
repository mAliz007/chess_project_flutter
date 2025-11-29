// Location: lib/screens/signup_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthController _authController = AuthController();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _loading = false;

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.greenAccent,
      ),
    );
  }

  // --- FIXED SIGNUP FUNCTION ---
  Future<void> _handleSignup() async {
    if (_passwordController.text != _confirmController.text) {
      _showMessage("Passwords do not match", isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await _authController.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      
      // Force navigation to Home upon success
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
      
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Signup failed", isError: true);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      _showMessage("An unexpected error occurred", isError: true);
      if (mounted) setState(() => _loading = false);
    } 
  }

  // --- FIXED GOOGLE SIGNUP FUNCTION ---
  Future<void> _handleGoogleSignup() async {
    setState(() => _loading = true);
    try {
      await _authController.signInWithGoogle();
      
      // Force navigation to Home upon success
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
      
    } catch (e) {
      _showMessage("Google Sign-In failed", isError: true);
      if (mounted) setState(() => _loading = false);
    } 
  }

  @override
  Widget build(BuildContext context) {
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

        // 2. PURPLE OVERLAY
        Positioned.fill(
          child: Container(
            color: Color(0xFF120E29).withOpacity(0.85), 
          ),
        ),

        // 3. THE FORM
        Scaffold(
          backgroundColor: Colors.transparent, 
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
            backgroundColor: Colors.transparent,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  // QUEEN LOGO
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1), 
                      shape: BoxShape.circle, 
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.5), 
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "♛", 
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
                  
                  SizedBox(height: 20),
                  
                  Text(
                    "JOIN THE ARENA",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                  ),
                  Text(
                    "Create your Grandmaster account",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  SizedBox(height: 30),

                  // INPUTS
                  _buildTextField("Email Address", _emailController, false),
                  SizedBox(height: 16),
                  _buildTextField("Password", _passwordController, true),
                  SizedBox(height: 16),
                  _buildTextField("Confirm Password", _confirmController, true),
                  
                  SizedBox(height: 30),

                  // BUTTONS
                  _loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, 
                                foregroundColor: primaryColor, 
                              ),
                              child: Text("CREATE ACCOUNT"),
                            ),
                            SizedBox(height: 16),
                            
                            ElevatedButton.icon(
                              onPressed: _handleGoogleSignup,
                              icon: Image.asset(
                                'assets/images/google_logo.jpg', 
                                height: 24,
                              ),
                              label: Text("Sign up with Google"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 2,
                              ),
                            ),
                            SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Already have an account?", style: TextStyle(color: Colors.white70)),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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