// lib/screens/game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../ai/ai_engine.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;
  final int aiDifficulty; // 0 = human vs human

  const GameScreen({super.key, required this.gameState, required this.aiDifficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late AIEngine? _ai;
  bool _aiThinking = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _lastBoxesCompleted = 0;

  @override
  void initState() {
    super.initState();
    _ai = widget.aiDifficulty > 0
        ? AIEngine(difficulty: widget.aiDifficulty)
        : null;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Trigger AI first move if AI is player 1 (shouldn't normally happen)
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAIMove());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onLineTapped(LineOrientation orientation, int row, int col) {
    if (_aiThinking) return;
    if (widget.gameState.gameOver) return;
    // If it's AI's turn (player two), ignore human taps
    if (_ai != null && widget.gameState.currentPlayer == Player.two) return;

    final result = widget.gameState.drawLine(orientation, row, col);
    if (!result.success) return;

    setState(() {
      _lastBoxesCompleted = result.boxesCompleted;
    });

    if (widget.gameState.gameOver) {
      _showGameOver();
      return;
    }
    _maybeAIMove();
  }

  void _maybeAIMove() {
    if (_ai == null) return;
    if (widget.gameState.currentPlayer != Player.two) return;
    if (widget.gameState.gameOver) return;

    setState(() => _aiThinking = true);

    // Small delay so the human can see the board update
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final move = _ai!.getBestMove(widget.gameState);
      if (move != null) {
        final result = widget.gameState.drawLine(
          move['orientation'] as LineOrientation,
          move['row'] as int,
          move['col'] as int,
        );
        setState(() {
          _aiThinking = false;
          _lastBoxesCompleted = result.boxesCompleted;
        });
        if (widget.gameState.gameOver) {
          _showGameOver();
        } else {
          // If AI completed a box it gets another turn — recurse
          if (widget.gameState.currentPlayer == Player.two) {
            _maybeAIMove();
          }
        }
      } else {
        setState(() => _aiThinking = false);
      }
    });
  }

  void _showGameOver() {
    final gs = widget.gameState;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1C2F45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GAME OVER', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              if (gs.isDrawGame) ...[
                const Text('🤝', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text("IT'S A DRAW!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ] else ...[
                const Text('🏆', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  '${gs.winnerName} WINS!',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScorePill(name: gs.player1Name, score: gs.player1Score, color: const Color(0xFFE63946)),
                  _ScorePill(name: gs.player2Name, score: gs.player2Score, color: const Color(0xFF457BFF)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DialogBtn(
                      label: 'REMATCH',
                      color: const Color(0xFF00FFCC),
                      onTap: () {
                        widget.gameState.reset();
                        Navigator.pop(context);
                        setState(() {});
                        _maybeAIMove();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogBtn(
                      label: 'MENU',
                      color: Colors.white24,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gameState;
    final isP1Turn = gs.currentPlayer == Player.one;
    final p1Color = const Color(0xFFE63946);
    final p2Color = const Color(0xFF457BFF);
    final currentColor = isP1Turn ? p1Color : p2Color;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white38, size: 18),
                    onPressed: () => _confirmExit(),
                  ),
                  const Spacer(),
                  Text(
                    '${gs.gridCols - 1}×${gs.gridRows - 1} GRID',
                    style: const TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 2),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white38, size: 18),
                    onPressed: () {
                      gs.reset();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            // Score bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _PlayerScoreCard(
                    name: gs.player1Name,
                    score: gs.player1Score,
                    color: p1Color,
                    isActive: isP1Turn && !gs.gameOver,
                    pulseAnim: _pulseAnim,
                  ),
                  Expanded(
                    child: Center(
                      child: _aiThinking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF457BFF),
                              ),
                            )
                          : AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Opacity(
                                opacity: _pulseAnim.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: currentColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: currentColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    gs.gameOver ? 'DONE' : 'YOUR TURN',
                                    style: TextStyle(
                                      color: currentColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  _PlayerScoreCard(
                    name: gs.player2Name,
                    score: gs.player2Score,
                    color: p2Color,
                    isActive: !isP1Turn && !gs.gameOver,
                    pulseAnim: _pulseAnim,
                    alignRight: true,
                  ),
                ],
              ),
            ),

            // Board
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GameBoard(
                  gameState: gs,
                  onLineTapped: _onLineTapped,
                  aiThinking: _aiThinking,
                ),
              ),
            ),

            // Turn hint
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                gs.gameOver
                    ? ''
                    : _aiThinking
                        ? 'CPU is thinking...'
                        : _lastBoxesCompleted > 0
                            ? '${gs.currentPlayerName} gets another turn! (+$_lastBoxesCompleted box${_lastBoxesCompleted > 1 ? 'es' : ''})'
                            : '${gs.currentPlayerName} — tap a line to draw',
                style: TextStyle(
                  color: gs.currentPlayerColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1C2F45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('QUIT GAME?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _DialogBtn(label: 'STAY', color: const Color(0xFF00FFCC), onTap: () => Navigator.pop(context))),
                  const SizedBox(width: 12),
                  Expanded(child: _DialogBtn(label: 'QUIT', color: const Color(0xFFE63946), onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  })),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerScoreCard extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  final bool isActive;
  final Animation<double> pulseAnim;
  final bool alignRight;

  const _PlayerScoreCard({
    required this.name,
    required this.score,
    required this.color,
    required this.isActive,
    required this.pulseAnim,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : const Color(0xFF1C2F45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color.withOpacity(0.5 * pulseAnim.value + 0.3) : Colors.white12,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            Text(
              '$score',
              style: TextStyle(color: isActive ? color : Colors.white54, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String name;
  final int score;
  final Color color;

  const _ScorePill({required this.name, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        Text('$score boxes', style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ),
      ),
    );
  }
}
