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
  int selectedCols = 6;
  int selectedRows = 6;
  int aiDifficulty = 2;
  final p1Controller = TextEditingController(text: 'RED');
  final p2Controller = TextEditingController(text: 'BLUE');

  final List<Map<String, dynamic>> gridPresets = [
    {'label': '3×3', 'cols': 3, 'rows': 3, 'desc': 'Quick game'},
    {'label': '5×5', 'cols': 5, 'rows': 5, 'desc': 'Standard'},
    {'label': '7×7', 'cols': 7, 'rows': 7, 'desc': 'Classic'},
    {'label': '9×9', 'cols': 9, 'rows': 9, 'desc': 'Long game'},
    {'label': '10×10', 'cols': 10, 'rows': 10, 'desc': 'Epic'},
  ];

  final diffLabels = ['Easy', 'Medium', 'Hard'];
  final diffIcons = [Icons.sentiment_satisfied, Icons.sentiment_neutral, Icons.sentiment_very_dissatisfied];
  final diffColors = [Color(0xFF00FFCC), Color(0xFFF4A261), Color(0xFFE63946)];

  @override
  void dispose() {
    p1Controller.dispose();
    p2Controller.dispose();
    super.dispose();
  }

  void _startGame() {
    final p1 = p1Controller.text.trim().isEmpty ? 'RED' : p1Controller.text.trim().toUpperCase();
    final p2 = widget.vsAI ? 'CPU' : (p2Controller.text.trim().isEmpty ? 'BLUE' : p2Controller.text.trim().toUpperCase());
    final state = GameState(
      gridCols: selectedCols,
      gridRows: selectedRows,
      mode: widget.vsAI ? GameMode.vsAI : GameMode.vsLocal,
      player1Name: p1,
      player2Name: p2,
      player1Initial: p1.substring(0, 1),
      player2Initial: p2.substring(0, 1),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          gameState: state,
          aiDifficulty: widget.vsAI ? aiDifficulty : 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00FFCC)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.vsAI ? 'SETUP: VS COMPUTER' : 'SETUP: VS FRIEND',
          style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid Size
              _SectionTitle(title: 'GRID SIZE'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: gridPresets.map((preset) {
                  final selected = selectedCols == preset['cols'] && selectedRows == preset['rows'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedCols = preset['cols'];
                      selectedRows = preset['rows'];
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF00FFCC).withOpacity(0.15) : const Color(0xFF1C2F45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? const Color(0xFF00FFCC) : Colors.white12,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            preset['label'],
                            style: TextStyle(
                              color: selected ? const Color(0xFF00FFCC) : Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            preset['desc'],
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                '${(selectedCols - 1) * (selectedRows - 1)} boxes to fill',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 28),

              // Player Names
              _SectionTitle(title: 'PLAYERS'),
              const SizedBox(height: 12),
              _PlayerField(
                controller: p1Controller,
                label: 'Player 1 Name',
                color: const Color(0xFFE63946),
                icon: Icons.circle,
              ),
              const SizedBox(height: 12),
              _PlayerField(
                controller: p2Controller,
                label: widget.vsAI ? 'CPU (auto)' : 'Player 2 Name',
                color: const Color(0xFF457BFF),
                icon: Icons.circle,
                enabled: !widget.vsAI,
              ),
              const SizedBox(height: 28),

              // AI Difficulty (only vs AI)
              if (widget.vsAI) ...[
                _SectionTitle(title: 'AI DIFFICULTY'),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(3, (i) {
                    final selected = aiDifficulty == i + 1;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => aiDifficulty = i + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? diffColors[i].withOpacity(0.15) : const Color(0xFF1C2F45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? diffColors[i] : Colors.white12,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(diffIcons[i], color: selected ? diffColors[i] : Colors.white38, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                diffLabels[i].toUpperCase(),
                                style: TextStyle(
                                  color: selected ? diffColors[i] : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
              ],

              // Start Button
              GestureDetector(
                onTap: _startGame,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00FFCC), Color(0xFF00C9A7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFCC).withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'START GAME',
                      style: TextStyle(
                        color: Color(0xFF0D1B2A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00FFCC),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.5,
      ),
    );
  }
}

class _PlayerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;
  final IconData icon;
  final bool enabled;

  const _PlayerField({
    required this.controller,
    required this.label,
    required this.color,
    required this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2F45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLength: 12,
              style: TextStyle(color: enabled ? Colors.white : Colors.white38, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(color: Colors.white24),
                border: InputBorder.none,
                counterText: '',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        ],
      ),
    );
  }
}
