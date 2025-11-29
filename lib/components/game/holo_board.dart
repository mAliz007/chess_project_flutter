import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

/// A styled container that gives the ChessBoard a holographic/glowing look
class HoloBoard extends StatelessWidget {
  final ChessBoardController controller;
  final VoidCallback onMove;
  final double size;

  const HoloBoard({
    Key? key, 
    required this.controller, 
    required this.onMove,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black54, // Dark backing
        borderRadius: BorderRadius.circular(8),
        // Glowing Border
        border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ChessBoard(
          controller: controller,
          boardColor: BoardColor.green, // Cyber/Matrix theme
          boardOrientation: PlayerColor.white,
          onMove: onMove,
        ),
      ),
    );
  }
}