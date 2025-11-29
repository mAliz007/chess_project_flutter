// Location: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

// Styling and Components
import 'core/theme/app_theme.dart';
import 'widgets/auth/auth_wrapper.dart';

// Screens
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/single_player_page.dart';
import 'screens/local_multiplayer_page.dart';
import 'screens/online_multiplayer_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Master',
      // Apply the custom chess theme
      theme: AppTheme.lightTheme, 
      debugShowCheckedModeBanner: false,
      
      // Determine the starting screen based on Auth status
      home: AuthWrapper(),
      
      // Named Routes
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/home': (context) => HomePage(),
        '/single': (context) => SinglePlayerPage(),
        '/local': (context) => LocalMultiplayerPage(),
        '/online': (context) => OnlineMultiplayerPage(),
      },
    );
  }
}