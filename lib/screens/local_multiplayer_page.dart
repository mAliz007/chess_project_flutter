import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart'; 

// Import Controller & Components
import '../controllers/local_multiplayer_controller.dart';
import '../components/game/holo_board.dart';
import '../components/game/captured_pieces_hud.dart';
import '../components/game/local_turn_hud.dart'; // New component

class LocalMultiplayerPage extends StatefulWidget {
  @override
  _LocalMultiplayerPageState createState() => _LocalMultiplayerPageState();
}

class _LocalMultiplayerPageState extends State<LocalMultiplayerPage> {
  late LocalMultiplayerController _gameController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _gameController = LocalMultiplayerController();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Rebuild UI on turn change
    _gameController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _gameController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  void _onMove() {
    // 1. Sync State
    _gameController.onMove();

    // 2. Check Game Over
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
        title = "WHITE WINS!";
        msg = "Player 1 takes the victory.";
        break;
      case LocalGameStatus.blackWins:
        title = "BLACK WINS!";
        msg = "Player 2 takes the victory.";
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

  // --- DIALOGS ---

  void _showGameOverDialog(String title, String msg, bool isWin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1F222B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isWin ? Colors.amber : Colors.grey, width: 2)
        ),
        title: Column(
          children: [
            Icon(Icons.emoji_events, size: 50, color: isWin ? Colors.amber : Colors.grey),
            SizedBox(height: 10),
            Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
        content: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text("LEAVE", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _gameController.resetGame();
            },
            child: Text("REMATCH"),
          ),
        ],
      ),
    );
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

        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // Top Bar
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
                      // NEW TURN HUD
                      LocalTurnHUD(isWhiteTurn: _gameController.isWhiteTurn),
                      SizedBox(width: 40),
                    ],
                  ),
                ),

                Spacer(),

                // PLAYER 2 (BLACK)
                _buildPlayerCard(
                  name: "PLAYER 2",
                  rank: "Black Pieces",
                  color: Colors.pinkAccent, // Distinct color for P2
                  isLeftAligned: false,
                  // Logic: Player 2 (Black) captures White pieces. 
                  // In our HUD, 'ai' mode shows White pieces captured.
                  child: CapturedPiecesHUD(fen: _gameController.fen, capturedBy: 'ai'), 
                ),

                SizedBox(height: 12),

                // Board
                HoloBoard(
                  controller: _gameController.boardController, 
                  size: boardSize,
                  onMove: _onMove,
                ),

                SizedBox(height: 12),

                // PLAYER 1 (WHITE)
                _buildPlayerCard(
                  name: "PLAYER 1",
                  rank: "White Pieces",
                  color: Colors.greenAccent,
                  isLeftAligned: true,
                  // Logic: Player 1 (White) captures Black pieces.
                  // In our HUD, 'player' mode shows Black pieces captured.
                  child: CapturedPiecesHUD(fen: _gameController.fen, capturedBy: 'player'),
                ),

                Spacer(),
                Text("Pass device to opponent", style: TextStyle(color: Colors.white24, fontSize: 12)),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // Confetti
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

  Widget _buildPlayerCard({required String name, required String rank, required Color color, required bool isLeftAligned, required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
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
              if (!isLeftAligned) ...[SizedBox(width: 10), CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 16, child: Icon(Icons.person_outline, color: color, size: 18))],
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