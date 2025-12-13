// Location: lib/screens/local_multiplayer_page.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

// Import Controller & Components
import '../controllers/local_multiplayer_controller.dart';
import '../components/game/holo_board.dart';
import '../components/game/local_turn_hud.dart';

// Import NEW components
import '../components/local_game/LocalNameInputDialog.dart';
import '../components/local_game/LocalGameOverDialog.dart';
import '../components/local_game/LocalPlayerCard.dart';

class LocalMultiplayerPage extends StatefulWidget {
  @override
  _LocalMultiplayerPageState createState() => _LocalMultiplayerPageState();
}

class _LocalMultiplayerPageState extends State<LocalMultiplayerPage> {
  late LocalMultiplayerController _gameController;
  late ConfettiController _confettiController;
  
  String _player1Name = "Player 1"; // White (Default)
  String _player2Name = "Player 2"; // Black (Default)

  @override
  void initState() {
    super.initState();
    _gameController = LocalMultiplayerController();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    _gameController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNameInputDialog();
    });
  }

  @override
  void dispose() {
    _gameController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // --- DIALOG WRAPPERS (Calls the external components) ---

  void _showNameInputDialog() {
    LocalNameInputDialog.show(
      context: context,
      p1DefaultName: _player1Name,
      p2DefaultName: _player2Name,
      onNamesConfirmed: (p1Name, p2Name) {
        setState(() {
          _player1Name = p1Name;
          _player2Name = p2Name;
        });
      },
    );
  }

  void _showGameOverDialog(String title, String msg, bool isWin) {
    LocalGameOverDialog.show(
      context: context,
      title: title,
      msg: msg,
      isWin: isWin,
      gameController: _gameController,
    );
  }

  // --- LOGIC ---

  void _onMove() {
    _gameController.onMove();

    LocalGameStatus status = _gameController.checkGameOver();
    if (status != LocalGameStatus.playing) {
      _handleGameOver(status);
    }
  }

  void _handleGameOver(LocalGameStatus status) {
    if (status != LocalGameStatus.draw) {
      _confettiController.play();
    }

    String title;
    String msg;
    bool isWin = true;

    switch (status) {
      case LocalGameStatus.whiteWins:
        title = "${_player1Name.toUpperCase()} WINS!";
        msg = "$_player1Name takes the victory playing White.";
        break;
      case LocalGameStatus.blackWins:
        title = "${_player2Name.toUpperCase()} WINS!";
        msg = "$_player2Name takes the victory playing Black.";
        break;
      case LocalGameStatus.draw:
        title = "DRAW";
        msg = "Stalemate or Repetition.";
        isWin = false;
        break;
      default:
        return;
    }

    _showGameOverDialog(title, msg, isWin);
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1F222B),
        title: Text("End Match?", style: TextStyle(color: Colors.white)),
        content: Text("Current progress will be lost.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: Text("Quit", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = MediaQuery.of(context).size.width - 24;

    return Stack(
      children: [
        Positioned.fill(child: Image.asset('assets/images/chess_bg.jpg', fit: BoxFit.cover)),
        Positioned.fill(child: Container(color: Color(0xFF120E29).withOpacity(0.95))),

// Modified SCROLLABLE Scaffold body (starts around line 140)

        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView( // <-- NEW: Add SingleChildScrollView
              child: Column(
                children: [
                  // --- TOP BAR ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.grid_view_rounded, color: Colors.white70),
                            color: Color(0xFF2A2D3A),
                            onSelected: (value) {
                              if (value == 'quit') _showExitDialog();
                              if (value == 'restart') _gameController.resetGame();
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'restart', child: Row(children: [Icon(Icons.refresh, color: Colors.blueAccent), SizedBox(width: 8), Text("Restart", style: TextStyle(color: Colors.white))])),
                              PopupMenuItem(value: 'quit', child: Row(children: [Icon(Icons.exit_to_app, color: Colors.redAccent), SizedBox(width: 8), Text("Quit", style: TextStyle(color: Colors.white))])),
                            ],
                          ),
                        ),
                        LocalTurnHUD(isWhiteTurn: _gameController.isWhiteTurn),
                        SizedBox(width: 40),
                      ],
                    ),
                  ),

                  // The Spacers need to be replaced with SizedBoxes now,
                  // because Spacers only work inside a tight Column/Row without SingleChildScrollView.
                  SizedBox(height: 16), // Replaces first Spacer

                  // PLAYER 2 (BLACK) - Uses new component
                  LocalPlayerCard(
                    name: _player2Name.toUpperCase(),
                    rank: "Black Pieces",
                    color: Colors.pinkAccent,
                    isLeftAligned: false,
                    fen: _gameController.fen, 
                    capturedBy: 'ai', // Black captures White pieces
                  ),

                  SizedBox(height: 12),

                  // Board
                  HoloBoard(
                    controller: _gameController.boardController, 
                    size: boardSize,
                    onMove: _onMove,
                  ),

                  SizedBox(height: 12),

                  // PLAYER 1 (WHITE) - Uses new component
                  LocalPlayerCard(
                    name: _player1Name.toUpperCase(),
                    rank: "White Pieces",
                    color: Colors.greenAccent,
                    isLeftAligned: true,
                    fen: _gameController.fen, 
                    capturedBy: 'player', // White captures Black pieces
                  ),

                  SizedBox(height: 16), // Replaces second Spacer
                  Text("Pass device to opponent", style: TextStyle(color: Colors.white24, fontSize: 12)),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),

        // Confetti (Must remain in the Stack)
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false, 
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.amber], 
            numberOfParticles: 50,
            gravity: 0.1,
          ),
        ),
      ],
    );
  }
}