import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:firebase_auth/firebase_auth.dart';

// Import Controller & Components
import '../controllers/online_game_controller.dart';
import '../components/game/holo_board.dart';
import '../components/game/captured_pieces_hud.dart';

class OnlineMultiplayerPage extends StatefulWidget {
  @override
  _OnlineMultiplayerPageState createState() => _OnlineMultiplayerPageState();
}

class _OnlineMultiplayerPageState extends State<OnlineMultiplayerPage> {
  late OnlineGameController _controller;
  final User? user = FirebaseAuth.instance.currentUser;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = user?.uid ?? "anon_${DateTime.now().millisecondsSinceEpoch}";
    _controller = OnlineGameController();
    
    // Listen to controller to rebuild UI
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _onBoardMove() {
    _controller.makeMove();
  }

  void _handleExit() {
    if (_controller.status == OnlineStatus.inGame) {
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
                _controller.leaveGame();
              }, 
              child: Text("Leave", style: TextStyle(color: Colors.redAccent))
            ),
          ],
        ),
      );
    } else {
      _controller.leaveGame(); // Cancel search
      Navigator.pop(context); // Go back to home
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = MediaQuery.of(context).size.width - 24;

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
              onPressed: _handleExit,
            ),
            title: Text(_getTitle(), style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: _controller.status == OnlineStatus.inGame 
              ? _buildGameView(boardSize) 
              : _buildLobbyView(),
        ),
      ],
    );
  }

  String _getTitle() {
    switch (_controller.status) {
      case OnlineStatus.lobby: return "ONLINE LOBBY";
      case OnlineStatus.searching: return "SEARCHING...";
      case OnlineStatus.inGame: return "RANKED MATCH";
    }
  }

  // --- VIEW 1: LOBBY ---
  Widget _buildLobbyView() {
    bool isSearching = _controller.status == OnlineStatus.searching;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulse Icon
          Container(
            height: 120, width: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 20)],
            ),
            child: isSearching 
                ? Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: Colors.blueAccent))
                : Icon(Icons.public, size: 60, color: Colors.blueAccent),
          ),
          
          SizedBox(height: 40),

          if (isSearching) ...[
            Text("Scanning for opponent...", style: TextStyle(color: Colors.white70, fontSize: 18)),
            SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => _controller.leaveGame(), 
              child: Text("CANCEL", style: TextStyle(color: Colors.redAccent)),
            )
          ] else ...[
             GestureDetector(
              onTap: () => _controller.joinQueue(_userId),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4834D4)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Text(
                  "FIND MATCH",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // --- VIEW 2: GAME ARENA ---
  Widget _buildGameView(double boardSize) {
    bool amIWhite = _controller.myColor == 'white';
    
    // Check if it's my turn to enable/disable board interaction
    bool canMove = _controller.isMyTurn;

    return SafeArea(
      child: Column(
        children: [
          Spacer(),

          // --- OPPONENT (Top) ---
          _buildPlayerCard(
            name: "OPPONENT",
            rank: amIWhite ? "Playing Black" : "Playing White",
            color: Colors.redAccent,
            isLeftAligned: false,
            // Logic: If I am White, opponent is Black. Opponent captures White pieces ('ai' mode).
            child: CapturedPiecesHUD(
              fen: _controller.fen, 
              capturedBy: amIWhite ? 'ai' : 'player', 
            ),
          ),

          SizedBox(height: 15),

          // --- STATUS BAR ---
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: canMove ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: canMove ? Colors.greenAccent : Colors.redAccent),
            ),
            child: Text(
              canMove ? "YOUR TURN" : "OPPONENT'S TURN",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(height: 15),

          // --- BOARD ---
          // Using HoloBoard for consistency
          IgnorePointer(
            ignoring: !canMove, // Prevent moving if not your turn
            child: HoloBoard(
              controller: _controller.boardController, 
              size: boardSize, 
              onMove: _onBoardMove,
            ),
          ),

          SizedBox(height: 15),

          // --- ME (Bottom) ---
          _buildPlayerCard(
            name: "YOU",
            rank: amIWhite ? "Playing White" : "Playing Black",
            color: Colors.greenAccent,
            isLeftAligned: true,
            // Logic: If I am White, I capture Black pieces ('player' mode).
            child: CapturedPiecesHUD(
              fen: _controller.fen, 
              capturedBy: amIWhite ? 'player' : 'ai',
            ),
          ),

          Spacer(),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({required String name, required String rank, required Color color, required bool isLeftAligned, required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isLeftAligned) ...[CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 16, child: Icon(Icons.person, color: color, size: 18)), SizedBox(width: 10)],
              Column(
                crossAxisAlignment: isLeftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(rank, style: TextStyle(color: color, fontSize: 10)),
                ],
              ),
              if (!isLeftAligned) ...[SizedBox(width: 10), CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 16, child: Icon(Icons.public, color: color, size: 18))],
            ],
          ),
          SizedBox(height: 8),
          Align(
            alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
            child: child,
          ),
        ],
      ),
    );
  }
}