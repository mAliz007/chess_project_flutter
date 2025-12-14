// lib/components/online_game/OnlineLobbyView.dart

import 'package:flutter/material.dart';
import '../../controllers/online_game_controller.dart';

class OnlineLobbyView extends StatelessWidget {
  final OnlineGameController controller;
  final String userId;

  const OnlineLobbyView({
    Key? key,
    required this.controller,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSearching = controller.status == OnlineStatus.searching;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulse circle or spinning icon
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 20)],
            ),
            child: isSearching
                ? Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ) // Searching indicator
                : Icon(Icons.public, size: 60, color: Colors.blueAccent), // Idle lobby icon
          ),

          SizedBox(height: 40),

          if (isSearching) ...[
            Text("Scanning for opponent...", style: TextStyle(color: Colors.white70, fontSize: 18)),
            SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => controller.leaveGame(),
              child: Text("CANCEL", style: TextStyle(color: Colors.redAccent)),
            )
          ] else ...[
            // Find match button
            GestureDetector(
              onTap: () => controller.joinQueue(userId),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4834D4)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Text(
                  "FIND MATCH",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}