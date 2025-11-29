// Location: lib/screens/single_player_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart'; 

// Controller & Components
import '../controllers/single_player_controller.dart';
import '../components/game/game_status_hud.dart';
import '../components/game/holo_board.dart';
import '../components/game/captured_pieces_hud.dart';

class SinglePlayerPage extends StatefulWidget {
  final int difficultyDepth;
  final String difficultyLabel;

  const SinglePlayerPage({
    Key? key, 
    this.difficultyDepth = 5, 
    this.difficultyLabel = "CASUAL"
  }) : super(key: key);

  @override
  _SinglePlayerPageState createState() => _SinglePlayerPageState();
}

class _SinglePlayerPageState extends State<SinglePlayerPage> {
  late SinglePlayerController _gameController;
  late ConfettiController _confettiController;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _gameController = SinglePlayerController();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
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

  // --- GAMEPLAY INTERACTION ---

  Future<void> _onMove() async {
    if (_checkAndShowGameOver()) return;

    bool success = await _gameController.makeAiMove(widget.difficultyDepth);
    
    if (success) {
      _checkAndShowGameOver();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection Interrupt."), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  bool _checkAndShowGameOver() {
    GameStatus status = _gameController.checkGameOver();
    
    if (status != GameStatus.playing) {
      bool playerLost = _gameController.didPlayerLose();
      bool isDraw = status == GameStatus.draw;

      if (!playerLost && !isDraw) {
        _confettiController.play(); 
      }

      String title = isDraw ? "DRAW" : (playerLost ? "DEFEAT" : "VICTORY");
      String msg = isDraw 
          ? "Stalemate or Repetition." 
          : (playerLost ? "Better luck next time." : "Congratulations!");

      _showGameOverDialog(title, msg, !playerLost && !isDraw);
      return true;
    }
    return false;
  }

  // --- DIALOGS ---

  void _showGameOverDialog(String title, String msg, bool isVictory) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1F222B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isVictory ? Colors.greenAccent : Colors.redAccent, width: 2)
        ),
        title: Column(
          children: [
            Icon(isVictory ? Icons.emoji_events : Icons.close, 
                 size: 50, color: isVictory ? Colors.amber : Colors.redAccent),
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
            style: ElevatedButton.styleFrom(backgroundColor: isVictory ? Colors.green : Colors.blue),
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
        title: Text("Resign Game?", style: TextStyle(color: Colors.white)),
        content: Text("You will return to the lobby.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: Text("Resign", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = MediaQuery.of(context).size.width - 24;
    
    String playerName = user?.displayName ?? "Commander";
    if (playerName == "Commander" && user?.email != null) {
      playerName = user!.email!.split('@')[0];
    }

    return Stack(
      children: [
        Positioned.fill(child: Image.asset('assets/images/chess_bg.jpg', fit: BoxFit.cover)),
        Positioned.fill(child: Container(color: Color(0xFF120E29).withOpacity(0.95))),

        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
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
                            if (value == 'resign') _showExitDialog();
                            if (value == 'restart') _gameController.resetGame();
                          },
                          // --- UPDATED MENU ITEMS WITH ICONS ---
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'restart', 
                              child: Row(
                                children: [
                                  Icon(Icons.refresh, color: Colors.blueAccent), 
                                  SizedBox(width: 8), 
                                  Text("Restart", style: TextStyle(color: Colors.white))
                                ],
                              )
                            ),
                            PopupMenuItem(
                              value: 'resign', 
                              child: Row(
                                children: [
                                  Icon(Icons.flag, color: Colors.redAccent), 
                                  SizedBox(width: 8), 
                                  Text("Resign", style: TextStyle(color: Colors.white))
                                ],
                              )
                            ),
                          ],
                        ),
                      ),
                      GameStatusHUD(isAiThinking: _gameController.isAiThinking),
                      SizedBox(width: 40), 
                    ],
                  ),
                ),

                Spacer(),

                // Opponent Card
                _buildPlayerCard(
                  name: "STOCKFISH AI",
                  rank: widget.difficultyLabel,
                  color: Colors.redAccent,
                  isLeftAligned: false,
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

                // Player Card
                _buildPlayerCard(
                  name: playerName.toUpperCase(),
                  rank: "Online",
                  color: Colors.greenAccent,
                  isLeftAligned: true,
                  child: CapturedPiecesHUD(fen: _gameController.fen, capturedBy: 'player'),
                ),

                Spacer(),
                Text("Tap a piece to see moves", style: TextStyle(color: Colors.white24, fontSize: 12)),
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
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple], 
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
              if (!isLeftAligned) ...[SizedBox(width: 10), CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 16, child: Icon(Icons.computer, color: color, size: 18))],
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