import 'package:flutter/material.dart';

class LocalTurnHUD extends StatelessWidget {
  final bool isWhiteTurn;

  const LocalTurnHUD({Key? key, required this.isWhiteTurn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // White Turn = Green / Black Turn = Pink (or any contrasting color)
    final color = isWhiteTurn ? Colors.greenAccent : Colors.pinkAccent;
    final text = isWhiteTurn ? "WHITE'S TURN" : "BLACK'S TURN";
    final icon = isWhiteTurn ? Icons.circle_outlined : Icons.circle;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 1),
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
          Icon(icon, color: color, size: 14),
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