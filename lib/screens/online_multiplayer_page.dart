import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart'; 

class GameController {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://chessproject-740f9-default-rtdb.firebaseio.com/',
  );
  
  String? gameId;
  String? myColor; 
  StreamSubscription? _matchSubscription;

  Future<void> joinQueue(String userId, Function(String gameId, String color) onGameFound) async {
    final waitingRoomRef = _db.ref('matchmaking/waiting_player');
    
    try {
      final snapshot = await waitingRoomRef.get();

      if (snapshot.exists) {
        final waitingData = snapshot.value as Map;
        final waitingUserId = waitingData['userId'];

        // PREVENT PLAYING VS SELF
        if (waitingUserId == userId) {
          print("LOG: Found self in waiting room. Resetting wait...");
          await waitingRoomRef.remove(); // Remove self and wait again
          joinQueue(userId, onGameFound); 
          return;
        }

        final newGameId = "${waitingUserId}_$userId";
        
        // STANDARD START FEN
        String startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1';

        await _db.ref('games/$newGameId').set({
          'white': waitingUserId,
          'black': userId,
          'fen': startFen,
          'turn': 'white',
        });

        await waitingRoomRef.remove();

        myColor = 'black';
        gameId = newGameId;
        onGameFound(newGameId, 'black');

      } else {
        await waitingRoomRef.set({
          'userId': userId,
          'timestamp': ServerValue.timestamp,
        });

        myColor = 'white';
        _matchSubscription = _db.ref('games').onChildAdded.listen((event) {
          if (event.snapshot.key!.contains(userId)) {
            gameId = event.snapshot.key;
            _matchSubscription?.cancel();
            onGameFound(gameId!, 'white');
          }
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> makeMove(String fen) async {
    if (gameId == null) return;
    String nextTurn = (myColor == 'white') ? 'black' : 'white';
    
    // UPDATE FIREBASE
    await _db.ref('games/$gameId').update({
      'fen': fen,
      'turn': nextTurn,
    });
  }

  Future<void> resetGame() async {
    if (gameId == null) return;
    String startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1';
    await _db.ref('games/$gameId').update({
      'fen': startFen,
      'turn': 'white',
    });
  }

  Stream<DatabaseEvent> getGameStream() {
    if (gameId == null) throw Exception("No Game ID");
    return _db.ref('games/$gameId').onValue;
  }

  void dispose() {
    _matchSubscription?.cancel();
  }
}

class OnlineMultiplayerPage extends StatefulWidget {
  @override
  _OnlineMultiplayerPageState createState() => _OnlineMultiplayerPageState();
}

class _OnlineMultiplayerPageState extends State<OnlineMultiplayerPage> {
  final GameController _gameController = GameController();
  final ChessBoardController _boardController = ChessBoardController();
  late String _userId;

  bool _inGame = false;
  String _statusText = "Press 'Find Match' to play";

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? "guest_${Random().nextInt(9999)}";
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  void _findMatch() {
    setState(() {
      _isSearching = true;
      _statusText = "Looking for opponent...";
    });
    _gameController.joinQueue(_userId, (gameId, color) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _inGame = true;
          _statusText = "Playing as ${color.toUpperCase()}";
        });
      }
    });
  }

  bool _isSearching = false;

  void _onUserMove() {
    // 1. Get current board FEN
    final currentFen = _boardController.getFen();
    // 2. Send to Firebase
    _gameController.makeMove(currentFen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Online Multiplayer"),
        actions: [
          if (_inGame)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                // RESET BUTTON FIXES CORRUPTED GAMES
                _gameController.resetGame(); 
              },
            )
        ],
      ),
      body: Center(
        child: !_inGame ? _buildLobby() : _buildGame(),
      ),
    );
  }

  Widget _buildLobby() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_statusText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 30),
        if (_isSearching) 
          CircularProgressIndicator()
        else
          ElevatedButton(onPressed: _findMatch, child: Text("Find Match")),
      ],
    );
  }

  Widget _buildGame() {
    return StreamBuilder<DatabaseEvent>(
      stream: _gameController.getGameStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.snapshot.value as Map;
        final serverFen = data['fen'];
        final serverTurn = data['turn']; 

        // CRITICAL FIX: Only load if FEN is DIFFERENT to prevent loops
        if (serverFen != null && _boardController.getFen() != serverFen) {
          // Additional check: Don't load if WE just made this move locally
           _boardController.loadFen(serverFen);
        }

        final bool isMyTurn = _gameController.myColor == serverTurn;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isMyTurn ? "YOUR TURN" : "OPPONENT'S TURN", 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: isMyTurn ? Colors.green : Colors.red
              )),
            SizedBox(height: 20),
            ChessBoard(
              controller: _boardController,
              boardColor: BoardColor.brown,
              boardOrientation: _gameController.myColor == 'white' ? PlayerColor.white : PlayerColor.black,
              enableUserMoves: isMyTurn, 
              onMove: _onUserMove,
            ),
          ],
        );
      },
    );
  }
}