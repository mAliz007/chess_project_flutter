import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:chess/chess.dart' as chess_lib;

enum LocalGameStatus { playing, whiteWins, blackWins, draw }

class LocalMultiplayerController extends ChangeNotifier {
  // --- Dependencies ---
  final ChessBoardController boardController = ChessBoardController();
  final chess_lib.Chess gameLogic = chess_lib.Chess();

  // --- State ---
  // We expose FEN for the UI to render the board and captured pieces
  String get fen => boardController.getFen();
  
  // Helper to know whose turn it is for the UI
  bool get isWhiteTurn => gameLogic.turn == chess_lib.Color.WHITE;

  // --- Methods ---

  /// Syncs the board controller state with our internal logic 
  /// and checks for game over conditions.
  void onMove() {
    // 1. Sync Logic Board with Visual Board
    gameLogic.load(boardController.getFen());
    
    // 2. Notify UI (so Turn Indicator updates)
    notifyListeners();
  }

  /// Checks if the game has ended
  LocalGameStatus checkGameOver() {
    if (gameLogic.in_checkmate) {
      // If it's White's turn and they are mated, Black wins.
      return isWhiteTurn ? LocalGameStatus.blackWins : LocalGameStatus.whiteWins;
    }
    if (gameLogic.in_draw || gameLogic.in_stalemate || gameLogic.in_threefold_repetition) {
      return LocalGameStatus.draw;
    }
    return LocalGameStatus.playing;
  }

  void resetGame() {
    gameLogic.reset();
    boardController.resetBoard();
    notifyListeners();
  }

  @override
  void dispose() {
    // boardController.dispose(); 
    super.dispose();
  }
}