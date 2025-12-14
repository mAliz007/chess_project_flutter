// lib/controllers/online_game_controller.dart - FULL FIXED WITH TIMER LOGIC

import 'dart:async'; // CRITICAL: For Timer

import 'package:flutter/material.dart';

import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;

import 'package:firebase_database/firebase_database.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:chess/chess.dart' as chess_lib;

enum OnlineStatus {
  lobby,
  searching,
  inGame,
  rejoinNeeded,
  gameOver
}

class OnlineGameController extends ChangeNotifier {
  final ChessBoardController boardController = ChessBoardController();
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://chessproject-740f9-default-rtdb.firebaseio.com/',
  );

  OnlineStatus status = OnlineStatus.lobby;
  String? gameId;
  String? myColor;
  String? myId;

  StreamSubscription? _gameSubscription;
  StreamSubscription? _matchSubscription;

  Map<String, dynamic>? activeGameDetails;

  String? gameStatus; // e.g., 'forfeited', 'checkmate', 'timeout'
  String? winnerId;   // Firebase UID of the winner

  String get fen => boardController.getFen();

  bool get isMyTurn {
    if (myColor == null || status != OnlineStatus.inGame) return false;
    final game = chess_lib.Chess.fromFEN(boardController.getFen());
    final currentTurnColor = game.turn == chess_lib.Color.WHITE ? 'white' : 'black';
    return myColor == currentTurnColor;
  }

  // --- TIMER FIELDS ---
  Timer? _turnTimer;
  final Duration _turnDuration = const Duration(minutes: 3);
  Duration _timeRemaining = const Duration(minutes: 3);

  // Public getter for timer display
  Duration get timeRemaining => _timeRemaining;

  // --- TIMER LOGIC ---

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _timeRemaining = _turnDuration;

    if (status != OnlineStatus.inGame || !isMyTurn) {
      // Don't start the timer if the game isn't active or it's not my turn
      notifyListeners();
      return;
    }

    // Timer only runs if it is *my* turn
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        notifyListeners();
      } else {
        // Time is up!
        _turnTimer?.cancel();
        _handleTurnTimeout();
      }
    });
    notifyListeners();
  }

  // Called when the timer reaches zero
  Future<void> _handleTurnTimeout() async {
    if (gameId == null || myId == null) return;
    
    // Determine the winner (the opponent)
    final opponentColorKey = myColor == 'white' ? 'black' : 'white';
    
    final opponentSnapshot = await _db.ref('games/$gameId/$opponentColorKey').get();
    final opponentId = opponentSnapshot.value as String?;

    if (opponentId != null) {
       // Update Firebase game state to 'timeout' and set the winner
       await _db.ref('games/$gameId').update({
          'status': 'timeout',
          'winner': opponentId,
       });
    }

    // Update local state to show game over screen
    _endGame('timeout', opponentId);
  }

  // --- Check for Active Games ---
  Future<bool> _checkActiveGames(String userId) async {
    final gamesRef = _db.ref('games');
    final snapshot = await gamesRef.orderByKey().startAt(userId).endAt(userId + '\uf8ff').get();

    String? foundGameId;
    Map? gameDataRaw;

    if (snapshot.exists && snapshot.value is Map) {
      final games = snapshot.value as Map;
      games.forEach((key, value) {
        if (value is! Map) return;

        final status = (value)['status'] as String? ?? 'inprogress';

        if (key.toString().contains(userId) && status == 'inprogress') {
           foundGameId = key.toString();
           gameDataRaw = value;
           return;
        }
      });
    }

    if (foundGameId != null && gameDataRaw != null) {
        final Map<String, dynamic> gameData = Map<String, dynamic>.from(gameDataRaw!);

        final whiteId = gameData['white'] as String;
        // blackId is not strictly needed here but useful for context
        // final blackId = gameData['black'] as String;

        myColor = (userId == whiteId) ? 'white' : 'black';

        status = OnlineStatus.rejoinNeeded;
        gameId = foundGameId;
        activeGameDetails = gameData;
        notifyListeners();
        return true;
    }
    return false;
  }

  // --- MATCHMAKING & GAME START ---

  Future<void> joinQueue(String userId) async {
    myId = userId;

    if (await _checkActiveGames(userId)) {
      return;
    }

    status = OnlineStatus.searching;
    notifyListeners();

    final waitingRoomRef = _db.ref('matchmaking/waiting_player');

    try {
      final snapshot = await waitingRoomRef.get();

      if (snapshot.exists) {
        final waitingData = Map.from(snapshot.value as Map);
        final opponentId = waitingData['userId'] as String;

        if (opponentId == userId) {
          _waitForChallenger(userId);
          return;
        }

        final newGameId = "${opponentId}_$userId";
        String startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

        await _db.ref('games/$newGameId').set({
          'white': opponentId,
          'black': userId,
          'fen': startFen,
          'turn': 'white',
          'status': 'inprogress',
        });

        await waitingRoomRef.remove();
        _startGame(newGameId, 'black');

      } else {
        await waitingRoomRef.set({
          'userId': userId,
          'timestamp': ServerValue.timestamp,
        });
        _waitForChallenger(userId);
      }
    } catch (e) {
      status = OnlineStatus.lobby;
      notifyListeners();
    }
  }

  void _waitForChallenger(String userId) {
    _matchSubscription = _db.ref('games').onChildAdded.listen((event) {
      if (event.snapshot.key!.contains(userId)) {
        _matchSubscription?.cancel();
        _db.ref('matchmaking/waiting_player').remove();
        _startGame(event.snapshot.key!, 'white');
      }
    });
  }

  void _startGame(String id, String color) {
    gameId = id;
    myColor = color;
    status = OnlineStatus.inGame;
    gameStatus = null;
    winnerId = null;

    if (activeGameDetails == null) {
      boardController.resetBoard();
    } else {
      // Rejoining a game
      boardController.loadFen(activeGameDetails!['fen']);
    }
    
    activeGameDetails = null; // Clear old details

    // Initial check for whose turn it is
    if (isMyTurn) {
      _startTurnTimer();
    } else {
      _turnTimer?.cancel(); // Ensure timer is off if it's not our turn
    }

    notifyListeners();

    _gameSubscription = _db.ref('games/$gameId').onValue.listen((event) {
      final dataRaw = event.snapshot.value;
      final data = dataRaw != null ? Map<String, dynamic>.from(dataRaw as Map) : null;
      if (data == null) return;

      final serverFen = data['fen'];

      final currentStatus = data['status'] as String? ?? 'inprogress';

      if (currentStatus != 'inprogress' && status == OnlineStatus.inGame) {
          // Game ended by opponent (forfeit, timeout from their side, etc.)
          // We rely on the 'winner' field set by the opponent's controller or Firebase rule
          _endGame(currentStatus, data['winner']);
          return;
      }

      // If still in game, update board
      if (serverFen != null && boardController.getFen() != serverFen) {
        boardController.loadFen(serverFen);

        // After loading a new FEN, re-evaluate whose turn it is
        final turnAfterMove = isMyTurn; // Recalculates based on the new FEN
        if (turnAfterMove) {
          _startTurnTimer(); // Start timer if it's now our turn
        } else {
          _turnTimer?.cancel(); // Stop timer if it's now the opponent's turn
        }
        notifyListeners();
      }
    });
  }

  void _endGame(String statusReason, String? winner) {
    _gameSubscription?.cancel(); // Stop listening to the game node
    _turnTimer?.cancel();        // Stop any running timer

    // If opponent forfeited, the winner is us (we should handle this in forfeitGame)
    // If the game ended due to checkmate, etc., the winner is sent from Firebase
    status = OnlineStatus.gameOver;
    gameStatus = statusReason;
    winnerId = winner;
    notifyListeners();
  }


  // --- CORE GAME ACTIONS ---

  void rejoinGame() {
    if (gameId != null && myColor != null && myId != null) {
      // The _startGame method handles loading FEN and starting the timer correctly
      _startGame(gameId!, myColor!);
    } else {
      leaveGame();
    }
  }

  Future<void> forfeitGame() async {
    if (gameId != null && myId != null) {
      final opponentIdKey = myColor == 'white' ? 'black' : 'white';

      final opponentSnapshot = await _db.ref('games/$gameId/$opponentIdKey').get();
      final opponentId = opponentSnapshot.value as String?;

      if (opponentId != null) {
         // Set the game status and the winner (the opponent)
         await _db.ref('games/$gameId').update({
            'status': 'forfeited',
            'winner': opponentId,
         });
      }
    }
    // Transition local player to game over screen immediately
    // Note: winnerId is null here, but the opponent will have the real one
    _endGame('forfeited', null);
  }

  Future<void> makeMove() async {
    if (gameId == null) return;

    _turnTimer?.cancel(); // CRITICAL: Stop the timer immediately after our move

    final newFen = boardController.getFen();
    final logicBoard = chess_lib.Chess.fromFEN(newFen);
    String nextTurn = logicBoard.turn == chess_lib.Color.WHITE ? 'white' : 'black';

    // Check for checkmate/stalemate here if necessary, but typically this is done
    // by the server or a dedicated cloud function for ranked games.
    
    await _db.ref('games/$gameId').update({
      'fen': newFen,
      'turn': nextTurn,
    });

    notifyListeners(); // Force UI update now before the stream receives it back
  }

  // --- CLEANUP ---

  void _cleanupInternal() {
    _gameSubscription?.cancel();
    _matchSubscription?.cancel();
    _turnTimer?.cancel(); // CRITICAL: Stop timer on cleanup

    // Clean up finished game node only after game over
    if (status == OnlineStatus.gameOver && gameId != null) {
      _db.ref('games/$gameId').remove().catchError((e) {
         print("Error cleaning up finished game node: $e");
      });
    }

    // Remove from waiting queue if searching
    if (status == OnlineStatus.searching && myId != null) {
      _db.ref('matchmaking/waiting_player').get().then((snapshot) {
        if (snapshot.exists) {
          final data = Map.from(snapshot.value as Map);
          if (data['userId'] == myId) {
            _db.ref('matchmaking/waiting_player').remove();
          }
        }
      });
    }

    // Reset state
    status = OnlineStatus.lobby;
    gameId = null;
    myColor = null;
    activeGameDetails = null;
    gameStatus = null;
    winnerId = null;
  }

  void leaveGame() {
    _cleanupInternal();
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanupInternal();
    super.dispose();
  }
}