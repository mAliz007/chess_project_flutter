// lib/components/online_game/OnlineTimer.dart

import 'package:flutter/material.dart';

class OnlineTimer extends StatelessWidget {
  final Duration timeRemaining;
  final bool isMyTurn;
  final bool isOpponentTurn;
  
  // Total duration to calculate the progress bar
  static const Duration _maxDuration = Duration(minutes: 3);

  const OnlineTimer({
    Key? key,
    required this.timeRemaining,
    required this.isMyTurn,
    required this.isOpponentTurn, // Will show a static view for opponent's timer
  }) : super(key: key);

  String get _formattedTime {
    String minutes = (timeRemaining.inMinutes % 60).toString().padLeft(1, '0');
    String seconds = (timeRemaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Calculate the fraction of time remaining (0.0 to 1.0)
  double get _progressValue {
    if (timeRemaining.inSeconds <= 0) return 0.0;
    return timeRemaining.inSeconds / _maxDuration.inSeconds;
  }
  
  // Determine color based on remaining time
  Color get _timerColor {
    if (timeRemaining.inSeconds < 30) return Colors.redAccent;
    if (timeRemaining.inSeconds < 60) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    // If it's the opponent's turn, display a static '3:00' to show the maximum time they have.
    if (isOpponentTurn) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          "3:00", // Opponent's clock is handled server-side, we just show their max time
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }
    
    // If it's my turn, display the live countdown.
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _timerColor),
          ),
          child: Text(
            _formattedTime,
            style: TextStyle(
              color: _timerColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.5,
            ),
          ),
        ),
        
        SizedBox(height: 4),

        // Progress Bar
        SizedBox(
          width: 120, // Limit width of progress bar
          child: LinearProgressIndicator(
            value: _progressValue,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
          ),
        ),
      ],
    );
  }
}