// lib/widgets/game_board.dart — N-player version
import 'package:flutter/material.dart';
import '../game/game_state.dart';

class GameBoard extends StatelessWidget {
  final GameState gameState;
  final void Function(LineOrientation, int, int) onLineTapped;
  final bool aiThinking;

  const GameBoard({
    super.key,
    required this.gameState,
    required this.onLineTapped,
    this.aiThinking = false,
  });

  Color _playerColor(int? idx) {
    if (idx == null) return Colors.transparent;
    return gameState.players[idx].color;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final gs = gameState;
      final cols = gs.gridCols;
      final rows = gs.gridRows;

      // Compute cell size — square cells, fit within available space
      // Also enforce minimum 30px per cell for tapability
      final rawCellW = constraints.maxWidth / (cols - 1);
      final rawCellH = constraints.maxHeight / (rows - 1);
      final cellSize = (rawCellW < rawCellH ? rawCellW : rawCellH).clamp(30.0, double.infinity);

      final boardW = cellSize * (cols - 1);
      final boardH = cellSize * (rows - 1);

      final dotR   = (cellSize * 0.09).clamp(4.0, 9.0);
      final thick  = (cellSize * 0.07).clamp(3.5, 8.0);
      final hitA   = (cellSize * 0.55).clamp(22.0, double.infinity); // generous hit zone

      return Center(
        child: SizedBox(
          width: boardW, height: boardH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ..._fills(gs, cellSize),
              ..._hLines(gs, cellSize, thick),
              ..._vLines(gs, cellSize, thick),
              ..._hHits(gs, cellSize, hitA),
              ..._vHits(gs, cellSize, hitA),
              ..._dots(gs, cellSize, dotR),
              ..._initials(gs, cellSize),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _fills(GameState gs, double cs) {
    final out = <Widget>[];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final box = gs.boxes[r][c];
        if (box.ownerIndex == null) continue;
        final color = _playerColor(box.ownerIndex).withOpacity(0.22);
        out.add(Positioned(
          left: c * cs, top: r * cs, width: cs, height: cs,
          child: Container(color: color),
        ));
      }
    }
    return out;
  }

  List<Widget> _hLines(GameState gs, double cs, double thick) {
    final out = <Widget>[];
    for (int r = 0; r < gs.gridRows; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final line = gs.hLines[r][c];
        final color = line.ownerIndex == null
            ? const Color(0x18FFFFFF)
            : _playerColor(line.ownerIndex);
        out.add(Positioned(
          left: c * cs, top: r * cs - thick / 2,
          width: cs, height: thick,
          child: Container(
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(thick / 2)),
          ),
        ));
      }
    }
    return out;
  }

  List<Widget> _vLines(GameState gs, double cs, double thick) {
    final out = <Widget>[];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols; c++) {
        final line = gs.vLines[r][c];
        final color = line.ownerIndex == null
            ? const Color(0x18FFFFFF)
            : _playerColor(line.ownerIndex);
        out.add(Positioned(
          left: c * cs - thick / 2, top: r * cs,
          width: thick, height: cs,
          child: Container(
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(thick / 2)),
          ),
        ));
      }
    }
    return out;
  }

  List<Widget> _hHits(GameState gs, double cs, double hitA) {
    final out = <Widget>[];
    for (int r = 0; r < gs.gridRows; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        if (gs.hLines[r][c].ownerIndex != null) continue;
        out.add(Positioned(
          left: c * cs, top: r * cs - hitA / 2,
          width: cs, height: hitA,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: aiThinking ? null : () => onLineTapped(LineOrientation.horizontal, r, c),
            child: Container(color: Colors.transparent),
          ),
        ));
      }
    }
    return out;
  }

  List<Widget> _vHits(GameState gs, double cs, double hitA) {
    final out = <Widget>[];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols; c++) {
        if (gs.vLines[r][c].ownerIndex != null) continue;
        out.add(Positioned(
          left: c * cs - hitA / 2, top: r * cs,
          width: hitA, height: cs,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: aiThinking ? null : () => onLineTapped(LineOrientation.vertical, r, c),
            child: Container(color: Colors.transparent),
          ),
        ));
      }
    }
    return out;
  }

  List<Widget> _dots(GameState gs, double cs, double dotR) {
    final out = <Widget>[];
    for (int r = 0; r < gs.gridRows; r++) {
      for (int c = 0; c < gs.gridCols; c++) {
        out.add(Positioned(
          left: c * cs - dotR, top: r * cs - dotR,
          width: dotR * 2, height: dotR * 2,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD0E4FF),
              boxShadow: [BoxShadow(color: Color(0x4400FFCC), blurRadius: 5)],
            ),
          ),
        ));
      }
    }
    return out;
  }

  List<Widget> _initials(GameState gs, double cs) {
    final out = <Widget>[];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final box = gs.boxes[r][c];
        if (box.ownerIndex == null) continue;
        final p = gs.players[box.ownerIndex!];
        final fontSize = (cs * 0.36).clamp(9.0, 26.0);
        out.add(Positioned(
          left: c * cs, top: r * cs, width: cs, height: cs,
          child: Center(
            child: Text(p.initial,
                style: TextStyle(color: p.color.withOpacity(0.9), fontSize: fontSize, fontWeight: FontWeight.w900)),
          ),
        ));
      }
    }
    return out;
  }
}
