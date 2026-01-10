import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:intime/screens/dashboard.dart';
import 'package:intime/screens/attendance.dart';
import 'package:intime/screens/employee_list.dart';
import 'package:intime/screens/report.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AttendanceScreen(),
    EmployeesListPage(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 60,
        backgroundColor: Colors.transparent,
        color: Colors.indigo,
        buttonBackgroundColor: Colors.indigoAccent,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          Icon(Icons.dashboard, color: Colors.white),
          Icon(Icons.camera_alt, color: Colors.white),
          Icon(Icons.group, color: Colors.white),
          Icon(Icons.assessment, color: Colors.white),
        ],
      ),
    );
  }
}
