// lib/controllers/online_game_controller.dart

import 'dart:async';
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
  
  String? gameStatus; // e.g., 'forfeited', 'checkmate'
  String? winnerId;   // Firebase UID of the winner

  String get fen => boardController.getFen();
  
  bool get isMyTurn {
    if (myColor == null || status != OnlineStatus.inGame) return false;
    final game = chess_lib.Chess.fromFEN(boardController.getFen());
    final currentTurnColor = game.turn == chess_lib.Color.WHITE ? 'white' : 'black';
    return myColor == currentTurnColor;
  }

  // --- Check for Active Games (Only returns true for 'inprogress' games) ---
  Future<bool> _checkActiveGames(String userId) async {
    final gamesRef = _db.ref('games');
    // Query for games containing the userId in the key
    final snapshot = await gamesRef.orderByKey().startAt(userId).endAt(userId + '\uf8ff').get();

    String? foundGameId;
    Map? gameDataRaw; 

    if (snapshot.exists && snapshot.value is Map) {
      final games = snapshot.value as Map;
      games.forEach((key, value) {
        // Ensure map is handled safely, assuming value is Map
        if (value is! Map) return;
        
        final status = (value)['status'] as String? ?? 'inprogress';
        
        // ONLY CONSIDER A GAME ACTIVE IF STATUS IS 'inprogress'
        if (key.toString().contains(userId) && status == 'inprogress') {
           foundGameId = key.toString();
           gameDataRaw = value;
           return;
        }
      });
    }

    if (foundGameId != null && gameDataRaw != null) {
        // Type safe casting for use in activeGameDetails
        final Map<String, dynamic> gameData = Map<String, dynamic>.from(gameDataRaw!);

        final whiteId = gameData['white'] as String;
        final blackId = gameData['black'] as String;
        
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
        final waitingData = snapshot.value as Map;
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
    }
    activeGameDetails = null; 
    
    notifyListeners();

    _gameSubscription = _db.ref('games/$gameId').onValue.listen((event) {
      final dataRaw = event.snapshot.value;
      final data = dataRaw != null ? Map<String, dynamic>.from(dataRaw as Map) : null;
      if (data == null) return;
      
      final serverFen = data['fen'];
      
      final currentStatus = data['status'] as String? ?? 'inprogress';

      if (currentStatus != 'inprogress' && status == OnlineStatus.inGame) {
          // Opponent has terminated the game (e.g., forfeited)
          _endGame(currentStatus, data['winner']);
          return; 
      }
      
      // If still in game, update board if necessary
      if (serverFen != null && boardController.getFen() != serverFen) {
        boardController.loadFen(serverFen);
        notifyListeners();
      }
    });
  }
  
  void _endGame(String statusReason, String? winner) {
    _gameSubscription?.cancel(); // Stop listening to the game node
    status = OnlineStatus.gameOver;
    gameStatus = statusReason;
    winnerId = winner;
    notifyListeners();
  }


  // --- CORE GAME ACTIONS ---

  void rejoinGame() {
    if (gameId != null && myColor != null) {
      if (activeGameDetails != null) {
         boardController.loadFen(activeGameDetails!['fen']);
      }
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
    _endGame('forfeited', null); 
  }

  Future<void> makeMove() async {
    if (gameId == null) return;
    
    final newFen = boardController.getFen();
    final logicBoard = chess_lib.Chess.fromFEN(newFen);
    String nextTurn = logicBoard.turn == chess_lib.Color.WHITE ? 'white' : 'black';

    await _db.ref('games/$gameId').update({
      'fen': newFen,
      'turn': nextTurn,
    });
    
    notifyListeners();
  }

  // --- CLEANUP (The crucial fix for starting new games) ---

  void _cleanupInternal() {
    _gameSubscription?.cancel();
    _matchSubscription?.cancel();
    
    // NEW FIX: If we are leaving a finished game, DELETE the Firebase node 
    // to prevent _checkActiveGames from finding it later.
    if (status == OnlineStatus.gameOver && gameId != null) {
      // Don't await this, just trigger the background cleanup
      _db.ref('games/$gameId').remove().catchError((e) {
         print("Error cleaning up finished game node: $e");
      });
    }

    // Only remove from waiting queue if we are currently searching
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
    
    // Reset all game state variables back to initial lobby condition
    status = OnlineStatus.lobby;
    gameId = null;
    myColor = null;
    activeGameDetails = null;
    gameStatus = null; 
    winnerId = null;   
  }

  // Public method called by UI to return to lobby from any state (including game over)
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