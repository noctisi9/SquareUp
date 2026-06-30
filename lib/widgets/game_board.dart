// lib/widgets/game_board.dart
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gs = gameState;
        final cols = gs.gridCols; // dots per row
        final rows = gs.gridRows; // dots per col
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        final cellW = maxW / (cols - 1);
        final cellH = maxH / (rows - 1);
        final cellSize = cellW < cellH ? cellW : cellH; // square cells

        final boardW = cellSize * (cols - 1);
        final boardH = cellSize * (rows - 1);

        final dotRadius = (cellSize * 0.07).clamp(4.0, 8.0);
        final lineThick = (cellSize * 0.06).clamp(3.0, 7.0);
        final hitArea = cellSize * 0.35; // tap zone around line

        return Center(
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Boxes (filled squares)
                ..._buildBoxes(gs, cellSize, boardH),
                // Lines (drawn)
                ..._buildLines(gs, cellSize, boardH, lineThick),
                // Tap zones for horizontal lines
                ..._buildHTapZones(gs, cellSize, boardH, hitArea),
                // Tap zones for vertical lines
                ..._buildVTapZones(gs, cellSize, boardH, hitArea),
                // Dots (drawn on top)
                ..._buildDots(gs, cellSize, boardH, dotRadius),
                // Box initials
                ..._buildBoxInitials(gs, cellSize, boardH),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildBoxes(GameState gs, double cs, double boardH) {
    final List<Widget> widgets = [];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final box = gs.boxes[r][c];
        if (box.owner == null) continue;
        final color = box.owner == Player.one
            ? const Color(0xFFE63946).withOpacity(0.18)
            : const Color(0xFF457BFF).withOpacity(0.18);
        final x = c * cs;
        final y = r * cs;
        widgets.add(Positioned(
          left: x,
          top: y,
          width: cs,
          height: cs,
          child: Container(color: color),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildLines(GameState gs, double cs, double boardH, double thick) {
    final List<Widget> widgets = [];
    final p1Color = const Color(0xFFE63946);
    final p2Color = const Color(0xFF457BFF);
    final ghostColor = Colors.white10;

    // Horizontal lines
    for (int r = 0; r < gs.gridRows; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final line = gs.hLines[r][c];
        final color = line.owner == null
            ? ghostColor
            : (line.owner == Player.one ? p1Color : p2Color);
        final x = c * cs;
        final y = r * cs;
        widgets.add(Positioned(
          left: x,
          top: y - thick / 2,
          width: cs,
          height: thick,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(thick / 2),
            ),
          ),
        ));
      }
    }

    // Vertical lines
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols; c++) {
        final line = gs.vLines[r][c];
        final color = line.owner == null
            ? ghostColor
            : (line.owner == Player.one ? p1Color : p2Color);
        final x = c * cs;
        final y = r * cs;
        widgets.add(Positioned(
          left: x - thick / 2,
          top: y,
          width: thick,
          height: cs,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(thick / 2),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildHTapZones(GameState gs, double cs, double boardH, double hitArea) {
    final List<Widget> widgets = [];
    for (int r = 0; r < gs.gridRows; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final line = gs.hLines[r][c];
        if (line.owner != null) continue; // already drawn
        final x = c * cs;
        final y = r * cs;
        widgets.add(Positioned(
          left: x,
          top: y - hitArea / 2,
          width: cs,
          height: hitArea,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: aiThinking ? null : () => onLineTapped(LineOrientation.horizontal, r, c),
            child: MouseRegion(
              cursor: aiThinking ? SystemMouseCursors.basic : SystemMouseCursors.click,
              child: Container(color: Colors.transparent),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildVTapZones(GameState gs, double cs, double boardH, double hitArea) {
    final List<Widget> widgets = [];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols; c++) {
        final line = gs.vLines[r][c];
        if (line.owner != null) continue;
        final x = c * cs;
        final y = r * cs;
        widgets.add(Positioned(
          left: x - hitArea / 2,
          top: y,
          width: hitArea,
          height: cs,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: aiThinking ? null : () => onLineTapped(LineOrientation.vertical, r, c),
            child: MouseRegion(
              cursor: aiThinking ? SystemMouseCursors.basic : SystemMouseCursors.click,
              child: Container(color: Colors.transparent),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildDots(GameState gs, double cs, double boardH, double dotR) {
    final List<Widget> widgets = [];
    for (int r = 0; r < gs.gridRows; r++) {
      for (int c = 0; c < gs.gridCols; c++) {
        widgets.add(Positioned(
          left: c * cs - dotR,
          top: r * cs - dotR,
          width: dotR * 2,
          height: dotR * 2,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD0E4FF),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFCC).withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildBoxInitials(GameState gs, double cs, double boardH) {
    final List<Widget> widgets = [];
    for (int r = 0; r < gs.gridRows - 1; r++) {
      for (int c = 0; c < gs.gridCols - 1; c++) {
        final box = gs.boxes[r][c];
        if (box.owner == null) continue;
        final initial = box.owner == Player.one
            ? gs.player1Initial
            : gs.player2Initial;
        final color = box.owner == Player.one
            ? const Color(0xFFE63946)
            : const Color(0xFF457BFF);
        final fontSize = (cs * 0.38).clamp(10.0, 28.0);
        widgets.add(Positioned(
          left: c * cs,
          top: r * cs,
          width: cs,
          height: cs,
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: color.withOpacity(0.85),
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }
}
