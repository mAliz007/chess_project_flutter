// Dart async utilities
import 'dart:async';
// Flutter widgets
import 'package:flutter/material.dart';
// Flutter Chess Board library, hide Color to avoid conflict with chess_lib
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
// Firebase Realtime Database
import 'package:firebase_database/firebase_database.dart';
// Firebase Core for initialization
import 'package:firebase_core/firebase_core.dart';
// Chess logic library
import 'package:chess/chess.dart' as chess_lib;

// Enum for tracking online game status
enum OnlineStatus { lobby, searching, inGame }

// Controller for managing online chess game logic and state
class OnlineGameController extends ChangeNotifier {
  final ChessBoardController boardController = ChessBoardController(); // Controls the chess board UI
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://chessproject-740f9-default-rtdb.firebaseio.com/',
  ); // Firebase Realtime Database reference

  OnlineStatus status = OnlineStatus.lobby; // Current online status
  String? gameId;    // Current game ID
  String? myColor;   // Player color ('white' or 'black')
  String? myId;      // Player unique ID

  StreamSubscription? _gameSubscription;   // Listener for game updates
  StreamSubscription? _matchSubscription;  // Listener for matchmaking

  // Get current FEN from board
  String get fen => boardController.getFen();

  // Determines if it's the player's turn
  bool get isMyTurn {
    if (myColor == null) return false; // Unknown color => can't move
    final game = chess_lib.Chess.fromFEN(boardController.getFen());
    final currentTurnColor = game.turn == chess_lib.Color.WHITE ? 'white' : 'black';
    return myColor == currentTurnColor;
  }

  // --- MATCHMAKING ---

  // Join the matchmaking queue
  Future<void> joinQueue(String userId) async {
    status = OnlineStatus.searching; // Set status to searching
    myId = userId;                    // Store player ID
    notifyListeners();                // Update UI

    final waitingRoomRef = _db.ref('matchmaking/waiting_player');

    try {
      final snapshot = await waitingRoomRef.get(); // Check if someone is waiting

      if (snapshot.exists) {
        final waitingData = snapshot.value as Map;
        final opponentId = waitingData['userId'];

        if (opponentId == userId) {
          // If same user is already waiting, wait for challenger
          _waitForChallenger(userId);
          return;
        }

        // Start a new game with waiting player
        final newGameId = "${opponentId}_$userId";
        String startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

        // Initialize game data in database
        await _db.ref('games/$newGameId').set({
          'white': opponentId,
          'black': userId,
          'fen': startFen,
          'turn': 'white',
        });

        await waitingRoomRef.remove(); // Remove waiting player
        _startGame(newGameId, 'black'); // Start game as black
      } else {
        // No one waiting, become waiting player
        await waitingRoomRef.set({
          'userId': userId,
          'timestamp': ServerValue.timestamp,
        });
        _waitForChallenger(userId); // Wait for opponent
      }
    } catch (e) {
      status = OnlineStatus.lobby; // On error, reset to lobby
      notifyListeners();
    }
  }

  // Wait for an opponent to start a game
  void _waitForChallenger(String userId) {
    _matchSubscription = _db.ref('games').onChildAdded.listen((event) {
      if (event.snapshot.key!.contains(userId)) {
        _matchSubscription?.cancel();           // Stop listening
        _db.ref('matchmaking/waiting_player').remove(); // Remove from waiting room
        _startGame(event.snapshot.key!, 'white');       // Start game as white
      }
    });
  }

  // Initialize game session
  void _startGame(String id, String color) {
    gameId = id;
    myColor = color;
    status = OnlineStatus.inGame;
    boardController.resetBoard(); // Reset board UI
    notifyListeners();

    // Listen for real-time game updates
    _gameSubscription = _db.ref('games/$gameId').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;
      final serverFen = data['fen'];

      // Update board if server FEN differs
      if (serverFen != null && boardController.getFen() != serverFen) {
        boardController.loadFen(serverFen);
        notifyListeners();
      }
    });
  }

  // Make a move and update Firebase
  Future<void> makeMove() async {
    if (gameId == null) return;

    final newFen = boardController.getFen(); // Get board state
    final logicBoard = chess_lib.Chess.fromFEN(newFen);
    String nextTurn = logicBoard.turn == chess_lib.Color.WHITE ? 'white' : 'black';

    // Update game data in database
    await _db.ref('games/$gameId').update({
      'fen': newFen,
      'turn': nextTurn,
    });

    notifyListeners(); // Refresh UI
  }

  // --- CLEANUP ---

  // Internal cleanup (stop streams, remove waiting player, reset status)
  void _cleanupInternal() {
    _gameSubscription?.cancel();
    _matchSubscription?.cancel();

    if (status == OnlineStatus.searching && myId != null) {
      _db.ref('matchmaking/waiting_player').get().then((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.value as Map;
          if (data['userId'] == myId) {
            _db.ref('matchmaking/waiting_player').remove();
          }
        }
      });
    }

    status = OnlineStatus.lobby;
    gameId = null;
    myColor = null;
  }

  // Public method to leave game (cleans up & notifies UI)
  void leaveGame() {
    _cleanupInternal();
    notifyListeners(); // Safe to call while UI is active
  }

  @override
  void dispose() {
    _cleanupInternal(); // Stop streams without notifying
    super.dispose();
  }
}
