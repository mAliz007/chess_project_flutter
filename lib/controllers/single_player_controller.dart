import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:chess/chess.dart' as chess_lib;
import '../services/stockfish_service.dart';

enum GameStatus { playing, checkmate, draw }

class SinglePlayerController extends ChangeNotifier {
  // --- Dependencies ---
  final ChessBoardController boardController = ChessBoardController();
  final StockfishService _aiService = StockfishService();

  // --- State ---
  bool isAiThinking = false;
  
  // We expose the board state (FEN) for the UI to read (for captured pieces, etc.)
  String get fen => boardController.getFen();

  // --- Methods ---

  /// Handles the full AI turn flow
  /// Returns [true] if the move was successful, [false] if network error
  Future<bool> makeAiMove(int depth) async {
    isAiThinking = true;
    notifyListeners(); // Update UI to show "Thinking..."

    try {
      final currentFen = boardController.getFen();
      final bestMove = await _aiService.getBestMove(currentFen, depth: depth);

      if (bestMove != null) {
        _applyMove(bestMove);
        isAiThinking = false;
        notifyListeners();
        return true;
      } else {
        isAiThinking = false;
        notifyListeners();
        return false; // Network error or API failure
      }
    } catch (e) {
      isAiThinking = false;
      notifyListeners();
      return false;
    }
  }

  /// Applies a move string (e.g. "e2e4") to the board logic
  void _applyMove(String move) {
    final source = move.substring(0, 2);
    final target = move.substring(2, 4);
    String? promotion = move.length > 4 ? move.substring(4, 5) : null;

    // We use the chess_lib to validate and apply the move logically
    final logicBoard = chess_lib.Chess.fromFEN(boardController.getFen());
    logicBoard.move({
      'from': source,
      'to': target,
      'promotion': promotion ?? 'q',
    });

    // Update the visual board
    boardController.loadFen(logicBoard.fen);
  }

  /// Checks if the game has ended (Checkmate, Stalemate, Draw)
  GameStatus checkGameOver() {
    final logicBoard = chess_lib.Chess.fromFEN(boardController.getFen());
    
    if (logicBoard.in_checkmate) {
      return GameStatus.checkmate;
    } 
    if (logicBoard.in_draw || logicBoard.in_stalemate || logicBoard.in_threefold_repetition) {
      return GameStatus.draw;
    }
    
    return GameStatus.playing;
  }

  /// Returns true if it was the Player's turn when the game ended
  /// (Meaning the Player lost, because it's their turn and they are in checkmate)
  bool didPlayerLose() {
    final logicBoard = chess_lib.Chess.fromFEN(boardController.getFen());
    // Assuming Player is always WHITE (First move)
    // If it is White's turn and game is over -> White Lost.
    return logicBoard.turn == chess_lib.Color.WHITE;
  }

  void resetGame() {
    boardController.resetBoard();
    isAiThinking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // boardController.dispose(); // Optional: depending on if you want to keep state
    super.dispose();
  }
}