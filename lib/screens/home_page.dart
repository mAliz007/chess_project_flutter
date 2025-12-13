// Import Flutter material widgets library
import 'package:flutter/material.dart';
// Import Firebase authentication package
import 'package:firebase_auth/firebase_auth.dart';
// Import SinglePlayerPage to navigate and pass arguments
import 'single_player_page.dart'; 

// HomePage widget is stateless
class HomePage extends StatelessWidget {
  // Get the currently signed-in Firebase user
  final User? user = FirebaseAuth.instance.currentUser;

  // Getter to determine the display name for the user
  String get _displayName {
    // If the user has a displayName set, use it
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!;
    }
    // Otherwise, derive name from email
    if (user?.email != null) {
      String name = user!.email!.split('@')[0];
      return name[0].toUpperCase() + name.substring(1);
    }
    // Default fallback name
    return "Commander";
  }

  // Function to sign out the user and navigate to login screen
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // --- NEW: DIFFICULTY SELECTION DIALOG ---
  // Function to show a dialog for selecting game difficulty
  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1F222B), // Dialog background color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded corners
        title: Center(
            child: Text("SELECT DIFFICULTY", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5))
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyBtn(context, "NOVICE", Colors.greenAccent, 2),
            SizedBox(height: 10),
            _buildDifficultyBtn(context, "CASUAL", Colors.blueAccent, 6),
            SizedBox(height: 10),
            _buildDifficultyBtn(context, "MASTER", Colors.orangeAccent, 10),
            SizedBox(height: 10),
            _buildDifficultyBtn(context, "GRANDMASTER", Colors.redAccent, 15),
          ],
        ),
      ),
    );
  }

  // Helper function to create a difficulty selection button
  Widget _buildDifficultyBtn(BuildContext context, String label, Color color, int depth) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context); // Close the difficulty dialog
          // Navigate to SinglePlayerPage and pass selected difficulty
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => SinglePlayerPage(difficultyDepth: depth, difficultyLabel: label)
            )
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)), // Border color with opacity
          padding: EdgeInsets.symmetric(vertical: 16), // Button padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)), // Button text
      ),
    );
  }
  // -----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image for the home page
        Positioned.fill(child: Image.asset('assets/images/chess_bg.jpg', fit: BoxFit.cover)),
        // Semi-transparent overlay to darken the background
        Positioned.fill(child: Container(color: Color(0xFF120E29).withOpacity(0.90))),
        
        // Main Scaffold for UI elements
        Scaffold(
          backgroundColor: Colors.transparent, // Transparent to show background
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0, // No shadow
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("WELCOME BACK,", style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white70)),
                Text(_displayName.toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            actions: [
              // Logout button in AppBar
              Container(
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: Icon(Icons.logout, color: Colors.redAccent),
                  onPressed: () => _signOut(context), // Call sign out function
                  tooltip: 'Logout',
                ),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title text
                Text(
                  "CHOOSE YOUR\nBATTLEFIELD",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5, height: 1.1),
                ),
                SizedBox(height: 40),

                // SINGLE PLAYER game mode card
                _buildGameModeCard(
                  context,
                  title: "SINGLE PLAYER",
                  subtitle: "Practice against AI",
                  icon: Icons.psychology,
                  color: Color(0xFF6C63FF),
                  onTap: () => _showDifficultyDialog(context), // Open difficulty selection dialog
                ),
                SizedBox(height: 20),

                // LOCAL MULTIPLAYER game mode card
                _buildGameModeCard(
                  context,
                  title: "LOCAL MULTIPLAYER",
                  subtitle: "Play on same device",
                  icon: Icons.supervised_user_circle,
                  color: Color(0xFF00E676),
                  onTap: () => Navigator.pushNamed(context, '/local'), // Navigate to local multiplayer page
                ),
                SizedBox(height: 20),

                // ONLINE MATCH game mode card
                _buildGameModeCard(
                  context,
                  title: "ONLINE MATCH",
                  subtitle: "Play against real Players",
                  icon: Icons.public,
                  color: Color(0xFFFF4081),
                  onTap: () => Navigator.pushNamed(context, '/online'), // Navigate to online match page
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper function to build a card for each game mode
  Widget _buildGameModeCard(BuildContext context,
      {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // Handle tap
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              // Icon for the game mode
              Container(
                height: 60, width: 60,
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.5))),
                child: Icon(icon, color: color, size: 30),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                    SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                ),
              ),
              // Arrow icon at the end
              Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
