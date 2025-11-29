import 'dart:convert';
import 'package:http/http.dart' as http;

/// This service handles communicating with the Stockfish Chess Engine API
class StockfishService {
  
  /// Fetches the best move for a given FEN string.
  /// Returns the move code (e.g., "e2e4") or null if failed.
  Future<String?> getBestMove(String fen, {int depth = 5}) async {
    try {
      final url = Uri.parse('https://stockfish.online/api/s/v2.php?fen=$fen&depth=$depth');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Response format example: "bestmove e2e4 ponder..."
          final bestMoveString = data['bestmove']; 
          final moveParts = bestMoveString.split(' ');
          
          // Return just the move part (e.g., "e2e4")
          return moveParts[1]; 
        }
      }
      return null;
    } catch (e) {
      print("Stockfish Service Error: $e");
      return null;
    }
  }
}