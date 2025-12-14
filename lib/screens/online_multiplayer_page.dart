// Import Flutter material widgets
import 'package:flutter/material.dart';
// Import Flutter Chess Board library, hide Color to avoid conflict
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
// Import Firebase Authentication
import 'package:firebase_auth/firebase_auth.dart';

// Import controller for online game logic & UI components
import '../controllers/online_game_controller.dart';
import '../components/game/holo_board.dart';
import '../components/game/captured_pieces_hud.dart';

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
                _controller.forfeitGame(); // Now calls the forfeit method to end game
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
          body: _buildBody(boardSize), // Use a switch method for cleaner body
        ),
      ],
    );
  }

  // NEW: Body switch to handle all states
  Widget _buildBody(double boardSize) {
    switch (_controller.status) {
      case OnlineStatus.inGame:
        return _buildGameView(boardSize);
      case OnlineStatus.rejoinNeeded:
        return _buildRejoinView(); 
      case OnlineStatus.gameOver: // NEW CASE ADDED
        return _buildGameOverView();
      case OnlineStatus.lobby:
      case OnlineStatus.searching:
      default:
        return _buildLobbyView();
    }
  }

  // Determine title based on current game status
  String _getTitle() {
    switch (_controller.status) {
      case OnlineStatus.lobby: return "ONLINE LOBBY";
      case OnlineStatus.searching: return "SEARCHING...";
      case OnlineStatus.inGame: return "RANKED MATCH";
      case OnlineStatus.rejoinNeeded: return "GAME FOUND"; 
      case OnlineStatus.gameOver: return "MATCH ENDED"; // NEW TITLE
    }
  }

  // --- VIEW 1: LOBBY & SEARCHING (No changes) ---
  Widget _buildLobbyView() {
    bool isSearching = _controller.status == OnlineStatus.searching;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulse circle or spinning icon
          Container(
            height: 120, width: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 20)],
            ),
            child: isSearching 
                ? Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: Colors.blueAccent)) // Searching indicator
                : Icon(Icons.public, size: 60, color: Colors.blueAccent), // Idle lobby icon
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
            // Find match button
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

  // --- VIEW 2: GAME ARENA (No changes) ---
  Widget _buildGameView(double boardSize) {
    bool amIWhite = _controller.myColor == 'white'; // Determine player color
    
    // Check if player can move
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
            // Captured pieces HUD for opponent
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
          IgnorePointer(
            ignoring: !canMove, // Disable interaction if not player's turn
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
            // Captured pieces HUD for player
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

  // --- VIEW 3: REJOIN / FORFEIT (No changes) ---
  Widget _buildRejoinView() {
    final myColorText = _controller.myColor == 'white' ? 'White' : 'Black';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orangeAccent),
            SizedBox(height: 20),
            Text(
              "Unfinished Game Detected!",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "You were playing as $myColorText in a previous match. What would you like to do?",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            
            // Rejoin Button
            ElevatedButton.icon(
              icon: Icon(Icons.refresh, color: Colors.black),
              label: Text("REJOIN MATCH", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () => _controller.rejoinGame(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            SizedBox(height: 20),
            
            // Forfeit Button
            OutlinedButton.icon(
              icon: Icon(Icons.flag, color: Colors.redAccent),
              label: Text("FORFEIT & START NEW", style: TextStyle(fontSize: 16, color: Colors.redAccent)),
              onPressed: () {
                // Confirm action before forfeiting and deleting the game
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Color(0xFF1F222B),
                    title: Text("Forfeit Game?", style: TextStyle(color: Colors.white)),
                    content: Text("This will abandon the unfinished match permanently.", style: TextStyle(color: Colors.grey)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: Colors.white54))),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _controller.forfeitGame();
                        }, 
                        child: Text("Forfeit", style: TextStyle(color: Colors.redAccent))
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 60),
                side: BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW VIEW 4: GAME OVER ---
  Widget _buildGameOverView() {
    final isWinner = _controller.winnerId == _userId;
    final titleText = isWinner ? "VICTORY!" : "DEFEAT!";
    final messageText = _getGameOverMessage();
    final color = isWinner ? Colors.greenAccent : Colors.redAccent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied, size: 80, color: color),
            SizedBox(height: 20),
            Text(
              titleText,
              style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              messageText,
              style: TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            
            // Return to Lobby Button
            ElevatedButton.icon(
              icon: Icon(Icons.home, color: Colors.black),
              label: Text("RETURN TO LOBBY", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () {
                // Clean up game state and return to lobby view
                _controller.leaveGame();
                // Note: The controller sets status to 'lobby', triggering a rebuild of _buildLobbyView
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper to determine the message based on the game status field
  String _getGameOverMessage() {
    switch (_controller.gameStatus) {
      case 'forfeited':
        return _controller.winnerId == _userId
            ? "Your opponent has forfeited the match."
            : "You forfeited the match.";
      // case 'checkmate':
      //   return "The game ended by Checkmate.";
      // case 'stalemate':
      //   return "The game ended in a Stalemate.";
      default:
        return "The match has ended.";
    }
  }

  // Player info card with captured pieces HUD (No changes)
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
              if (isLeftAligned) ...[
                CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 16, child: Icon(Icons.person, color: color, size: 18)), 
                SizedBox(width: 10)
              ],
              Column(
                crossAxisAlignment: isLeftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(rank, style: TextStyle(color: color, fontSize: 10)),
                ],
              ),
              if (!isLeftAligned) ...[
                SizedBox(width: 10), 
                CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 16, child: Icon(Icons.public, color: color, size: 18))
              ],
            ],
          ),
          SizedBox(height: 8),
          Align(
            alignment: isLeftAligned ? Alignment.centerLeft : Alignment.centerRight,
            child: child, // Captured pieces HUD
          ),
        ],
      ),
    );
  }
}