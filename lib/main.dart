import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DotsAndBoxesApp());
}

class DotsAndBoxesApp extends StatelessWidget {
  const DotsAndBoxesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOCTIS Dots & Boxes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D1B2A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Rajdhani',
      ),
      home: const HomeScreen(),
    );
  }
}
