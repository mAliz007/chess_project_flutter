// File: lib/screens/signup_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _loading = false;

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    print("DEBUG: $msg");
  }

  // Email/Password signup
  Future<void> _signup() async {
    if (_passwordController.text != _confirmController.text) {
      _showMessage("Passwords do not match");
      return;
    }
    setState(() => _loading = true);
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      _showMessage("Signup successful: ${userCredential.user?.email}");
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showMessage("Signup failed: ${e.message}");
    } catch (e) {
      _showMessage("Signup failed: $e");
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
        "Google Sign-Up successful: ${userCredential.user?.displayName}",
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showMessage("Google Sign-Up failed: ${e.message}");
    } catch (e) {
      _showMessage("Google Sign-Up failed: $e");
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signup Page')),
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
              SizedBox(height: 10),
              TextField(
                controller: _confirmController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              _loading
                  ? CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _signup,
                          child: Text('Signup'),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _googleSignIn,
                          child: Text('Signup with Google'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/');
                          },
                          child: Text('Go to Login'),
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
