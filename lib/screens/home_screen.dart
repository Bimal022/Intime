import 'package:flutter/material.dart';
import 'package:intime/screens/dashboard.dart';
import 'package:intime/widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _screens = const [DashboardScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _screens[_index]);
  }
}
