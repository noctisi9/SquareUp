// lib/multiplayer/hotspot_service.dart
// TCP socket multiplayer over Wi-Fi Hotspot
// Host listens on port 45454, Guest connects to host IP

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../game/game_state.dart';

const int kPort = 45454;

class HotspotService {
  ServerSocket? _server;
  Socket? _socket;
  bool isHost = false;

  final _moveCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _statusCtrl = StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get onMove => _moveCtrl.stream;
  Stream<String> get onStatus => _statusCtrl.stream;

  String? localIP;

  // ── HOST: open a server, wait for one client ──────────────────────────────
  Future<void> startHost() async {
    isHost = true;
    localIP = await _getLocalIP();
    _statusCtrl.add('HOST_READY:$localIP');
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, kPort);
    _statusCtrl.add('WAITING');
    _server!.first.then((socket) {
      _socket = socket;
      _statusCtrl.add('CONNECTED');
      _listen();
    });
  }

  // ── GUEST: connect to host by IP ─────────────────────────────────────────
  Future<void> connectToHost(String hostIP) async {
    isHost = false;
    _socket = await Socket.connect(hostIP, kPort, timeout: const Duration(seconds: 8));
    _statusCtrl.add('CONNECTED');
    _listen();
  }

  void _listen() {
    _socket!.listen(
      (data) {
        final text = utf8.decode(data).trim();
        for (final line in text.split('\n')) {
          if (line.isEmpty) continue;
          try {
            final map = jsonDecode(line) as Map<String, dynamic>;
            _moveCtrl.add(map);
          } catch (_) {}
        }
      },
      onDone: () => _statusCtrl.add('DISCONNECTED'),
      onError: (_) => _statusCtrl.add('DISCONNECTED'),
    );
  }

  void sendMove(LineOrientation orientation, int row, int col) {
    if (_socket == null) return;
    final msg = jsonEncode({
      'o': orientation == LineOrientation.horizontal ? 'h' : 'v',
      'r': row,
      'c': col,
    }) + '\n';
    _socket!.write(msg);
  }

  void sendConfig(int cols, int rows, String p1Name, String p2Name) {
    if (_socket == null) return;
    final msg = jsonEncode({'type': 'config', 'cols': cols, 'rows': rows, 'p1': p1Name, 'p2': p2Name}) + '\n';
    _socket!.write(msg);
  }

  Future<void> dispose() async {
    await _socket?.close();
    await _server?.close();
    await _moveCtrl.close();
    await _statusCtrl.close();
  }

  Future<String?> _getLocalIP() async {
    try {
      final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }
}
