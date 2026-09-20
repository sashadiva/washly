import 'package:flutter/material.dart';
import 'screens/discovery_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const WashlyApp());
}

class WashlyApp extends StatelessWidget {
  const WashlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Washly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DiscoveryScreen(),
    );
  }
}