// lib/screens/game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../ai/ai_engine.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;
  final int aiDifficulty;   // 0 = human vs human
  final int aiPlayerIndex;  // which player index is AI (-1 = none)

  const GameScreen({
    super.key,
    required this.gameState,
    required this.aiDifficulty,
    required this.aiPlayerIndex,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AIEngine? _ai;
  bool _aiThinking = false;
  int _lastBoxes = 0;

  // Pulse animation for active player indicator
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Timer countdown
  late AnimationController _timerCtrl;
  Timer? _countdownTimer;
  int _secsLeft = 0;
  bool _timerRunning = false;

  GameState get gs => widget.gameState;
  bool get isTimeAttack => gs.isTimeAttack;
  bool get isAITurn => widget.aiPlayerIndex >= 0 && gs.currentIndex == widget.aiPlayerIndex;

  @override
  void initState() {
    super.initState();
    _ai = widget.aiDifficulty > 0 ? AIEngine(difficulty: widget.aiDifficulty) : null;

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _timerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTurn();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timerCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Turn management ───────────────────────────────────────────────────────
  void _startTurn() {
    if (!mounted || gs.gameOver) return;
    _countdownTimer?.cancel();
    setState(() => _lastBoxes = 0);

    if (isTimeAttack && !isAITurn) {
      _secsLeft = gs.timeLimitSeconds;
      _timerRunning = true;
      _timerCtrl.forward(from: 0);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _secsLeft--);
        if (_secsLeft <= 0) {
          t.cancel();
          _onTimeout();
        }
      });
    }

    if (isAITurn) _scheduleAI();
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    _timerRunning = false;
  }

  void _onTimeout() {
    if (gs.gameOver) return;
    _stopTimer();
    // Penalty: -1 to current player, next player gets +1
    final penalisedName = gs.currentPlayerName;
    gs.applyTimeoutPenalty();
    setState(() {});
    // Show brief snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⏱ $penalisedName timed out! −1 point'),
        backgroundColor: const Color(0xFFE63946),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
    if (gs.gameOver) { _showGameOver(); return; }
    _startTurn();
  }

  // ── Human tap ────────────────────────────────────────────────────────────
  void _onLineTapped(LineOrientation orientation, int row, int col) {
    if (_aiThinking || gs.gameOver) return;
    if (isAITurn) return;

    _stopTimer();
    final result = gs.drawLine(orientation, row, col);
    if (!result.success) { if (isTimeAttack && !isAITurn) _startTurn(); return; }

    setState(() => _lastBoxes = result.boxesCompleted);
    if (gs.gameOver) { _showGameOver(); return; }
    _startTurn();
  }

  // ── Undo / Redo ───────────────────────────────────────────────────────────
  void _undo() {
    if (_aiThinking) return;
    _stopTimer();
    bool did = gs.undo();
    // If vs AI and now it's AI turn, undo one more
    if (did && _ai != null && gs.currentIndex == widget.aiPlayerIndex) gs.undo();
    setState(() => _lastBoxes = 0);
    _startTurn();
  }

  void _redo() {
    if (_aiThinking) return;
    _stopTimer();
    gs.redo();
    setState(() => _lastBoxes = 0);
    _startTurn();
  }

  // ── AI move ──────────────────────────────────────────────────────────────
  void _scheduleAI() {
    if (!mounted || !isAITurn || gs.gameOver) return;
    setState(() => _aiThinking = true);
    Future.delayed(const Duration(milliseconds: 580), () {
      if (!mounted) return;
      final move = _ai!.getBestMove(gs);
      if (move != null) {
        final result = gs.drawLine(
          move['orientation'] as LineOrientation,
          move['row'] as int, move['col'] as int,
        );
        setState(() { _aiThinking = false; _lastBoxes = result.boxesCompleted; });
        if (gs.gameOver) { _showGameOver(); return; }
        _startTurn();
      } else {
        setState(() => _aiThinking = false);
      }
    });
  }

  // ── Game over dialog ──────────────────────────────────────────────────────
  void _showGameOver() {
    _stopTimer();
    final sorted = gs.sortedPlayers;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1C2F45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('GAME OVER', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text(gs.isDrawGame ? "🤝 IT'S A DRAW!" : '🏆 ${gs.winnerName} WINS!',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            // Scoreboard
            ...sorted.asMap().entries.map((e) {
              final rank = e.key;
              final p = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: rank == 0 ? p.color.withOpacity(0.15) : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: rank == 0 ? p.color.withOpacity(0.5) : Colors.white12),
                ),
                child: Row(children: [
                  Text(rank == 0 ? '🥇' : rank == 1 ? '🥈' : rank == 2 ? '🥉' : '  ', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: p.color)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.name, style: TextStyle(color: p.color, fontWeight: FontWeight.w800))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${p.effectiveScore} pts', style: TextStyle(color: p.color, fontSize: 15, fontWeight: FontWeight.w900)),
                    if (gs.isTimeAttack && p.penaltyPoints > 0)
                      Text('${p.score} boxes −${p.penaltyPoints} penalty',
                          style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ]),
                ]),
              );
            }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _dialogBtn('REMATCH', const Color(0xFF00FFCC), () {
                gs.reset();
                Navigator.of(context).pop();
                setState(() => _lastBoxes = 0);
                _startTurn();
              })),
              const SizedBox(width: 12),
              Expanded(child: _dialogBtn('HOME', Colors.white24, () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((r) => r.isFirst);
              })),
            ]),
          ]),
        ),
      ),
    );
  }

  void _confirmExit() {
    _stopTimer();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1C2F45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('QUIT GAME?', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _dialogBtn('STAY', const Color(0xFF00FFCC), () {
                Navigator.of(context).pop();
                if (isTimeAttack && !isAITurn) _startTurn();
              })),
              const SizedBox(width: 12),
              Expanded(child: _dialogBtn('QUIT', const Color(0xFFE63946), () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((r) => r.isFirst);
              })),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cp = gs.currentPlayer;
    final cpColor = cp.color;

    return WillPopScope(
      onWillPop: () async { _confirmExit(); return false; },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: SafeArea(
          child: Column(children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white38, size: 18),
                  onPressed: _confirmExit,
                ),
                Text('${gs.gridCols - 1}×${gs.gridRows - 1}',
                    style: const TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 2)),
                if (isTimeAttack) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6BB5).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFF6BB5).withOpacity(0.5)),
                    ),
                    child: const Text('⚡ TIME ATTACK',
                        style: TextStyle(color: Color(0xFFFF6BB5), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.undo_rounded,
                      color: gs.canUndo && !_aiThinking ? const Color(0xFF00FFCC) : Colors.white12,
                      size: 22),
                  onPressed: gs.canUndo && !_aiThinking ? _undo : null,
                ),
                IconButton(
                  icon: Icon(Icons.redo_rounded,
                      color: gs.canRedo && !_aiThinking ? const Color(0xFFF4A261) : Colors.white12,
                      size: 22),
                  onPressed: gs.canRedo && !_aiThinking ? _redo : null,
                ),
              ]),
            ),

            // ── Timer bar (Time Attack only) ─────────────────────────────
            if (isTimeAttack && !gs.gameOver && _timerRunning)
              _TimerBar(secsLeft: _secsLeft, total: gs.timeLimitSeconds, color: cpColor),

            // ── Score strip (all players) ────────────────────────────────
            SizedBox(
              height: 68,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: gs.players.length,
                itemBuilder: (_, i) {
                  final p = gs.players[i];
                  final active = gs.currentIndex == i && !gs.gameOver;
                  return AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? p.color.withOpacity(0.15) : const Color(0xFF1C2F45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? p.color.withOpacity(0.4 + 0.3 * _pulseAnim.value) : Colors.white12,
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: p.color)),
                            const SizedBox(width: 5),
                            Text(p.name, style: TextStyle(color: p.color, fontSize: 10, fontWeight: FontWeight.w800)),
                          ]),
                          Text('${p.effectiveScore}',
                              style: TextStyle(color: active ? p.color : Colors.white54, fontSize: 20, fontWeight: FontWeight.w900, height: 1.1)),
                          if (gs.isTimeAttack && p.penaltyPoints > 0)
                            Text('−${p.penaltyPoints}', style: const TextStyle(color: Color(0xFFE63946), fontSize: 9, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Board ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: GameBoard(
                  gameState: gs,
                  onLineTapped: _onLineTapped,
                  aiThinking: _aiThinking,
                ),
              ),
            ),

            // ── Bottom hint ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 2),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey('$_aiThinking${gs.currentIndex}$_lastBoxes'),
                  gs.gameOver ? '' :
                  _aiThinking ? 'CPU is thinking...' :
                  isTimeAttack && _timerRunning ? '$_secsLeft s — ${gs.currentPlayerName}\'s move' :
                  _lastBoxes > 0 ? '${gs.currentPlayerName} gets another turn! +$_lastBoxes' :
                  '${gs.currentPlayerName} — tap a line',
                  style: TextStyle(color: cpColor.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _dialogBtn(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Center(child: Text(label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5))),
        ),
      );
}

// ── Timer bar widget ──────────────────────────────────────────────────────────
class _TimerBar extends StatelessWidget {
  final int secsLeft, total;
  final Color color;
  const _TimerBar({required this.secsLeft, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (secsLeft / total).clamp(0.0, 1.0) : 0.0;
    final barColor = ratio > 0.5 ? const Color(0xFF00FFCC) :
                     ratio > 0.25 ? const Color(0xFFFFD166) :
                     const Color(0xFFE63946);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('⏱ $secsLeft s', style: TextStyle(color: barColor, fontSize: 13, fontWeight: FontWeight.w900)),
          Text('/ $total s', style: const TextStyle(color: Colors.white24, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }
}
