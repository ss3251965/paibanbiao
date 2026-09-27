import 'package:flutter/material.dart';
import 'screens/calendar_screen.dart';

void main() {
  runApp(const BanBiaoApp());
}

class BanBiaoApp extends StatelessWidget {
  const BanBiaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '班表小历',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A6CF7)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7FA),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6CF7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      ),
      home: const CalendarScreen(),
    );
  }
}