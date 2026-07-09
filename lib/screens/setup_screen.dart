// lib/screens/setup_screen.dart
import 'package:flutter/material.dart';
import '../game/game_state.dart';
import 'game_screen.dart';

class SetupScreen extends StatefulWidget {
  final bool vsAI;
  const SetupScreen({super.key, required this.vsAI});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // Grid
  int _cols = 6, _rows = 6;

  // Players
  int _playerCount = 2;
  final List<TextEditingController> _nameCtrl = List.generate(6, (i) => TextEditingController(text: ['RED','BLUE','GREEN','YELLOW','PINK','PURPLE'][i]));
  final List<int> _colorIndex = [0, 1, 2, 3, 4, 5]; // index into PlayerColors.palette

  // AI
  int _aiDifficulty = 2;
  bool _playerGoesFirst = true;

  // Time Attack
  bool _timeAttack = false;
  int _timeSecs = 10;
  final List<int> _timeOptions = [1, 10, 15, 20, 25, 30, 40, 50];

  // Grid presets — 2 players, more players = bigger grid
  static const _gridPresets = [
    {'label': '4×4', 'cols': 4, 'rows': 4},
    {'label': '5×5', 'cols': 5, 'rows': 5},
    {'label': '6×6', 'cols': 6, 'rows': 6},
    {'label': '7×7', 'cols': 7, 'rows': 7},
    {'label': '8×8', 'cols': 8, 'rows': 8},
    {'label': '9×9', 'cols': 9, 'rows': 9},
    {'label': '10×10', 'cols': 10, 'rows': 10},
  ];

  // Auto-recommend grid size based on player count & screen
  void _autoGrid(int players, BuildContext ctx) {
    final size = MediaQuery.of(ctx).size;
    final minDim = size.width < size.height ? size.width : size.height;
    // Each cell must be at least 36px (comfortable tap target)
    final maxCells = (minDim / 36).floor();
    final recommended = [4, 5, 6, 7, 8][((players - 2)).clamp(0, 4)];
    final clamped = recommended.clamp(3, maxCells);
    setState(() { _cols = clamped; _rows = clamped; });
  }

  @override
  void dispose() {
    for (final c in _nameCtrl) c.dispose();
    super.dispose();
  }

  void _start() {
    List<PlayerDef> playerList;

    if (widget.vsAI) {
      // P0 in setup = human, P1 in setup = CPU (UI always shows human first)
      final humanName = _nameCtrl[0].text.trim().toUpperCase();
      final humanDef = PlayerDef(
        index: 0,
        name: humanName.isEmpty ? 'P1' : humanName,
        initial: (humanName.isEmpty ? 'P' : humanName.substring(0, 1)),
        color: PlayerColors.palette[_colorIndex[0]],
      );
      final cpuDef = PlayerDef(
        index: 1,
        name: 'CPU',
        initial: 'C',
        color: PlayerColors.palette[_colorIndex[1]],
      );

      // _playerGoesFirst = true  → human is index 0, CPU is index 1
      // _playerGoesFirst = false → CPU is index 0 (goes first), human is index 1
      if (_playerGoesFirst) {
        humanDef.index = 0; cpuDef.index = 1;
        playerList = [humanDef, cpuDef];
      } else {
        humanDef.index = 1; cpuDef.index = 0;
        playerList = [cpuDef, humanDef];
      }
    } else {
      // VS Friends — N players, each with their chosen name and color
      playerList = List.generate(_playerCount, (i) {
        final rawName = _nameCtrl[i].text.trim().toUpperCase();
        final name = rawName.isEmpty ? 'P${i + 1}' : rawName;
        return PlayerDef(
          index: i,
          name: name,
          initial: name.substring(0, 1),
          color: PlayerColors.palette[_colorIndex[i]],
        );
      });
    }

    final gs = GameState(
      gridCols: _cols,
      gridRows: _rows,
      mode: widget.vsAI ? GameMode.vsAI : GameMode.vsLocal,
      players: playerList,
      isTimeAttack: _timeAttack,
      timeLimitSeconds: _timeAttack ? _timeSecs : 0,
    );

    // aiPlayerIndex: which index in the final list is the CPU
    final aiIdx = widget.vsAI
        ? (_playerGoesFirst ? 1 : 0)  // human first → CPU at 1; human second → CPU at 0
        : -1;

    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => GameScreen(
          gameState: gs,
          aiDifficulty: widget.vsAI ? _aiDifficulty : 0,
          aiPlayerIndex: aiIdx,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00FFCC)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.vsAI ? 'VS COMPUTER' : 'VS FRIENDS',
          style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Player Count (vs friends only) ─────────────────────────
              if (!widget.vsAI) ...[
                _label('NUMBER OF PLAYERS'),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (i) {
                    final n = i + 2;
                    final sel = _playerCount == n;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () { setState(() => _playerCount = n); _autoGrid(n, context); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFE63946).withOpacity(0.15) : const Color(0xFF1C2F45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? const Color(0xFFE63946) : Colors.white12, width: sel ? 2 : 1),
                          ),
                          child: Column(children: [
                            Text('$n', style: TextStyle(color: sel ? const Color(0xFFE63946) : Colors.white54, fontSize: 18, fontWeight: FontWeight.w900)),
                            Text(n == 2 ? '1v1' : '$n P', style: TextStyle(color: sel ? const Color(0xFFE63946).withOpacity(0.7) : Colors.white24, fontSize: 9)),
                          ]),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
              ],

              // ── Grid Size ──────────────────────────────────────────────
              _label('GRID SIZE'),
              const SizedBox(height: 8),
              _gridSizeNote(context),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _gridPresets.map((p) {
                  final sel = _cols == p['cols'];
                  return GestureDetector(
                    onTap: () => setState(() { _cols = p['cols'] as int; _rows = p['rows'] as int; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF00FFCC).withOpacity(0.13) : const Color(0xFF1C2F45),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: sel ? const Color(0xFF00FFCC) : Colors.white12, width: sel ? 2 : 1),
                      ),
                      child: Text(p['label'] as String,
                          style: TextStyle(color: sel ? const Color(0xFF00FFCC) : Colors.white54, fontWeight: FontWeight.w800)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // ── Player Names + Color Pickers ───────────────────────────
              _label('PLAYERS'),
              const SizedBox(height: 10),
              // In VS AI mode: row 0 = human (always), row 1 = CPU (always)
              // Colors: _colorIndex[0] = human color, _colorIndex[1] = CPU color
              ...List.generate(widget.vsAI ? 2 : _playerCount, (i) {
                final isAI = widget.vsAI && i == 1; // CPU is always shown as row 1 in UI
                final label = widget.vsAI
                    ? (i == 0 ? 'YOU' : 'CPU')
                    : 'P${i + 1}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlayerRow(
                    index: i,
                    label: label,
                    controller: _nameCtrl[i],
                    colorIndex: _colorIndex[i],
                    isAI: isAI,
                    onColorChanged: (ci) => setState(() => _colorIndex[i] = ci),
                    takenColors: List.generate(widget.vsAI ? 2 : _playerCount, (j) => j == i ? -1 : _colorIndex[j]),
                  ),
                );
              }),
              const SizedBox(height: 22),

              // ── AI Options ─────────────────────────────────────────────
              if (widget.vsAI) ...[
                _label('GO FIRST OR SECOND?'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _toggle('FIRST', _playerGoesFirst, const Color(0xFF00FFCC), () => setState(() => _playerGoesFirst = true))),
                  const SizedBox(width: 10),
                  Expanded(child: _toggle('SECOND', !_playerGoesFirst, const Color(0xFFF4A261), () => setState(() => _playerGoesFirst = false))),
                ]),
                const SizedBox(height: 22),

                _label('AI DIFFICULTY'),
                const SizedBox(height: 10),
                Row(children: List.generate(3, (i) {
                  final labels = ['EASY', 'MEDIUM', 'HARD'];
                  final colors = [const Color(0xFF2DC653), const Color(0xFFFFD166), const Color(0xFFE63946)];
                  final sel = _aiDifficulty == i + 1;
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => _aiDifficulty = i + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: sel ? colors[i].withOpacity(0.15) : const Color(0xFF1C2F45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? colors[i] : Colors.white12, width: sel ? 2 : 1),
                      ),
                      child: Center(child: Text(labels[i],
                          style: TextStyle(color: sel ? colors[i] : Colors.white38, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1))),
                    ),
                  ));
                })),
                const SizedBox(height: 22),

                // ── Time Attack ────────────────────────────────────────
                _label('GAME MODE'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _toggle('FREE PLAY', !_timeAttack, const Color(0xFF457BFF), () => setState(() => _timeAttack = false))),
                  const SizedBox(width: 10),
                  Expanded(child: _toggle('TIME ATTACK ⚡', _timeAttack, const Color(0xFFFF6BB5), () => setState(() => _timeAttack = true))),
                ]),
                if (_timeAttack) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFF1C2F45), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF6BB5).withOpacity(0.4))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('SECONDS PER MOVE', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFF6BB5).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text('$_timeSecs s', style: const TextStyle(color: Color(0xFFFF6BB5), fontSize: 18, fontWeight: FontWeight.w900)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _timeOptions.map((t) {
                          final sel = _timeSecs == t;
                          return GestureDetector(
                            onTap: () => setState(() => _timeSecs = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFFFF6BB5).withOpacity(0.2) : const Color(0xFF0D1B2A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sel ? const Color(0xFFFF6BB5) : Colors.white12, width: sel ? 2 : 1),
                              ),
                              child: Text('${t}s', style: TextStyle(color: sel ? const Color(0xFFFF6BB5) : Colors.white38, fontWeight: FontWeight.w800)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '⚠ Timeout = −1 point from your score\nOpponent gains +1 bonus for your timeout',
                        style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 22),
              ],

              // ── Start ──────────────────────────────────────────────────
              GestureDetector(
                onTap: _start,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00FFCC), Color(0xFF00C9A7)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF00FFCC).withOpacity(0.25), blurRadius: 20)],
                  ),
                  child: const Center(child: Text('START GAME',
                      style: TextStyle(color: Color(0xFF0D1B2A), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3))),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2.5));

  Widget _gridSizeNote(BuildContext ctx) {
    final size = MediaQuery.of(ctx).size;
    final minDim = size.width < size.height ? size.width : size.height;
    final maxCells = (minDim / 36).floor();
    return Text(
      'Screen fits up to ${maxCells}×$maxCells comfortably',
      style: const TextStyle(color: Colors.white24, fontSize: 11),
    );
  }

  Widget _toggle(String label, bool active, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : const Color(0xFF1C2F45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? color : Colors.white12, width: active ? 2 : 1),
          ),
          child: Center(child: Text(label, style: TextStyle(color: active ? color : Colors.white38, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
        ),
      );
}

// ── Player row with name field + color picker ─────────────────────────────────
class _PlayerRow extends StatelessWidget {
  final int index;
  final String label;
  final TextEditingController controller;
  final int colorIndex;
  final bool isAI;
  final void Function(int) onColorChanged;
  final List<int> takenColors;

  const _PlayerRow({
    required this.index, required this.label, required this.controller, required this.colorIndex,
    required this.isAI, required this.onColorChanged, required this.takenColors,
  });

  @override
  Widget build(BuildContext context) {
    final color = PlayerColors.palette[colorIndex];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2F45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(width: 12),
          Expanded(
            child: isAI
                ? const Text('CPU (auto)', style: TextStyle(color: Colors.white38, fontSize: 14))
                : TextField(
                    controller: controller,
                    maxLength: 10,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Enter name', hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none, counterText: '',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
          ),
        ]),
        const SizedBox(height: 10),
        // Color palette
        Wrap(
          spacing: 7, runSpacing: 7,
          children: List.generate(PlayerColors.palette.length, (ci) {
            final taken = takenColors.contains(ci);
            final selected = colorIndex == ci;
            return GestureDetector(
              onTap: taken ? null : () => onColorChanged(ci),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: taken ? PlayerColors.palette[ci].withOpacity(0.2) : PlayerColors.palette[ci],
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: selected ? 3 : 0,
                  ),
                  boxShadow: selected ? [BoxShadow(color: PlayerColors.palette[ci].withOpacity(0.6), blurRadius: 6)] : null,
                ),
                child: taken && !selected
                    ? const Center(child: Icon(Icons.close, size: 12, color: Colors.white38))
                    : null,
              ),
            );
          }),
        ),
      ]),
    );
  }
}
