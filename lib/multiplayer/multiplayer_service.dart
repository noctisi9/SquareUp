// lib/multiplayer/multiplayer_service.dart
// Multiplayer service stub — hook-in point for Bluetooth & Wi-Fi Direct
// Wire up nearby_connections or flutter_blue_plus here when ready

import '../game/game_state.dart';

enum ConnectionState { disconnected, scanning, connecting, connected }
enum HostRole { host, guest }

class MultiplayerMove {
  final LineOrientation orientation;
  final int row;
  final int col;

  MultiplayerMove({
    required this.orientation,
    required this.row,
    required this.col,
  });

  Map<String, dynamic> toJson() => {
    'o': orientation == LineOrientation.horizontal ? 'h' : 'v',
    'r': row,
    'c': col,
  };

  factory MultiplayerMove.fromJson(Map<String, dynamic> j) => MultiplayerMove(
    orientation: j['o'] == 'h' ? LineOrientation.horizontal : LineOrientation.vertical,
    row: j['r'],
    col: j['c'],
  );
}

abstract class MultiplayerService {
  ConnectionState connectionState = ConnectionState.disconnected;
  HostRole? role;

  // Called when a move is received from remote player
  void Function(MultiplayerMove move)? onMoveReceived;
  // Called when connection state changes
  void Function(ConnectionState state)? onConnectionChanged;
  // Called when opponent disconnects
  void Function()? onOpponentDisconnected;

  Future<void> startHosting(String playerName, int gridCols, int gridRows);
  Future<void> scanAndConnect(String playerName);
  Future<void> sendMove(MultiplayerMove move);
  Future<void> disconnect();
}

// ─── PLACEHOLDER IMPLEMENTATION (no-op) ─────────────────────────────────────
// Replace this with nearby_connections or flutter_blue_plus implementation

class StubMultiplayerService extends MultiplayerService {
  @override
  Future<void> startHosting(String playerName, int gridCols, int gridRows) async {
    // TODO: implement with nearby_connections package
    // NearbyConnections.instance.startAdvertising(...)
    throw UnimplementedError('Multiplayer not yet implemented. Coming soon!');
  }

  @override
  Future<void> scanAndConnect(String playerName) async {
    // TODO: implement with nearby_connections package
    // NearbyConnections.instance.startDiscovery(...)
    throw UnimplementedError('Multiplayer not yet implemented. Coming soon!');
  }

  @override
  Future<void> sendMove(MultiplayerMove move) async {
    // TODO: serialize move.toJson() and send over connection
    throw UnimplementedError('Multiplayer not yet implemented. Coming soon!');
  }

  @override
  Future<void> disconnect() async {
    connectionState = ConnectionState.disconnected;
    role = null;
  }
}

// ─── MOVE PROTOCOL ───────────────────────────────────────────────────────────
// When implementing:
// 1. Host advertises with service ID: 'com.noctis.dotsandboxes'
// 2. Guest discovers and connects
// 3. Host sends GAME_CONFIG: { cols, rows, hostIsP1: true }
// 4. Players take turns sending MOVE: { o, r, c }
// 5. Both sides apply the move to their local GameState
// 6. On disconnect mid-game, show reconnect dialog
