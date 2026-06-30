// lib/game/game_state.dart
// Core Dots and Boxes game engine for NOCTIS iTRADE Dots & Boxes
// Supports 2 player local, vs AI, and multiplayer (Bluetooth/Hotspot hook-in ready)

enum Player { one, two }
enum GameMode { vsAI, vsLocal, vsOnline }
enum LineOrientation { horizontal, vertical }

class Line {
  final int row;
  final int col;
  final LineOrientation orientation;
  Player? owner; // null = not drawn yet

  Line({required this.row, required this.col, required this.orientation, this.owner});

  String get id => '${orientation.name}_${row}_$col';
}

class Box {
  final int row;
  final int col;
  Player? owner; // null = not completed yet

  Box({required this.row, required this.col, this.owner});
}

class GameState {
  final int gridCols; // number of dots per row
  final int gridRows; // number of dots per col
  final GameMode mode;
  final String player1Name;
  final String player2Name;
  final String player1Initial;
  final String player2Initial;

  late List<List<Line>> hLines; // horizontal lines: [gridRows-1+1][gridCols-1] → (rows) x (cols-1)
  late List<List<Line>> vLines; // vertical lines:   [gridRows-1][gridCols-1+1]
  late List<List<Box>> boxes;

  Player currentPlayer = Player.one;
  bool gameOver = false;
  int player1Score = 0;
  int player2Score = 0;

  // hLines[r][c] = line between dot(r,c) and dot(r,c+1)
  // vLines[r][c] = line between dot(r,c) and dot(r+1,c)
  // boxes[r][c]  = box with top-left corner at dot(r,c)

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
    // Horizontal lines: gridRows rows of (gridCols-1) lines
    hLines = List.generate(
      gridRows,
      (r) => List.generate(
        gridCols - 1,
        (c) => Line(row: r, col: c, orientation: LineOrientation.horizontal),
      ),
    );
    // Vertical lines: (gridRows-1) rows of gridCols lines
    vLines = List.generate(
      gridRows - 1,
      (r) => List.generate(
        gridCols,
        (c) => Line(row: r, col: c, orientation: LineOrientation.vertical),
      ),
    );
    // Boxes: (gridRows-1) x (gridCols-1)
    boxes = List.generate(
      gridRows - 1,
      (r) => List.generate(
        gridCols - 1,
        (c) => Box(row: r, col: c),
      ),
    );
    currentPlayer = Player.one;
    gameOver = false;
    player1Score = 0;
    player2Score = 0;
  }

  // Returns true if the line was drawn (not already taken)
  // Returns number of boxes completed (0 or more)
  MoveResult drawLine(LineOrientation orientation, int row, int col) {
    Line line;
    if (orientation == LineOrientation.horizontal) {
      line = hLines[row][col];
    } else {
      line = vLines[row][col];
    }
    if (line.owner != null) return MoveResult(success: false, boxesCompleted: 0);

    line.owner = currentPlayer;

    int completed = _checkBoxes(orientation, row, col);
    if (completed > 0) {
      if (currentPlayer == Player.one) {
        player1Score += completed;
      } else {
        player2Score += completed;
      }
      // Player gets bonus turn — do NOT switch player
    } else {
      // Switch turn
      currentPlayer = currentPlayer == Player.one ? Player.two : Player.one;
    }

    // Check game over
    gameOver = _allBoxesFilled();
    return MoveResult(success: true, boxesCompleted: completed);
  }

  int _checkBoxes(LineOrientation orientation, int row, int col) {
    int count = 0;
    // Each line can be part of at most 2 boxes
    List<List<int>> candidateBoxes = _getAdjacentBoxes(orientation, row, col);
    for (var bc in candidateBoxes) {
      int br = bc[0];
      int bc2 = bc[1];
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
      // Top box: (row-1, col), bottom box: (row, col)
      return [
        [row - 1, col],
        [row, col],
      ];
    } else {
      // Left box: (row, col-1), right box: (row, col)
      return [
        [row, col - 1],
        [row, col],
      ];
    }
  }

  bool _isBoxComplete(int r, int c) {
    // top h, bottom h, left v, right v
    bool top    = hLines[r][c].owner != null;
    bool bottom = hLines[r + 1][c].owner != null;
    bool left   = vLines[r][c].owner != null;
    bool right  = vLines[r][c + 1].owner != null;
    return top && bottom && left && right;
  }

  bool _allBoxesFilled() {
    for (var row in boxes) {
      for (var box in row) {
        if (box.owner == null) return false;
      }
    }
    return true;
  }

  // For AI: get all undrawn lines
  List<Map<String, dynamic>> getAvailableMoves() {
    List<Map<String, dynamic>> moves = [];
    for (int r = 0; r < hLines.length; r++) {
      for (int c = 0; c < hLines[r].length; c++) {
        if (hLines[r][c].owner == null) {
          moves.add({'orientation': LineOrientation.horizontal, 'row': r, 'col': c});
        }
      }
    }
    for (int r = 0; r < vLines.length; r++) {
      for (int c = 0; c < vLines[r].length; c++) {
        if (vLines[r][c].owner == null) {
          moves.add({'orientation': LineOrientation.vertical, 'row': r, 'col': c});
        }
      }
    }
    return moves;
  }

  // Count how many sides a box has drawn
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

  Color get currentPlayerColor =>
      currentPlayer == Player.one ? const Color(0xFFE63946) : const Color(0xFF457BFF);

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
