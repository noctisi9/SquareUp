// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'setup_screen.dart';

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
              const SizedBox(height: 32),
              // Brand
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFCC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00FFCC), width: 1.5),
                    ),
                    child: const Center(
                      child: Text('N', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 22, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('SQUAREUP', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4)),
                      Text('DOTS & BOXES', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // Title
              const Text(
                'CONNECT.\nCOMPETE.\nCONQUER.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Classic Dots & Boxes — draw lines, complete squares, own the grid.',
                style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
              ),
              const Spacer(),
              // Mode buttons
              _ModeCard(
                icon: Icons.smart_toy_outlined,
                title: 'VS COMPUTER',
                subtitle: 'Challenge the AI — 3 difficulty levels',
                color: const Color(0xFF00FFCC),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SetupScreen(vsAI: true)),
                ),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.people_outline,
                title: 'VS FRIEND',
                subtitle: 'Pass & play on the same device',
                color: const Color(0xFFE63946),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SetupScreen(vsAI: false)),
                ),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.wifi_tethering,
                title: 'ONLINE / HOTSPOT',
                subtitle: 'Coming soon — Bluetooth & Wi-Fi Direct',
                color: Colors.white24,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Multiplayer coming soon!'),
                    backgroundColor: Color(0xFF1C2F45),
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

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2F45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 14),
          ],
        ),
      ),
    );
  }
}
