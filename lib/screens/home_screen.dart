// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'multiplayer_lobby_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Brand row
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFCC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00FFCC), width: 1.5),
                    ),
                    child: const Center(
                      child: Text('S', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 22, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SQUAREUP', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4)),
                      Text('DOTS & BOXES', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 52),
              const Text(
                'CONNECT.\nCOMPETE.\nCONQUER.',
                style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              const Text(
                'Classic Dots & Boxes — draw lines, complete squares, own the grid.',
                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
              ),
              const Spacer(),
              _ModeCard(
                icon: Icons.smart_toy_outlined,
                title: 'VS COMPUTER',
                subtitle: 'Challenge the AI — 3 difficulty levels',
                color: const Color(0xFF00FFCC),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SetupScreen(vsAI: true))),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.people_outline,
                title: 'VS FRIEND',
                subtitle: 'Pass & play on the same device',
                color: const Color(0xFFE63946),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SetupScreen(vsAI: false))),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.wifi_tethering,
                title: 'MULTIPLAYER',
                subtitle: 'Hotspot or Bluetooth — play over wireless',
                color: const Color(0xFFF4A261),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MultiplayerLobbyScreen())),
              ),
              const SizedBox(height: 28),
              // Credit
              Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 1),
                    children: [
                      TextSpan(text: 'Developed by '),
                      TextSpan(
                        text: 'NOCTIS',
                        style: TextStyle(
                          color: Color(0xFF00FFCC),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      TextSpan(text: ' • SquareUp v1.0'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ModeCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2F45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 13),
          ],
        ),
      ),
    );
  }
}
