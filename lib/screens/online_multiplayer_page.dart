// lib/screens/online_multiplayer_page.dart - UPDATED WITH TIMER INTEGRATION

// Import Flutter material widgets
import 'package:flutter/material.dart';
// Import Flutter Chess Board library, hide Color to avoid conflict
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
// Import Firebase Authentication
import 'package:firebase_auth/firebase_auth.dart';

// Import controller for online game logic
import '../controllers/online_game_controller.dart';

// Import UI Components
import '../components/game/holo_board.dart';
import '../components/game/captured_pieces_hud.dart';
import '../components/online_game/OnlinePlayerCard.dart';
import '../components/online_game/OnlineLobbyView.dart';
import '../components/online_game/OnlineRejoinView.dart';
import '../components/online_game/OnlineGameOverView.dart';
import '../components/online_game/OnlineTimer.dart'; // NEW TIMER IMPORT

// Stateful widget for online multiplayer chess
class OnlineMultiplayerPage extends StatefulWidget {
  @override
  _OnlineMultiplayerPageState createState() => _OnlineMultiplayerPageState();
}

class _OnlineMultiplayerPageState extends State<OnlineMultiplayerPage> {
  late OnlineGameController _controller; // Manages online game state
  final User? user = FirebaseAuth.instance.currentUser; // Current signed-in Firebase user
  late String _userId; // Unique ID for player

  @override
  void initState() {
    super.initState();
    // Generate user ID if user is anonymous
    _userId = user?.uid ?? "anon_${DateTime.now().millisecondsSinceEpoch}";
    _controller = OnlineGameController(); // Initialize controller

    // Listen to controller updates to rebuild UI
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose controller when widget removed
    super.dispose();
  }

  // --- ACTIONS ---

  // Called when a move is made on the board
  void _onBoardMove() {
    // Controller's makeMove handles the timer logic
    _controller.makeMove();
  }

  // Handle back/exit button
  void _handleExit() {
    if (_controller.status == OnlineStatus.inGame) {
      // Confirm leaving if game is ongoing
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Color(0xFF1F222B),
          title: Text("Leave Match?", style: TextStyle(color: Colors.white)),
          content: Text("You will forfeit this game.", style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: Colors.white54))),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _controller.forfeitGame(); // Calls the forfeit method to end game
              },
              child: Text("Leave", style: TextStyle(color: Colors.redAccent))
            ),
          ],
        ),
      );
    } else if (_controller.status == OnlineStatus.rejoinNeeded || _controller.status == OnlineStatus.gameOver) {
      // If stuck on rejoin or game over screen, just cancel and go back
      _controller.leaveGame();
      Navigator.pop(context);
    } else {
      _controller.leaveGame(); // Cancel queue/search
      Navigator.pop(context); // Go back to home
    }
  }

  // Determine title based on current game status
  String _getTitle() {
    switch (_controller.status) {
      case OnlineStatus.lobby: return "ONLINE LOBBY";
      case OnlineStatus.searching: return "SEARCHING...";
      case OnlineStatus.inGame: return "RANKED MATCH";
      case OnlineStatus.rejoinNeeded: return "GAME FOUND";
      case OnlineStatus.gameOver: return "MATCH ENDED";
    }
  }

  // --- BODY VIEW SWITCH ---
  Widget _buildBody(double boardSize) {
    switch (_controller.status) {
      case OnlineStatus.inGame:
        return _buildGameView(boardSize);
      case OnlineStatus.rejoinNeeded:
        return OnlineRejoinView(controller: _controller);
      case OnlineStatus.gameOver:
        return OnlineGameOverView(controller: _controller, userId: _userId);
      case OnlineStatus.lobby:
      case OnlineStatus.searching:
      default:
        return OnlineLobbyView(controller: _controller, userId: _userId);
    }
  }

  // --- GAME ARENA VIEW (now using the new component) ---
  Widget _buildGameView(double boardSize) {
    bool amIWhite = _controller.myColor == 'white';
    bool canMove = _controller.isMyTurn;

    return SafeArea(
      child: Column(
        children: [
          Spacer(),

          // --- OPPONENT (Top) ---
          OnlinePlayerCard(
            name: "OPPONENT",
            rank: amIWhite ? "Playing Black" : "Playing White",
            color: Colors.redAccent,
            isLeftAligned: false,
            capturedPiecesHud: CapturedPiecesHUD(
              fen: _controller.fen,
              capturedBy: amIWhite ? 'ai' : 'player',
            ),
          ),

          SizedBox(height: 15),

          // --- TIMER COMPONENT ---
          OnlineTimer(
            timeRemaining: _controller.timeRemaining,
            isMyTurn: canMove,
            isOpponentTurn: !canMove,
          ),

          SizedBox(height: 15),

          // --- BOARD ---
          IgnorePointer(
            ignoring: !canMove,
            child: HoloBoard(
              controller: _controller.boardController,
              size: boardSize,
              onMove: _onBoardMove,
            ),
          ),

          SizedBox(height: 15),

          // --- ME (Bottom) ---
          OnlinePlayerCard(
            name: "YOU",
            rank: amIWhite ? "Playing White" : "Playing Black",
            color: Colors.greenAccent,
            isLeftAligned: true,
            capturedPiecesHud: CapturedPiecesHUD(
              fen: _controller.fen,
              capturedBy: amIWhite ? 'player' : 'ai',
            ),
          ),

          Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = MediaQuery.of(context).size.width - 24; // Calculate board size

    return Stack(
      children: [
        // 1. Background Image
        Positioned.fill(child: Image.asset('assets/images/chess_bg.jpg', fit: BoxFit.cover)),
        // 2. Dark Overlay
        Positioned.fill(child: Container(color: Color(0xFF120E29).withOpacity(0.95))),

        // 3. Main Scaffold
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _handleExit, // Back/exit button
            ),
            title: Text(_getTitle(), style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: _buildBody(boardSize), // Use the body switch method
        ),
      ],
    );
  }
}