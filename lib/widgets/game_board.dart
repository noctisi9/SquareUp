// lib/widgets/game_board.dart
import 'package:flutter/material.dart';
import '../game/game_state.dart';

class GameBoard extends StatelessWidget {
  final GameState gameState;
  final void Function(LineOrientation, int, int) onLineTapped;
  final bool aiThinking;
  const GameBoard({super.key, required this.gameState, required this.onLineTapped, this.aiThinking = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final gs = gameState;
      final cols = gs.gridCols;
      final rows = gs.gridRows;
      final cellW = constraints.maxWidth / (cols - 1);
      final cellH = constraints.maxHeight / (rows - 1);
      final cellSize = cellW < cellH ? cellW : cellH;
      final boardW = cellSize * (cols - 1);
      final boardH = cellSize * (rows - 1);
      final dotR = (cellSize * 0.08).clamp(4.5, 9.0);
      final lineThick = (cellSize * 0.07).clamp(3.5, 8.0);
      // ↑ Sensitivity: hit zone is 55% of cell — much easier to tap
      final hitArea = cellSize * 0.55;

      return Center(
        child: SizedBox(
          width: boardW, height: boardH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ..._buildBoxFills(gs, cellSize),
              ..._buildLines(gs, cellSize, lineThick),
              ..._buildHTapZones(gs, cellSize, hitArea),
              ..._buildVTapZones(gs, cellSize, hitArea),
              ..._buildDots(gs, cellSize, dotR),
              ..._buildInitials(gs, cellSize),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildBoxFills(GameState gs, double cs) {
    final List<Widget> out = [];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final box = gs.boxes[r][c];
        if (box.owner == null) continue;
        final color = box.owner == Player.one
            ? const Color(0xFFE63946).withOpacity(0.2)
            : const Color(0xFF457BFF).withOpacity(0.2);
        out.add(Positioned(left: c * cs, top: r * cs, width: cs, height: cs,
            child: Container(color: color)));
      }
    }
    return out;
  }

  List<Widget> _buildLines(GameState gs, double cs, double thick) {
    final List<Widget> out = [];
    const p1 = Color(0xFFE63946);
    const p2 = Color(0xFF457BFF);
    const ghost = Color(0x18FFFFFF);

    // Horizontal
    for (int r = 0; r < gs.gridRows; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final line = gs.hLines[r][c];
        final color = line.owner == null ? ghost : (line.owner == Player.one ? p1 : p2);
        out.add(Positioned(
          left: c * cs, top: r * cs - thick / 2,
          width: cs, height: thick,
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(thick / 2))),
        ));
      }
    }
    // Vertical
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols; c++) {
        final line = gs.vLines[r][c];
        final color = line.owner == null ? ghost : (line.owner == Player.one ? p1 : p2);
        out.add(Positioned(
          left: c * cs - thick / 2, top: r * cs,
          width: thick, height: cs,
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(thick / 2))),
        ));
      }
    }
    return out;
  }

  List<Widget> _buildHTapZones(GameState gs, double cs, double hitArea) {
    final List<Widget> out = [];
    for (int r = 0; r < gs.gridRows; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        if (gs.hLines[r][c].owner != null) continue;
        out.add(Positioned(
          left: c * cs, top: r * cs - hitArea / 2,
          width: cs, height: hitArea,
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

  List<Widget> _buildVTapZones(GameState gs, double cs, double hitArea) {
    final List<Widget> out = [];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols; c++) {
        if (gs.vLines[r][c].owner != null) continue;
        out.add(Positioned(
          left: c * cs - hitArea / 2, top: r * cs,
          width: hitArea, height: cs,
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

  List<Widget> _buildDots(GameState gs, double cs, double dotR) {
    final List<Widget> out = [];
    for (int r = 0; r < gs.gridRows; r++) {
      for (int c = 0; c < gs.gridCols; c++) {
        out.add(Positioned(
          left: c * cs - dotR, top: r * cs - dotR,
          width: dotR * 2, height: dotR * 2,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD0E4FF),
              boxShadow: [BoxShadow(color: Color(0x4D00FFCC), blurRadius: 4, spreadRadius: 0.5)],
            ),
          ),
        ));
      }
    }
    return out;
  }

  List<Widget> _buildInitials(GameState gs, double cs) {
    final List<Widget> out = [];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final box = gs.boxes[r][c];
        if (box.owner == null) continue;
        final initial = box.owner == Player.one ? gs.player1Initial : gs.player2Initial;
        final color = box.owner == Player.one ? const Color(0xFFE63946) : const Color(0xFF457BFF);
        final fontSize = (cs * 0.38).clamp(10.0, 28.0);
        out.add(Positioned(
          left: c * cs, top: r * cs, width: cs, height: cs,
          child: Center(
            child: Text(initial, style: TextStyle(color: color.withOpacity(0.85), fontSize: fontSize, fontWeight: FontWeight.w900)),
          ),
        ));
      }
    }
    return out;
  }
}
