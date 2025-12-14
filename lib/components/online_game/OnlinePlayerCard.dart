// lib/components/online_game/OnlinePlayerCard.dart

import 'package:flutter/material.dart';

class OnlinePlayerCard extends StatelessWidget {
  final String name;
  final String rank;
  final Color color;
  final bool isLeftAligned;
  final Widget capturedPiecesHud;

  const OnlinePlayerCard({
    Key? key,
    required this.name,
    required this.rank,
    required this.color,
    required this.isLeftAligned,
    required this.capturedPiecesHud,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isLeftAligned) ...[
                CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 16, child: Icon(Icons.person, color: color, size: 18)),
                SizedBox(width: 10)
              ],
              Column(
                crossAxisAlignment: isLeftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(rank, style: TextStyle(color: color, fontSize: 10)),
                ],
              ),
              if (!isLeftAligned) ...[
                SizedBox(width: 10),
                CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 16, child: Icon(Icons.public, color: color, size: 18))
              ],
            ],
          ),
          SizedBox(height: 8),
          Align(
            alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
            child: capturedPiecesHud, // Captured pieces HUD (the child widget)
          ),
        ],
      ),
    );
  }
}