// File: lib/screens/home_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    String welcomeText = "Welcome";
    if (user != null) {
      // Prefer displayName, fallback to email
      welcomeText = "Welcome, ${user!.displayName ?? user!.email}";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              welcomeText,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/single'),
              child: Text('Single Player'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/local'),
              child: Text('Local Multiplayer'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/online'),
              child: Text('Online Multiplayer'),
            ),
          ],
        ),
      ),
    );
  }
}
