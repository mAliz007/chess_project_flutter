import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:http/http.dart' as http;

class SinglePlayerPage extends StatefulWidget {
  @override
  _SinglePlayerPageState createState() => _SinglePlayerPageState();
}

class _SinglePlayerPageState extends State<SinglePlayerPage> {
  final ChessBoardController _controller = ChessBoardController();
  
  // Flag to show a loader while AI thinks
  bool _isAiThinking = false;

  // ----------------------------------------------------------
  // CORE AI LOGIC (HTTP instead of Native)
  // ----------------------------------------------------------
  Future<void> _makeAiMove() async {
    setState(() {
      _isAiThinking = true;
    });

    try {
      final fen = _controller.getFen();
      // Using a free Stockfish API
      final url = Uri.parse('https://stockfish.online/api/s/v2.php?fen=$fen&depth=5');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Format: "bestmove e2e4 ponder..."
          final bestMoveString = data['bestmove']; 
          final moveParts = bestMoveString.split(' ');
          final moveCode = moveParts[1]; // e.g., "e2e4"

          _applyMove(moveCode);
        }
      }
    } catch (e) {
      print("AI Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI Network Error. Check internet.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAiThinking = false;
        });
      }
    }
  }

  void _applyMove(String move) {
    // Parse move (e.g., "e2e4")
    final source = move.substring(0, 2);
    final target = move.substring(2, 4);
    String? promotion;
    if (move.length > 4) {
      promotion = move.substring(4, 5);
    }

    // Logic Board Update
    final logicBoard = chess_lib.Chess.fromFEN(_controller.getFen());
    logicBoard.move({
      'from': source,
      'to': target,
      'promotion': promotion ?? 'q',
    });

    // UI Update
    _controller.loadFen(logicBoard.fen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("VS AI (Online)")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Indicator
            if (_isAiThinking)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(width: 10),
                    Text("AI is thinking..."),
                  ],
                ),
              ),
              
            ChessBoard(
              controller: _controller,
              boardColor: BoardColor.brown,
              boardOrientation: PlayerColor.white,
              onMove: () {
                // When user moves, trigger AI
                _makeAiMove();
              },
            ),
            
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                _controller.resetBoard();
              },
              child: Text("Reset Game"),
            ),
          ],
        ),
      ),
    );
  }
}