import 'package:flutter/material.dart';
import '../../controllers/local_multiplayer_controller.dart';

class LocalGameOverDialog {
 static void show({
  required BuildContext context,
  required String title,
  required String msg,
  required bool isWin,
  required LocalMultiplayerController gameController,
 }) {
  showDialog(
   context: context,
   barrierDismissible: false,
   builder: (ctx) => AlertDialog(
    backgroundColor: Color(0xFF1F222B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: isWin ? Colors.amber : Colors.grey, width: 2)),
    title: Column(
     children: [
      Icon(Icons.emoji_events, size: 50, color: isWin ? Colors.amber : Colors.grey),
      SizedBox(height: 10),
      Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
     ],
    ),
    content: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
    actions: [
     OutlinedButton(
      onPressed: () {
       Navigator.pop(ctx);
       Navigator.pop(context); // Go back to Home
      },
      child: Text("LEAVE", style: TextStyle(color: Colors.white54)),
     ),
     ElevatedButton(
      onPressed: () {
       Navigator.pop(ctx);
       gameController.resetGame();
      },
      child: Text("REMATCH"),
     ),
    ],
   ),
  );
 }
}