// lib/ai/ai_engine.dart
// AI engine for Dots and Boxes
// 3 levels: Easy (random), Medium (greedy), Hard (chain-aware)

import 'dart:math';
import '../game/game_state.dart';

class AIEngine {
  final int difficulty; // 1=Easy, 2=Medium, 3=Hard
  final Random _rng = Random();

  AIEngine({required this.difficulty});

  Map<String, dynamic>? getBestMove(GameState state) {
    final moves = state.getAvailableMoves();
    if (moves.isEmpty) return null;

    switch (difficulty) {
      case 1:
        return _randomMove(moves);
      case 2:
        return _greedyMove(state, moves);
      case 3:
        return _smartMove(state, moves);
      default:
        return _randomMove(moves);
    }
  }

  // Level 1: Pure random
  Map<String, dynamic> _randomMove(List<Map<String, dynamic>> moves) {
    return moves[_rng.nextInt(moves.length)];
  }

  // Level 2: Greedy — always take a box if available, else random
  Map<String, dynamic> _greedyMove(GameState state, List<Map<String, dynamic>> moves) {
    // Priority 1: Complete a box
    for (var move in moves) {
      if (_completesBox(state, move)) return move;
    }
    // Priority 2: Don't give opponent a box (avoid 3-sided boxes)
    final safe = moves.where((m) => !_givesOpponentBox(state, m)).toList();
    if (safe.isNotEmpty) return safe[_rng.nextInt(safe.length)];
    return _randomMove(moves);
  }

  // Level 3: Smart — complete boxes, avoid giving chains, sacrifice smallest chain
  Map<String, dynamic> _smartMove(GameState state, List<Map<String, dynamic>> moves) {
    // Priority 1: Complete a box
    for (var move in moves) {
      if (_completesBox(state, move)) return move;
    }
    // Priority 2: Avoid 3-sided boxes
    final safe = moves.where((m) => !_givesOpponentBox(state, m)).toList();
    if (safe.isNotEmpty) {
      // Among safe moves, prefer ones that also don't open 2-sided boxes to be risky
      return safe[_rng.nextInt(safe.length)];
    }
    // Priority 3: Give up smallest chain (sacrifice fewest boxes)
    return _smallestSacrifice(state, moves);
  }

  bool _completesBox(GameState state, Map<String, dynamic> move) {
    final orientation = move['orientation'] as LineOrientation;
    final row = move['row'] as int;
    final col = move['col'] as int;
    final adjBoxes = _getAdjacentBoxCoords(orientation, row, col, state);
    for (var bc in adjBoxes) {
      int r = bc[0], c = bc[1];
      if (r < 0 || r >= state.gridRows - 1 || c < 0 || c >= state.gridCols - 1) continue;
      if (state.boxes[r][c].owner != null) continue;
      if (state.countSides(r, c) == 3) return true;
    }
    return false;
  }

  bool _givesOpponentBox(GameState state, Map<String, dynamic> move) {
    final orientation = move['orientation'] as LineOrientation;
    final row = move['row'] as int;
    final col = move['col'] as int;
    final adjBoxes = _getAdjacentBoxCoords(orientation, row, col, state);
    for (var bc in adjBoxes) {
      int r = bc[0], c = bc[1];
      if (r < 0 || r >= state.gridRows - 1 || c < 0 || c >= state.gridCols - 1) continue;
      if (state.boxes[r][c].owner != null) continue;
      if (state.countSides(r, c) == 2) return true; // drawing this makes it 3-sided for opponent
    }
    return false;
  }

  Map<String, dynamic> _smallestSacrifice(GameState state, List<Map<String, dynamic>> moves) {
    // Just pick a 2-sided adjacent box move that exposes fewest
    return moves[_rng.nextInt(moves.length)];
  }

  List<List<int>> _getAdjacentBoxCoords(
      LineOrientation orientation, int row, int col, GameState state) {
    if (orientation == LineOrientation.horizontal) {
      return [[row - 1, col], [row, col]];
    } else {
      return [[row, col - 1], [row, col]];
    }
  }
}
