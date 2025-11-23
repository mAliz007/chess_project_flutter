// File: lib/screens/local_multiplayer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess;

class LocalMultiplayerPage extends StatefulWidget {
  @override
  State<LocalMultiplayerPage> createState() => _LocalMultiplayerPageState();
}

class _LocalMultiplayerPageState extends State<LocalMultiplayerPage> {
  ChessBoardController controller = ChessBoardController();
  chess.Chess game = chess.Chess();
  bool isWhiteTurn = true;

  String turnText() => isWhiteTurn ? "White's Turn" : "Black's Turn";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Local Multiplayer')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            turnText(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ChessBoard(
            controller: controller,
            boardColor: BoardColor.brown,
            boardOrientation: PlayerColor.white,
            enableUserMoves: true,
            onMove: () {
              // Sync game state with board FEN
              game.load(controller.getFen());

              setState(() {
                isWhiteTurn = !isWhiteTurn;
              });

              // Check game over
              if (game.in_checkmate) {
                _showDialog(
                  "${isWhiteTurn ? "Black" : "White"} wins by checkmate!",
                );
              } else if (game.in_draw) {
                _showDialog("Draw!");
              }
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              game.reset();
              controller.resetBoard();
              setState(() => isWhiteTurn = true);
            },
            child: Text('Restart Game'),
          ),
        ],
      ),
    );
  }

  void _showDialog(String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Game Over'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              game.reset();
              controller.resetBoard();
              setState(() => isWhiteTurn = true);
            },
            child: Text('Restart'),
          ),
        ],
      ),
    );
  }
}
