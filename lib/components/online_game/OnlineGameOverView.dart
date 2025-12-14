// lib/components/online_game/OnlineGameOverView.dart

import 'package:flutter/material.dart';
import '../../controllers/online_game_controller.dart';

class OnlineGameOverView extends StatelessWidget {
  final OnlineGameController controller;
  final String userId;

  const OnlineGameOverView({
    Key? key,
    required this.controller,
    required this.userId,
  }) : super(key: key);

  String _getGameOverMessage() {
    switch (controller.gameStatus) {
      case 'forfeited':
        return controller.winnerId == userId
            ? "Your opponent has forfeited the match."
            : "You forfeited the match.";
      case 'timeout':
        return controller.winnerId == userId
            ? "Your opponent ran out of time!"
            : "You ran out of time.";
      // You can add more cases here (checkmate, draw, etc.)
      default:
        return "The match has ended.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWinner = controller.winnerId == userId;
    final titleText = isWinner ? "VICTORY!" : "DEFEAT!";
    final messageText = _getGameOverMessage();
    final color = isWinner ? Colors.greenAccent : Colors.redAccent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied, size: 80, color: color),
            SizedBox(height: 20),
            Text(
              titleText,
              style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              messageText,
              style: TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Return to Lobby Button
            ElevatedButton.icon(
              icon: Icon(Icons.home, color: Colors.black),
              label: Text("RETURN TO LOBBY", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () {
                // Clean up game state and return to lobby view
                controller.leaveGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}