// lib/screens/multiplayer_lobby_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_state.dart';
import '../multiplayer/hotspot_service.dart';
import 'game_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});
  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  // 0 = pick mode, 1 = host waiting, 2 = guest enter IP, 3 = connecting
  int _step = 0;
  String _status = '';
  String _hostIP = '';
  bool _isConnected = false;
  HotspotService? _service;
  final _ipCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(text: 'PLAYER');
  int _selectedCols = 6;
  int _selectedRows = 6;
  StreamSubscription? _statusSub;
  StreamSubscription? _moveSub;

  final List<Map<String, dynamic>> _gridPresets = [
    {'label': '3×3', 'cols': 3, 'rows': 3},
    {'label': '5×5', 'cols': 5, 'rows': 5},
    {'label': '7×7', 'cols': 7, 'rows': 7},
    {'label': '9×9', 'cols': 9, 'rows': 9},
  ];

  @override
  void dispose() {
    _statusSub?.cancel();
    _moveSub?.cancel();
    _service?.dispose();
    _ipCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── HOST ──────────────────────────────────────────────────────────────────
  Future<void> _startHost() async {
    setState(() { _step = 1; _status = 'Starting hotspot server...'; });
    _service = HotspotService();
    _statusSub = _service!.onStatus.listen((s) {
      if (!mounted) return;
      if (s.startsWith('HOST_READY:')) {
        final ip = s.split(':').last;
        setState(() { _hostIP = ip; _status = 'Your IP: $ip\nShare this with your friend!'; });
      } else if (s == 'WAITING') {
        setState(() => _status = 'Waiting for friend to connect...');
      } else if (s == 'CONNECTED') {
        setState(() { _isConnected = true; _status = 'Friend connected! Sending config...'; });
        // Host sends config and starts game
        _service!.sendConfig(_selectedCols, _selectedRows, _nameCtrl.text.trim().toUpperCase(), 'GUEST');
        Future.delayed(const Duration(milliseconds: 400), _launchGame);
      } else if (s == 'DISCONNECTED') {
        setState(() => _status = 'Connection lost.');
      }
    });
    try {
      await _service!.startHost();
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  // ── GUEST ─────────────────────────────────────────────────────────────────
  Future<void> _connectAsGuest() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) return;
    setState(() { _step = 3; _status = 'Connecting to $ip...'; });
    _service = HotspotService();

    // Wait for config from host
    _moveSub = _service!.onMove.listen((msg) {
      if (!mounted) return;
      if (msg['type'] == 'config') {
        _selectedCols = msg['cols'] as int;
        _selectedRows = msg['rows'] as int;
        _launchGame(guestName: _nameCtrl.text.trim().toUpperCase(), hostName: msg['p1'] as String);
      }
    });

    _statusSub = _service!.onStatus.listen((s) {
      if (!mounted) return;
      if (s == 'CONNECTED') setState(() => _status = 'Connected! Waiting for host...');
      if (s == 'DISCONNECTED') setState(() => _status = 'Connection lost.');
    });

    try {
      await _service!.connectToHost(ip);
    } catch (e) {
      setState(() => _status = 'Failed to connect: $e\n\nMake sure you\'re on their hotspot and the IP is correct.');
    }
  }

  // ── LAUNCH GAME ───────────────────────────────────────────────────────────
  void _launchGame({String? guestName, String? hostName}) {
    if (!mounted) return;
    final svc = _service!;
    final isHost = svc.isHost;
    final p1Name = isHost ? (_nameCtrl.text.trim().toUpperCase().isEmpty ? 'HOST' : _nameCtrl.text.trim().toUpperCase()) : (hostName ?? 'HOST');
    final p2Name = isHost ? 'GUEST' : (guestName ?? _nameCtrl.text.trim().toUpperCase().isEmpty ? 'GUEST' : _nameCtrl.text.trim().toUpperCase());

    final gs = GameState(
      gridCols: _selectedCols,
      gridRows: _selectedRows,
      mode: GameMode.vsOnline,
      player1Name: p1Name,
      player2Name: p2Name,
      player1Initial: p1Name.substring(0, 1),
      player2Initial: p2Name.substring(0, 1),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MultiplayerGameScreen(
          gameState: gs,
          service: svc,
          isHost: isHost,
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
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFF4A261)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('MULTIPLAYER', style: TextStyle(color: Color(0xFFF4A261), fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == 0 ? _buildPickMode() :
                 _step == 1 ? _buildHostWaiting() :
                 _step == 2 ? _buildGuestJoin() :
                              _buildConnecting(),
        ),
      ),
    );
  }

  // ── Step 0: Pick mode ─────────────────────────────────────────────────────
  Widget _buildPickMode() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('YOUR NAME'),
      const SizedBox(height: 8),
      _field(_nameCtrl, 'Enter your name'),
      const SizedBox(height: 24),
      _label('GRID SIZE'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10, runSpacing: 10,
        children: _gridPresets.map((p) {
          final sel = _selectedCols == p['cols'];
          return GestureDetector(
            onTap: () => setState(() { _selectedCols = p['cols']; _selectedRows = p['rows']; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFF4A261).withOpacity(0.15) : const Color(0xFF1C2F45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? const Color(0xFFF4A261) : Colors.white12, width: sel ? 2 : 1),
              ),
              child: Text(p['label'], style: TextStyle(color: sel ? const Color(0xFFF4A261) : Colors.white54, fontWeight: FontWeight.w800)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 32),
      _label('HOW TO CONNECT'),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF1C2F45), borderRadius: BorderRadius.circular(12)),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📡  Wi-Fi Hotspot', style: TextStyle(color: Color(0xFFF4A261), fontWeight: FontWeight.w800, fontSize: 13)),
            SizedBox(height: 6),
            Text('1. One person turns on Mobile Hotspot\n2. Other person connects to that hotspot on Wi-Fi\n3. HOST taps "Create Game" below\n4. GUEST taps "Join Game" and enters the IP shown',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6)),
          ],
        ),
      ),
      const SizedBox(height: 28),
      _bigBtn('CREATE GAME (HOST)', const Color(0xFF00FFCC), () { setState(() => _step = 1); _startHost(); }),
      const SizedBox(height: 14),
      _bigBtn('JOIN GAME (GUEST)', const Color(0xFF457BFF), () => setState(() => _step = 2)),
    ],
  );

  // ── Step 1: Host waiting ───────────────────────────────────────────────────
  Widget _buildHostWaiting() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 20),
      const Icon(Icons.wifi_tethering, color: Color(0xFF00FFCC), size: 52),
      const SizedBox(height: 20),
      const Text('HOSTING GAME', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2)),
      const SizedBox(height: 16),
      if (_hostIP.isNotEmpty) ...[
        const Text('Your IP address:', style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _hostIP));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IP copied!'), backgroundColor: Color(0xFF1C2F45)));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF00FFCC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00FFCC).withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_hostIP, style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(width: 10),
                const Icon(Icons.copy, color: Color(0xFF00FFCC), size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Tap to copy • Share with your friend', style: TextStyle(color: Colors.white24, fontSize: 11)),
      ],
      const SizedBox(height: 20),
      if (!_isConnected) const CircularProgressIndicator(color: Color(0xFF00FFCC), strokeWidth: 2),
      const SizedBox(height: 16),
      Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
      const SizedBox(height: 32),
      _bigBtn('CANCEL', Colors.white24, () {
        _service?.dispose();
        setState(() { _step = 0; _status = ''; _hostIP = ''; _isConnected = false; });
      }),
    ],
  );

  // ── Step 2: Guest enter IP ─────────────────────────────────────────────────
  Widget _buildGuestJoin() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      const Text('Enter the IP shown on your friend\'s screen:', style: TextStyle(color: Colors.white54, fontSize: 13)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2F45), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF457BFF).withOpacity(0.5), width: 1.5),
        ),
        child: TextField(
          controller: _ipCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
          decoration: const InputDecoration(
            hintText: '192.168.x.x',
            hintStyle: TextStyle(color: Colors.white24),
            border: InputBorder.none,
          ),
        ),
      ),
      const SizedBox(height: 24),
      _bigBtn('CONNECT', const Color(0xFF457BFF), _connectAsGuest),
      const SizedBox(height: 14),
      _bigBtn('BACK', Colors.white24, () => setState(() => _step = 0)),
    ],
  );

  // ── Step 3: Connecting spinner ─────────────────────────────────────────────
  Widget _buildConnecting() => Column(
    children: [
      const SizedBox(height: 40),
      const CircularProgressIndicator(color: Color(0xFF457BFF), strokeWidth: 2),
      const SizedBox(height: 20),
      Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.6)),
      const SizedBox(height: 32),
      _bigBtn('CANCEL', Colors.white24, () {
        _service?.dispose();
        setState(() { _step = 0; _status = ''; });
      }),
    ],
  );

  Widget _label(String t) => Text(t, style: const TextStyle(color: Color(0xFFF4A261), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2));

  Widget _field(TextEditingController c, String hint) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF1C2F45), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white12),
    ),
    child: TextField(
      controller: c, maxLength: 12,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white24), border: InputBorder.none, counterText: ''),
      textCapitalization: TextCapitalization.characters,
    ),
  );

  Widget _bigBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2))),
    ),
  );
}

// ── Multiplayer Game Screen wrapper ──────────────────────────────────────────
class MultiplayerGameScreen extends StatefulWidget {
  final GameState gameState;
  final HotspotService service;
  final bool isHost;
  const MultiplayerGameScreen({super.key, required this.gameState, required this.service, required this.isHost});
  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  StreamSubscription? _moveSub;
  StreamSubscription? _statusSub;
  int _lastBoxes = 0;

  // Host = Player.one, Guest = Player.two
  Player get myPlayer => widget.isHost ? Player.one : Player.two;
  bool get isMyTurn => widget.gameState.currentPlayer == myPlayer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _moveSub = widget.service.onMove.listen((msg) {
      if (!mounted) return;
      if (msg['type'] == 'config') return; // ignore late config
      final o = msg['o'] == 'h' ? LineOrientation.horizontal : LineOrientation.vertical;
      final result = widget.gameState.drawLine(o, msg['r'] as int, msg['c'] as int);
      setState(() => _lastBoxes = result.boxesCompleted);
      if (widget.gameState.gameOver) _showGameOver();
    });

    _statusSub = widget.service.onStatus.listen((s) {
      if (!mounted) return;
      if (s == 'DISCONNECTED') {
        showDialog(context: context, barrierDismissible: false, builder: (_) => Dialog(
          backgroundColor: const Color(0xFF1C2F45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('OPPONENT\nDISCONNECTED', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () { Navigator.of(context).pop(); Navigator.of(context).popUntil((r) => r.isFirst); },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: const Color(0xFFE63946).withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE63946).withOpacity(0.5))),
                  child: const Center(child: Text('GO HOME', style: TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.w800, letterSpacing: 1.5))),
                ),
              ),
            ]),
          ),
        ));
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _moveSub?.cancel();
    _statusSub?.cancel();
    widget.service.dispose();
    super.dispose();
  }

  void _onLineTapped(LineOrientation orientation, int row, int col) {
    if (!isMyTurn) return;
    if (widget.gameState.gameOver) return;
    final result = widget.gameState.drawLine(orientation, row, col);
    if (!result.success) return;
    widget.service.sendMove(orientation, row, col);
    setState(() => _lastBoxes = result.boxesCompleted);
    if (widget.gameState.gameOver) _showGameOver();
  }

  void _showGameOver() {
    final gs = widget.gameState;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1C2F45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('GAME OVER', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            if (gs.isDrawGame) const Text("IT'S A DRAW! 🤝", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))
            else Text('${gs.winnerName} WINS! 🏆', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Column(children: [Text(gs.player1Name, style: const TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.w800)), Text('${gs.player1Score}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))]),
              Column(children: [Text(gs.player2Name, style: const TextStyle(color: Color(0xFF457BFF), fontWeight: FontWeight.w800)), Text('${gs.player2Score}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))]),
            ]),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () { Navigator.of(context).pop(); Navigator.of(context).popUntil((r) => r.isFirst); },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(color: const Color(0xFF00FFCC).withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF00FFCC).withOpacity(0.5))),
                child: const Center(child: Text('HOME', style: TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.w800, letterSpacing: 2))),
              ),
            ),
          ]),
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

    return WillPopScope(
      onWillPop: () async { Navigator.of(context).popUntil((r) => r.isFirst); return false; },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white38, size: 18), onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF4A261).withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF4A261).withOpacity(0.4))),
                  child: Text(
                    isMyTurn ? 'YOUR TURN' : 'WAITING...',
                    style: TextStyle(color: isMyTurn ? const Color(0xFF00FFCC) : Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                _ScoreCard(name: gs.player1Name, score: gs.player1Score, color: p1Color, isActive: isP1Turn && !gs.gameOver, pulseAnim: _pulseAnim),
                Expanded(child: Center(child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Opacity(opacity: _pulseAnim.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: currentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: currentColor.withOpacity(0.4))),
                      child: Text(gs.gameOver ? 'DONE' : '●', style: TextStyle(color: currentColor, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ))),
                _ScoreCard(name: gs.player2Name, score: gs.player2Score, color: p2Color, isActive: !isP1Turn && !gs.gameOver, pulseAnim: _pulseAnim, alignRight: true),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: GameBoard(gameState: gs, onLineTapped: _onLineTapped, aiThinking: !isMyTurn),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                gs.gameOver ? '' : isMyTurn ? '${gs.currentPlayerName} — tap a line' : 'Waiting for ${gs.currentPlayerName}...',
                style: TextStyle(color: Color(gs.currentPlayerColorValue).withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String name; final int score; final Color color;
  final bool isActive; final Animation<double> pulseAnim; final bool alignRight;
  const _ScoreCard({required this.name, required this.score, required this.color, required this.isActive, required this.pulseAnim, this.alignRight = false});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulseAnim,
    builder: (_, __) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.12) : const Color(0xFF1C2F45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? color.withOpacity(0.5 * pulseAnim.value + 0.3) : Colors.white12, width: isActive ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          Text('$score', style: TextStyle(color: isActive ? color : Colors.white54, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
        ],
      ),
    ),
  );
}
