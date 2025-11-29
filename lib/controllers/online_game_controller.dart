import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chess/chess.dart' as chess_lib;

enum OnlineStatus { lobby, searching, inGame }

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

  String get fen => boardController.getFen();
  
  bool get isMyTurn {
    if (myColor == null) return false;
    final game = chess_lib.Chess.fromFEN(boardController.getFen());
    final currentTurnColor = game.turn == chess_lib.Color.WHITE ? 'white' : 'black';
    return myColor == currentTurnColor;
  }

  // --- MATCHMAKING ---

  Future<void> joinQueue(String userId) async {
    status = OnlineStatus.searching;
    myId = userId;
    notifyListeners();

    final waitingRoomRef = _db.ref('matchmaking/waiting_player');

    try {
      final snapshot = await waitingRoomRef.get();

      if (snapshot.exists) {
        final waitingData = snapshot.value as Map;
        final opponentId = waitingData['userId'];

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
    boardController.resetBoard(); 
    notifyListeners();

    _gameSubscription = _db.ref('games/$gameId').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;
      final serverFen = data['fen'];
      
      if (serverFen != null && boardController.getFen() != serverFen) {
        boardController.loadFen(serverFen);
        notifyListeners();
      }
    });
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

  // --- CLEANUP ---

  // 1. Internal Cleanup (Stops streams, DOES NOT notify UI)
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

  // 2. Public Leave Game (Cleans up AND notifies UI)
  void leaveGame() {
    _cleanupInternal();
    notifyListeners(); // Safe to call if UI is still active
  }

  @override
  void dispose() {
    _cleanupInternal(); // Just clean up, DO NOT notify
    super.dispose();
  }
}