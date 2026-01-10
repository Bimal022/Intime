import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intime/screens/attendance.dart';
import 'package:intime/screens/register_employee.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalEmployees = 0;
  int _presentToday = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final employeesSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .get();

      final totalEmployees = employeesSnapshot.docs.length;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('timestamp', isGreaterThanOrEqualTo: todayStart)
          .where('timestamp', isLessThan: todayEnd)
          .get();

      final uniqueEmployees = <String>{};
      for (var doc in attendanceSnapshot.docs) {
        final employeeId = doc.data()['employeeId'];
        if (employeeId != null) {
          uniqueEmployees.add(employeeId.toString());
        }
      }

      setState(() {
        _totalEmployees = totalEmployees;
        _presentToday = uniqueEmployees.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Dashboard error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade50, Colors.white],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 28),
                _statsRow(),
                const SizedBox(height: 28),
                _attendanceProgress(),
                const SizedBox(height: 32),
                _primaryActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${DateTime.now().hour < 12 ? "Morning" : "Evening"} 👋',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.indigo.shade50,
          child: Icon(Icons.notifications_none, color: Colors.indigo.shade700),
        ),
      ],
    );
  }

  // ---------------- STATS ----------------

  Widget _statsRow() {
    return Row(
      children: [
        _statCard(
          title: 'Total Employees',
          value: _isLoading ? '—' : _totalEmployees.toString(),
          icon: Icons.people_outline,
          gradient: LinearGradient(
            colors: [Colors.indigo.shade400, Colors.indigo.shade600],
          ),
        ),
        const SizedBox(width: 16),
        _statCard(
          title: 'Present Today',
          value: _isLoading ? '—' : _presentToday.toString(),
          icon: Icons.check_circle_outline,
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.teal.shade600],
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Expanded(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- PROGRESS ----------------

  Widget _attendanceProgress() {
    final double progress = _totalEmployees == 0 ? 0 : _presentToday / _totalEmployees;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today’s Attendance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Colors.indigo),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$_presentToday of $_totalEmployees employees present',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ---------------- ACTIONS ----------------

  Widget _primaryActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _actionTile(
                icon: Icons.camera_alt,
                title: 'Mark Attendance',
                color: Colors.indigo,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                  );
                  _loadDashboardData();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _actionTile(
                icon: Icons.person_add,
                title: 'Add Employee',
                color: Colors.purple,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterEmployeeScreen(),
                    ),
                  );
                  _loadDashboardData();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
