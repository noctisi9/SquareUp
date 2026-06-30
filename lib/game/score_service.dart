// lib/game/score_service.dart
// Persists game history using shared_preferences
// Tracks wins, losses, draws per mode

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameRecord {
  final String winner; // player name or 'Draw'
  final int p1Score;
  final int p2Score;
  final String p1Name;
  final String p2Name;
  final String mode; // vsAI / vsLocal
  final int gridSize;
  final DateTime playedAt;

  GameRecord({
    required this.winner,
    required this.p1Score,
    required this.p2Score,
    required this.p1Name,
    required this.p2Name,
    required this.mode,
    required this.gridSize,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
    'winner': winner,
    'p1Score': p1Score,
    'p2Score': p2Score,
    'p1Name': p1Name,
    'p2Name': p2Name,
    'mode': mode,
    'gridSize': gridSize,
    'playedAt': playedAt.toIso8601String(),
  };

  factory GameRecord.fromJson(Map<String, dynamic> j) => GameRecord(
    winner: j['winner'],
    p1Score: j['p1Score'],
    p2Score: j['p2Score'],
    p1Name: j['p1Name'],
    p2Name: j['p2Name'],
    mode: j['mode'],
    gridSize: j['gridSize'],
    playedAt: DateTime.parse(j['playedAt']),
  );
}

class ScoreService {
  static const _key = 'dab_history';

  static Future<void> saveRecord(GameRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.add(jsonEncode(record.toJson()));
    // Keep last 100 games
    if (existing.length > 100) existing.removeAt(0);
    await prefs.setStringList(_key, existing);
  }

  static Future<List<GameRecord>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => GameRecord.fromJson(jsonDecode(s)))
        .toList()
        .reversed
        .toList();
  }

  static Future<Map<String, int>> getStats() async {
    final history = await loadHistory();
    int wins = 0, losses = 0, draws = 0;
    for (final r in history) {
      if (r.winner == 'Draw') {
        draws++;
      } else if (r.winner == r.p1Name) {
        wins++;
      } else {
        losses++;
      }
    }
    return {'wins': wins, 'losses': losses, 'draws': draws, 'total': history.length};
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
