// lib/game/game_state.dart
enum Player { one, two }
enum GameMode { vsAI, vsLocal, vsOnline }
enum LineOrientation { horizontal, vertical }

class Line {
  final int row;
  final int col;
  final LineOrientation orientation;
  Player? owner;
  Line({required this.row, required this.col, required this.orientation, this.owner});
  String get id => '${orientation.name}_${row}_$col';
}

class Box {
  final int row;
  final int col;
  Player? owner;
  Box({required this.row, required this.col, this.owner});
}

// Snapshot of board state for undo/redo
class _BoardSnapshot {
  final List<List<Player?>> hOwners;
  final List<List<Player?>> vOwners;
  final List<List<Player?>> boxOwners;
  final Player currentPlayer;
  final int p1Score;
  final int p2Score;
  final bool gameOver;

  _BoardSnapshot({
    required this.hOwners,
    required this.vOwners,
    required this.boxOwners,
    required this.currentPlayer,
    required this.p1Score,
    required this.p2Score,
    required this.gameOver,
  });
}

class GameState {
  final int gridCols;
  final int gridRows;
  final GameMode mode;
  final String player1Name;
  final String player2Name;
  final String player1Initial;
  final String player2Initial;

  late List<List<Line>> hLines;
  late List<List<Line>> vLines;
  late List<List<Box>> boxes;

  Player currentPlayer = Player.one;
  bool gameOver = false;
  int player1Score = 0;
  int player2Score = 0;

  // Undo / redo stacks
  final List<_BoardSnapshot> _undoStack = [];
  final List<_BoardSnapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  GameState({
    required this.gridCols,
    required this.gridRows,
    required this.mode,
    required this.player1Name,
    required this.player2Name,
    required this.player1Initial,
    required this.player2Initial,
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
    currentPlayer = Player.one;
    gameOver = false;
    player1Score = 0;
    player2Score = 0;
    _undoStack.clear();
    _redoStack.clear();
  }

  // ── Snapshot helpers ─────────────────────────────────────────────────────
  _BoardSnapshot _snapshot() => _BoardSnapshot(
        hOwners: hLines.map((row) => row.map((l) => l.owner).toList()).toList(),
        vOwners: vLines.map((row) => row.map((l) => l.owner).toList()).toList(),
        boxOwners: boxes.map((row) => row.map((b) => b.owner).toList()).toList(),
        currentPlayer: currentPlayer,
        p1Score: player1Score,
        p2Score: player2Score,
        gameOver: gameOver,
      );

  void _restore(_BoardSnapshot s) {
    for (int r = 0; r < hLines.length; r++)
      for (int c = 0; c < hLines[r].length; c++)
        hLines[r][c].owner = s.hOwners[r][c];
    for (int r = 0; r < vLines.length; r++)
      for (int c = 0; c < vLines[r].length; c++)
        vLines[r][c].owner = s.vOwners[r][c];
    for (int r = 0; r < boxes.length; r++)
      for (int c = 0; c < boxes[r].length; c++)
        boxes[r][c].owner = s.boxOwners[r][c];
    currentPlayer = s.currentPlayer;
    player1Score = s.p1Score;
    player2Score = s.p2Score;
    gameOver = s.gameOver;
  }

  // ── Undo / Redo ───────────────────────────────────────────────────────────
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
    Line line = orientation == LineOrientation.horizontal
        ? hLines[row][col]
        : vLines[row][col];
    if (line.owner != null) return MoveResult(success: false, boxesCompleted: 0);

    // Save snapshot before mutating
    _undoStack.add(_snapshot());
    _redoStack.clear(); // new move invalidates redo history

    line.owner = currentPlayer;
    int completed = _checkBoxes(orientation, row, col);
    if (completed > 0) {
      if (currentPlayer == Player.one) player1Score += completed;
      else player2Score += completed;
    } else {
      currentPlayer = currentPlayer == Player.one ? Player.two : Player.one;
    }
    gameOver = _allBoxesFilled();
    return MoveResult(success: true, boxesCompleted: completed);
  }

  int _checkBoxes(LineOrientation orientation, int row, int col) {
    int count = 0;
    for (var bc in _getAdjacentBoxes(orientation, row, col)) {
      int br = bc[0], bc2 = bc[1];
      if (br < 0 || br >= gridRows - 1 || bc2 < 0 || bc2 >= gridCols - 1) continue;
      if (boxes[br][bc2].owner != null) continue;
      if (_isBoxComplete(br, bc2)) {
        boxes[br][bc2].owner = currentPlayer;
        count++;
      }
    }
    return count;
  }

  List<List<int>> _getAdjacentBoxes(LineOrientation orientation, int row, int col) {
    if (orientation == LineOrientation.horizontal) {
      return [[row - 1, col], [row, col]];
    } else {
      return [[row, col - 1], [row, col]];
    }
  }

  bool _isBoxComplete(int r, int c) =>
      hLines[r][c].owner != null &&
      hLines[r + 1][c].owner != null &&
      vLines[r][c].owner != null &&
      vLines[r][c + 1].owner != null;

  bool _allBoxesFilled() {
    for (var row in boxes)
      for (var box in row)
        if (box.owner == null) return false;
    return true;
  }

  List<Map<String, dynamic>> getAvailableMoves() {
    List<Map<String, dynamic>> moves = [];
    for (int r = 0; r < hLines.length; r++)
      for (int c = 0; c < hLines[r].length; c++)
        if (hLines[r][c].owner == null)
          moves.add({'orientation': LineOrientation.horizontal, 'row': r, 'col': c});
    for (int r = 0; r < vLines.length; r++)
      for (int c = 0; c < vLines[r].length; c++)
        if (vLines[r][c].owner == null)
          moves.add({'orientation': LineOrientation.vertical, 'row': r, 'col': c});
    return moves;
  }

  int countSides(int r, int c) {
    int count = 0;
    if (hLines[r][c].owner != null) count++;
    if (hLines[r + 1][c].owner != null) count++;
    if (vLines[r][c].owner != null) count++;
    if (vLines[r][c + 1].owner != null) count++;
    return count;
  }

  String get currentPlayerName =>
      currentPlayer == Player.one ? player1Name : player2Name;
  String get currentPlayerInitial =>
      currentPlayer == Player.one ? player1Initial : player2Initial;
  int get currentPlayerColorValue =>
      currentPlayer == Player.one ? 0xFFE63946 : 0xFF457BFF;

  String get winnerName {
    if (!gameOver) return '';
    if (player1Score > player2Score) return player1Name;
    if (player2Score > player1Score) return player2Name;
    return 'Draw';
  }

  bool get isDrawGame => gameOver && player1Score == player2Score;
  void reset() => _initBoard();
}

class MoveResult {
  final bool success;
  final int boxesCompleted;
  MoveResult({required this.success, required this.boxesCompleted});
}
