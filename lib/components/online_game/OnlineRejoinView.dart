// lib/components/online_game/OnlineRejoinView.dart

import 'package:flutter/material.dart';
import '../../controllers/online_game_controller.dart';

class OnlineRejoinView extends StatelessWidget {
  final OnlineGameController controller;

  const OnlineRejoinView({
    Key? key,
    required this.controller,
  }) : super(key: key);

  void _confirmForfeit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1F222B),
        title: Text("Forfeit Game?", style: TextStyle(color: Colors.white)),
        content: Text("This will abandon the unfinished match permanently.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.forfeitGame();
            },
            child: Text("Forfeit", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myColorText = controller.myColor == 'white' ? 'White' : 'Black';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orangeAccent),
            SizedBox(height: 20),
            Text(
              "Unfinished Game Detected!",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "You were playing as $myColorText in a previous match. What would you like to do?",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Rejoin Button
            ElevatedButton.icon(
              icon: Icon(Icons.refresh, color: Colors.black),
              label: Text("REJOIN MATCH", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () => controller.rejoinGame(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            SizedBox(height: 20),

            // Forfeit Button
            OutlinedButton.icon(
              icon: Icon(Icons.flag, color: Colors.redAccent),
              label: Text("FORFEIT & START NEW", style: TextStyle(fontSize: 16, color: Colors.redAccent)),
              onPressed: () => _confirmForfeit(context),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 60),
                side: BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}