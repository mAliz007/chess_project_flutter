// File: lib/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    print("DEBUG: $msg");
  }

  // Email/Password login
  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _showMessage("Login successful: ${userCredential.user?.email}");
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showMessage("Login failed: ${e.message}");
    } catch (e) {
      _showMessage("Login failed: $e");
    }
    setState(() => _loading = false);
  }

  // Google Sign-In
  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _showMessage("Google Sign-In canceled");
        setState(() => _loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      _showMessage(
        "Google Sign-In successful: ${userCredential.user?.displayName}",
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showMessage("Google Sign-In failed: ${e.message}");
    } catch (e) {
      _showMessage("Google Sign-In failed: $e");
    }
    setState(() => _loading = false);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Please enter your email first");
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showMessage("Password reset email sent to $email");
    } on FirebaseAuthException catch (e) {
      _showMessage("Failed to send reset email: ${e.message}");
    } catch (e) {
      _showMessage("Failed to send reset email: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              _loading
                  ? CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(onPressed: _login, child: Text('Login')),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _googleSignIn,
                          child: Text('Login with Google'),
                        ),
                        SizedBox(height: 10),
                        TextButton(
                          onPressed: _forgotPassword,
                          child: Text('Forgot Password?'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/signup');
                          },
                          child: Text('Go to Signup'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
