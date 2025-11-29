import 'package:flutter/material.dart';

/// A Heads-Up Display (HUD) pill that shows whose turn it is
class GameStatusHUD extends StatelessWidget {
  final bool isAiThinking;

  const GameStatusHUD({Key? key, required this.isAiThinking}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine colors based on state
    final color = isAiThinking ? Colors.redAccent : Colors.greenAccent;
    final text = isAiThinking ? "AI CALCULATING..." : "YOUR TURN";
    final icon = isAiThinking ? null : Icons.person;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), // Glassy background
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // If thinking, show spinner. If user turn, show Icon.
          if (isAiThinking)
            SizedBox(
              width: 15, 
              height: 15, 
              child: CircularProgressIndicator(strokeWidth: 2, color: color)
            )
          else
            Icon(icon, color: color, size: 18),
          
          SizedBox(width: 10),
          
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}