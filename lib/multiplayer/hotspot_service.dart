// lib/multiplayer/hotspot_service.dart
// TCP socket multiplayer over Wi-Fi Hotspot
// Fixes:
//   1. ServerSocket.listen() instead of .first.then() — keeps stream alive
//   2. Buffer-based message framing — handles fragmented TCP packets
//   3. Keepalive ping every 4s — prevents hotspot idle-kill
//   4. Socket ownership transfer — dispose() is safe to call from lobby
//      because the game screen calls detach() first to take ownership

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import '../game/game_state.dart';

const int kPort = 45454;
const Duration kPingInterval = Duration(seconds: 4);
const Duration kConnectTimeout = Duration(seconds: 10);

class HotspotService {
  ServerSocket? _server;
  Socket? _socket;
  bool isHost = false;
  bool _disposed = false;
  bool _detached = false; // true = game screen owns socket, lobby must not close it

  // Incoming message buffer — handles fragmented TCP packets
  final StringBuffer _buf = StringBuffer();

  Timer? _pingTimer;
  Timer? _reconnectTimer;

  final _moveCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _statusCtrl = StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get onMove => _moveCtrl.stream;
  Stream<String> get onStatus => _statusCtrl.stream;

  String? localIP;
  bool get isConnected => _socket != null;

  // ── HOST ──────────────────────────────────────────────────────────────────
  Future<void> startHost() async {
    isHost = true;
    localIP = await _getLocalIP();
    _emit('HOST_READY:${localIP ?? "unknown"}');

    // Close any previous server
    await _server?.close();

    _server = await ServerSocket.bind(InternetAddress.anyIPv4, kPort, shared: true);
    _emit('WAITING');

    // FIX 1: use .listen() not .first.then() — keeps the server stream open
    _server!.listen(
      (socket) {
        if (_socket != null) {
          // Reject extra connections
          socket.destroy();
          return;
        }
        _socket = socket;
        _configureSocket(socket);
        _emit('CONNECTED');
        _startListening();
        _startPing();
      },
      onError: (e) => _emit('ERROR:$e'),
      onDone: () {
        if (!_disposed) _emit('SERVER_CLOSED');
      },
    );
  }

  // ── GUEST ─────────────────────────────────────────────────────────────────
  Future<void> connectToHost(String hostIP) async {
    isHost = false;
    _socket = await Socket.connect(
      hostIP, kPort,
      timeout: kConnectTimeout,
    );
    _configureSocket(_socket!);
    _emit('CONNECTED');
    _startListening();
    _startPing();
  }

  // ── Socket options — disable Nagle, enable keepalive ─────────────────────
  void _configureSocket(Socket s) {
    try {
      // FIX 3a: disable Nagle's algorithm — sends small packets immediately
      s.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {}
  }

  // ── Listen with buffer — FIX 2 ───────────────────────────────────────────
  void _startListening() {
    _socket!.listen(
      (data) {
        // Append incoming bytes to buffer
        _buf.write(utf8.decode(data, allowMalformed: true));
        // Process all complete lines
        final raw = _buf.toString();
        final lines = raw.split('\n');
        // Last element may be incomplete — keep it in buffer
        _buf.clear();
        _buf.write(lines.last);
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          // Ignore keepalive pings
          if (line == '{"ping":1}') continue;
          try {
            final map = jsonDecode(line) as Map<String, dynamic>;
            if (!_moveCtrl.isClosed) _moveCtrl.add(map);
          } catch (_) {
            // Malformed packet — ignore, don't disconnect
          }
        }
      },
      onDone: () {
        _pingTimer?.cancel();
        if (!_disposed && !_detached) _emit('DISCONNECTED');
      },
      onError: (e) {
        _pingTimer?.cancel();
        if (!_disposed && !_detached) _emit('DISCONNECTED');
      },
      cancelOnError: false, // FIX: don't auto-cancel on error
    );
  }

  // ── Keepalive ping — FIX 3 ───────────────────────────────────────────────
  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(kPingInterval, (_) {
      if (_socket == null || _disposed) return;
      try {
        _socket!.write('{"ping":1}\n');
      } catch (_) {
        _pingTimer?.cancel();
        if (!_disposed) _emit('DISCONNECTED');
      }
    });
  }

  // ── Send move ─────────────────────────────────────────────────────────────
  void sendMove(LineOrientation orientation, int row, int col) {
    _send({
      'o': orientation == LineOrientation.horizontal ? 'h' : 'v',
      'r': row,
      'c': col,
    });
  }

  void sendConfig(int cols, int rows, String p1Name, String p2Name) {
    _send({'type': 'config', 'cols': cols, 'rows': rows, 'p1': p1Name, 'p2': p2Name});
  }

  void _send(Map<String, dynamic> msg) {
    if (_socket == null || _disposed) return;
    try {
      _socket!.write(jsonEncode(msg) + '\n');
    } catch (e) {
      if (!_disposed) _emit('DISCONNECTED');
    }
  }

  void _emit(String status) {
    if (!_statusCtrl.isClosed) _statusCtrl.add(status);
  }

  // ── FIX 4: detach — lobby calls this before navigating to game screen ─────
  // After detach, dispose() will NOT close the socket.
  // The game screen calls dispose() when it's done.
  void detach() {
    _detached = true;
  }

  void reattach() {
    _detached = false;
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    // Only close socket if game screen hasn't taken ownership
    if (!_detached) {
      try { _socket?.destroy(); } catch (_) {}
      try { await _server?.close(); } catch (_) {}
    }
    if (!_moveCtrl.isClosed) await _moveCtrl.close();
    if (!_statusCtrl.isClosed) await _statusCtrl.close();
  }

  // ── Get local IP via network_info_plus (reliable on Android hotspot) ──────
  Future<String?> _getLocalIP() async {
    try {
      final info = NetworkInfo();
      // getWifiIP returns the IP of the current Wi-Fi/hotspot interface
      final ip = await info.getWifiIP();
      if (ip != null && ip.isNotEmpty) return ip;
    } catch (_) {}
    // Fallback: NetworkInterface scan
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
