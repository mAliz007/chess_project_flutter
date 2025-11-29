// Location: lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // HARSH / DEEP GAMING PALETTE
  static final Color _primaryColor = Color(0xFF6C63FF); // Electric Indigo (High Contrast)
  static final Color _backgroundColor = Color(0xFF120E29); // Deep Midnight (Almost Black)
  static final Color _surfaceColor = Color(0xFF1F1A36); // Slightly lighter Midnight for inputs
  static final Color _accentColor = Color(0xFF00E676); // Neon Green

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _backgroundColor,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _accentColor,
        surface: _surfaceColor,
        background: _backgroundColor,
      ),

      // AppBar Styling
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900, // Heavy/Harsh weight
          letterSpacing: 1.0,
        ),
      ),

      // Input Fields 
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceColor, // Darker input background
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: TextStyle(color: Colors.grey[600]),
        labelStyle: TextStyle(color: Colors.white70),
        // Sharper borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(16),
           borderSide: BorderSide(color: Colors.white12), // Subtle harsh edge
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryColor, width: 2), // Electric border
        ),
      ),

      // Button Styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: _primaryColor.withOpacity(0.6), // Stronger glow
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Less round, more "tech" looking
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800, // Bold text
            letterSpacing: 1.2,
          ),
        ),
      ),
      
      // Text Styling
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.w900, 
          fontSize: 32,
          letterSpacing: 1.5,
        ),
        bodyMedium: TextStyle(
          color: Colors.grey[400], 
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}