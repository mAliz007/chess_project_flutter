// Location: lib/main.dart

// Imports for the core Flutter framework and Material Design components
import 'package:flutter/material.dart';
// Imports for Firebase services
import 'package:firebase_core/firebase_core.dart';
// Auto-generated file containing configuration specific to your Firebase project
import 'firebase_options.dart'; 

// Styling and Components (files defining the look and key structural widgets)
import 'core/theme/app_theme.dart';
import 'widgets/auth/auth_wrapper.dart'; // Handles the initial login check

// All the different screen views the user can navigate to
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/single_player_page.dart';
import 'screens/local_multiplayer_page.dart';
import 'screens/online_multiplayer_page.dart';

// --- APPLICATION ENTRY POINT ---
void main() async {
    // 1. Ensures the Flutter framework is initialized before anything else.
    WidgetsFlutterBinding.ensureInitialized();
    
    // 2. Initializes the connection to your Firebase project.
    // This makes sure authentication, database, etc., are available.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // 3. Runs the root widget of the application.
    runApp(MyApp());
}

// --- ROOT WIDGET OF THE APP ---
class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            // Display name for the operating system and user's phone
            title: 'Chess Master', 
            
            // Apply the custom visual style across the whole application
            theme: AppTheme.lightTheme, 
            
            // Hides the "DEBUG" banner in the top-right corner
            debugShowCheckedModeBanner: false,
            
            // The first screen to display when the app starts.
            // AuthWrapper checks if the user is logged in and navigates accordingly.
            home: AuthWrapper(),
            
            // Named Routes: A map of string names to their corresponding screen widgets.
            // This allows for easy navigation throughout the app.
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