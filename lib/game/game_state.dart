// lib/game/game_state.dart — N-player rewrite
import 'dart:ui';

enum GameMode { vsAI, vsLocal, vsOnline }
enum LineOrientation { horizontal, vertical }

// ── Player colors palette ────────────────────────────────────────────────────
class PlayerColors {
  static const List<Color> palette = [
    Color(0xFFE63946), // Red
    Color(0xFF457BFF), // Blue
    Color(0xFF2DC653), // Green
    Color(0xFFFFD166), // Yellow
    Color(0xFFFF6BB5), // Pink
    Color(0xFFAB63F5), // Purple
    Color(0xFFFF8C42), // Orange
    Color(0xFF00FFCC), // Cyan
    Color(0xFFFFFFFF), // White
    Color(0xFFB5FF6D), // Lime
  ];

  static const List<String> names = [
    'Red','Blue','Green','Yellow','Pink',
    'Purple','Orange','Cyan','White','Lime',
  ];
}

// ── Player definition ─────────────────────────────────────────────────────────
class PlayerDef {
  int index;        // 0-based — mutable so we can swap player order
  String name;
  String initial;
  Color color;
  int score;
  int penaltyPoints;      // Time Attack: accumulated lost points

  PlayerDef({
    required this.index,
    required this.name,
    required this.initial,
    required this.color,
    this.score = 0,
    this.penaltyPoints = 0,
  });

  // Effective score = boxes - penalties
  int get effectiveScore => score - penaltyPoints;

  PlayerDef copy() => PlayerDef(
    index: index, name: name, initial: initial, color: color,
    score: score, penaltyPoints: penaltyPoints,
  );
}

// ── Line / Box ────────────────────────────────────────────────────────────────
class Line {
  final int row, col;
  final LineOrientation orientation;
  int? ownerIndex; // null = undrawn
  Line({required this.row, required this.col, required this.orientation, this.ownerIndex});
}

class Box {
  final int row, col;
  int? ownerIndex;
  Box({required this.row, required this.col, this.ownerIndex});
}

// ── Undo snapshot ─────────────────────────────────────────────────────────────
class _Snapshot {
  final List<List<int?>> hOwners, vOwners, boxOwners;
  final int currentIndex;
  final List<int> scores;
  final List<int> penalties;
  final bool gameOver;

  _Snapshot({
    required this.hOwners, required this.vOwners, required this.boxOwners,
    required this.currentIndex, required this.scores, required this.penalties,
    required this.gameOver,
  });
}

// ── Main game state ───────────────────────────────────────────────────────────
class GameState {
  final int gridCols, gridRows;
  final GameMode mode;
  final List<PlayerDef> players;

  // Time Attack
  final bool isTimeAttack;
  final int timeLimitSeconds; // 0 = free play

  late List<List<Line>> hLines, vLines;
  late List<List<Box>> boxes;

  int currentIndex = 0;
  bool gameOver = false;

  final List<_Snapshot> _undoStack = [];
  final List<_Snapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  GameState({
    required this.gridCols,
    required this.gridRows,
    required this.mode,
    required this.players,
    this.isTimeAttack = false,
    this.timeLimitSeconds = 0,
  }) {
    _initBoard();
  }

  void _initBoard() {
    hLines = List.generate(gridRows,
        (r) => List.generate(gridCols - 1,
            (c) => Line(row: r, col: c, orientation: LineOrientation.horizontal)));
    vLines = List.generate(gridRows - 1,
        (r) => List.generate(gridCols,
            (c) => Line(row: r, col: c, orientation: LineOrientation.vertical)));
    boxes = List.generate(gridRows - 1,
        (r) => List.generate(gridCols - 1, (c) => Box(row: r, col: c)));
    currentIndex = 0;
    gameOver = false;
    for (final p in players) { p.score = 0; p.penaltyPoints = 0; }
    _undoStack.clear();
    _redoStack.clear();
  }

  // ── Current player ────────────────────────────────────────────────────────
  PlayerDef get currentPlayer => players[currentIndex];
  String get currentPlayerName => currentPlayer.name;
  String get currentPlayerInitial => currentPlayer.initial;
  int get currentPlayerColorValue => currentPlayer.color.value;

  // ── Snapshot ──────────────────────────────────────────────────────────────
  _Snapshot _snapshot() => _Snapshot(
    hOwners: hLines.map((r) => r.map((l) => l.ownerIndex).toList()).toList(),
    vOwners: vLines.map((r) => r.map((l) => l.ownerIndex).toList()).toList(),
    boxOwners: boxes.map((r) => r.map((b) => b.ownerIndex).toList()).toList(),
    currentIndex: currentIndex,
    scores: players.map((p) => p.score).toList(),
    penalties: players.map((p) => p.penaltyPoints).toList(),
    gameOver: gameOver,
  );

  void _restore(_Snapshot s) {
    for (int r = 0; r < hLines.length; r++)
      for (int c = 0; c < hLines[r].length; c++)
        hLines[r][c].ownerIndex = s.hOwners[r][c];
    for (int r = 0; r < vLines.length; r++)
      for (int c = 0; c < vLines[r].length; c++)
        vLines[r][c].ownerIndex = s.vOwners[r][c];
    for (int r = 0; r < boxes.length; r++)
      for (int c = 0; c < boxes[r].length; c++)
        boxes[r][c].ownerIndex = s.boxOwners[r][c];
    currentIndex = s.currentIndex;
    for (int i = 0; i < players.length; i++) {
      players[i].score = s.scores[i];
      players[i].penaltyPoints = s.penalties[i];
    }
    gameOver = s.gameOver;
  }

  bool undo() {
    if (_undoStack.isEmpty) return false;
    _redoStack.add(_snapshot());
    _restore(_undoStack.removeLast());
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) return false;
    _undoStack.add(_snapshot());
    _restore(_redoStack.removeLast());
    return true;
  }

  // ── Draw line ─────────────────────────────────────────────────────────────
  MoveResult drawLine(LineOrientation orientation, int row, int col) {
    final line = orientation == LineOrientation.horizontal
        ? hLines[row][col] : vLines[row][col];
    if (line.ownerIndex != null) return MoveResult(success: false, boxesCompleted: 0);

    _undoStack.add(_snapshot());
    _redoStack.clear();

    line.ownerIndex = currentIndex;
    final completed = _checkBoxes(orientation, row, col);
    if (completed > 0) {
      players[currentIndex].score += completed;
      // stay on same player — bonus turn
    } else {
      _advanceTurn();
    }
    gameOver = _allBoxesFilled();
    return MoveResult(success: true, boxesCompleted: completed);
  }

  // ── Time Attack: timeout penalty ──────────────────────────────────────────
  void applyTimeoutPenalty() {
    // Penalise current player 1 point
    players[currentIndex].penaltyPoints += 1;
    // Advance to next player
    _advanceTurn();
  }

  void _advanceTurn() {
    currentIndex = (currentIndex + 1) % players.length;
  }

  int _checkBoxes(LineOrientation orientation, int row, int col) {
    int count = 0;
    for (final bc in _adjacent(orientation, row, col)) {
      final br = bc[0], bc2 = bc[1];
      if (br < 0 || br >= gridRows - 1 || bc2 < 0 || bc2 >= gridCols - 1) continue;
      if (boxes[br][bc2].ownerIndex != null) continue;
      if (_isComplete(br, bc2)) { boxes[br][bc2].ownerIndex = currentIndex; count++; }
    }
    return count;
  }

  List<List<int>> _adjacent(LineOrientation o, int row, int col) =>
      o == LineOrientation.horizontal
          ? [[row - 1, col], [row, col]]
          : [[row, col - 1], [row, col]];

  bool _isComplete(int r, int c) =>
      hLines[r][c].ownerIndex != null &&
      hLines[r + 1][c].ownerIndex != null &&
      vLines[r][c].ownerIndex != null &&
      vLines[r][c + 1].ownerIndex != null;

  bool _allBoxesFilled() {
    for (final row in boxes)
      for (final box in row)
        if (box.ownerIndex == null) return false;
    return true;
  }

  List<Map<String, dynamic>> getAvailableMoves() {
    final moves = <Map<String, dynamic>>[];
    for (int r = 0; r < hLines.length; r++)
      for (int c = 0; c < hLines[r].length; c++)
        if (hLines[r][c].ownerIndex == null)
          moves.add({'orientation': LineOrientation.horizontal, 'row': r, 'col': c});
    for (int r = 0; r < vLines.length; r++)
      for (int c = 0; c < vLines[r].length; c++)
        if (vLines[r][c].ownerIndex == null)
          moves.add({'orientation': LineOrientation.vertical, 'row': r, 'col': c});
    return moves;
  }

  int countSides(int r, int c) {
    int n = 0;
    if (hLines[r][c].ownerIndex != null) n++;
    if (hLines[r + 1][c].ownerIndex != null) n++;
    if (vLines[r][c].ownerIndex != null) n++;
    if (vLines[r][c + 1].ownerIndex != null) n++;
    return n;
  }

  // ── Winners ───────────────────────────────────────────────────────────────
  List<PlayerDef> get sortedPlayers {
    final sorted = List<PlayerDef>.from(players);
    sorted.sort((a, b) => b.effectiveScore.compareTo(a.effectiveScore));
    return sorted;
  }

  PlayerDef get winner => sortedPlayers.first;

  bool get isDrawGame {
    if (!gameOver) return false;
    final top = sortedPlayers.first.effectiveScore;
    return sortedPlayers.where((p) => p.effectiveScore == top).length > 1;
  }

  String get winnerName {
    if (!gameOver) return '';
    if (isDrawGame) return 'Draw';
    return winner.name;
  }

  void reset() => _initBoard();
}

class MoveResult {
  final bool success;
  final int boxesCompleted;
  MoveResult({required this.success, required this.boxesCompleted});
}
