import 'package:flutter/material.dart';

class CapturedPiecesHUD extends StatelessWidget {
  final String fen;
  final String capturedBy; // 'player' (shows black pieces) or 'ai' (shows white pieces)

  const CapturedPiecesHUD({
    Key? key, 
    required this.fen, 
    required this.capturedBy
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final captured = _calculateCapturedPieces(fen);
    
    // If capturedBy Player -> Show Black Pieces (b) that you killed
    // If capturedBy AI -> Show White Pieces (w) that it killed
    final piecesToShow = capturedBy == 'player' 
        ? (captured['b'] ?? []) 
        : (captured['w'] ?? []);

    // If empty, show invisible container to keep layout stable
    if (piecesToShow.isEmpty) return SizedBox(height: 30, width: 10);

    return Container(
      height: 35,
      // Stack the pieces horizontally with overlap
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: piecesToShow.length,
        itemBuilder: (context, index) {
          return Align(
            widthFactor: 0.6, // This makes them overlap (Stack effect)
            child: _buildPieceChip(piecesToShow[index], capturedBy),
          );
        },
      ),
    );
  }

  Widget _buildPieceChip(String letter, String capturedBy) {
    String icon = _getPieceIcon(letter);
    bool isWhitePiece = capturedBy == 'ai'; 

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isWhitePiece ? Colors.white : Colors.black,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white24, 
          width: 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(1, 1),
          )
        ],
      ),
      child: Center(
        child: Text(
          icon,
          style: TextStyle(
            color: isWhitePiece ? Colors.black : Colors.white,
            fontSize: 16,
            height: 1.1, // Fix vertical alignment of unicode
          ),
        ),
      ),
    );
  }

  String _getPieceIcon(String letter) {
    switch (letter.toLowerCase()) {
      case 'p': return '♟';
      case 'n': return '♞';
      case 'b': return '♝';
      case 'r': return '♜';
      case 'q': return '♛';
      default: return '';
    }
  }

  Map<String, List<String>> _calculateCapturedPieces(String fen) {
    // Standard piece counts
    final fullSet = {'p': 8, 'n': 2, 'b': 2, 'r': 2, 'q': 1};
    Map<String, int> whiteOnBoard = {'p': 0, 'n': 0, 'b': 0, 'r': 0, 'q': 0};
    Map<String, int> blackOnBoard = {'p': 0, 'n': 0, 'b': 0, 'r': 0, 'q': 0};

    String boardPart = fen.split(' ')[0];
    
    // Count what is currently on the board
    for (int i = 0; i < boardPart.length; i++) {
      String char = boardPart[i];
      if (whiteOnBoard.containsKey(char.toLowerCase())) {
        if (char == char.toUpperCase()) {
          whiteOnBoard[char.toLowerCase()] = (whiteOnBoard[char.toLowerCase()] ?? 0) + 1;
        } else {
          blackOnBoard[char] = (blackOnBoard[char] ?? 0) + 1;
        }
      }
    }

    List<String> whiteCaptured = [];
    List<String> blackCaptured = [];

    // Calculate diff
    fullSet.forEach((key, maxCount) {
      int wMissing = maxCount - (whiteOnBoard[key] ?? 0);
      // Sort so Queen/Rook appear first in the graveyard
      for (int i=0; i<wMissing; i++) whiteCaptured.insert(0, key); 

      int bMissing = maxCount - (blackOnBoard[key] ?? 0);
      for (int i=0; i<bMissing; i++) blackCaptured.insert(0, key);
    });

    return {'w': whiteCaptured, 'b': blackCaptured};
  }
}