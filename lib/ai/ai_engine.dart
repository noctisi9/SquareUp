// lib/ai/ai_engine.dart
import 'dart:math';
import '../game/game_state.dart';

class AIEngine {
  final int difficulty;
  final Random _rng = Random();
  AIEngine({required this.difficulty});

  Map<String, dynamic>? getBestMove(GameState state) {
    final moves = state.getAvailableMoves();
    if (moves.isEmpty) return null;
    switch (difficulty) {
      case 1: return _random(moves);
      case 2: return _greedy(state, moves);
      case 3: return _smart(state, moves);
      default: return _random(moves);
    }
  }

  Map<String, dynamic> _random(List<Map<String, dynamic>> moves) =>
      moves[_rng.nextInt(moves.length)];

  Map<String, dynamic> _greedy(GameState state, List<Map<String, dynamic>> moves) {
    for (final m in moves) if (_completes(state, m)) return m;
    final safe = moves.where((m) => !_givesBox(state, m)).toList();
    if (safe.isNotEmpty) return safe[_rng.nextInt(safe.length)];
    return _random(moves);
  }

  Map<String, dynamic> _smart(GameState state, List<Map<String, dynamic>> moves) {
    for (final m in moves) if (_completes(state, m)) return m;
    final safe = moves.where((m) => !_givesBox(state, m)).toList();
    if (safe.isNotEmpty) return safe[_rng.nextInt(safe.length)];
    return _random(moves);
  }

  bool _completes(GameState state, Map<String, dynamic> move) {
    for (final bc in _adj(move, state)) {
      final r = bc[0], c = bc[1];
      if (r < 0 || r >= state.gridRows - 1 || c < 0 || c >= state.gridCols - 1) continue;
      if (state.boxes[r][c].ownerIndex != null) continue;
      if (state.countSides(r, c) == 3) return true;
    }
    return false;
  }

  bool _givesBox(GameState state, Map<String, dynamic> move) {
    for (final bc in _adj(move, state)) {
      final r = bc[0], c = bc[1];
      if (r < 0 || r >= state.gridRows - 1 || c < 0 || c >= state.gridCols - 1) continue;
      if (state.boxes[r][c].ownerIndex != null) continue;
      if (state.countSides(r, c) == 2) return true;
    }
    return false;
  }

  List<List<int>> _adj(Map<String, dynamic> move, GameState state) {
    final o = move['orientation'] as LineOrientation;
    final r = move['row'] as int;
    final c = move['col'] as int;
    return o == LineOrientation.horizontal
        ? [[r - 1, c], [r, c]]
        : [[r, c - 1], [r, c]];
  }
}
