import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intime/screens/attendance_face_recognition.dart';
import 'package:intime/screens/attendance_manual.dart';
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

      // Total employees
      final employeesSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .get();
      final totalEmployees = employeesSnapshot.docs.length;

      // Today date string
      final now = DateTime.now();
      final today =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Attendance where clockInTime exists today
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: today)
          .where('clockInTime', isNull: false)
          .get();

      final presentToday = attendanceSnapshot.docs.length;

      setState(() {
        _totalEmployees = totalEmployees;
        _presentToday = presentToday;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Dashboard error: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _recentClockIns() {
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Clock-Ins',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where('date', isEqualTo: today)
              .where('clockInTime', isNull: false)
              .orderBy('clockInTime', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Text(
                'No one has clocked in yet',
                style: TextStyle(color: Colors.grey),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final employeeId = data['employeeId'];
                final clockInTime = (data['clockInTime'] as Timestamp).toDate();

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('employees')
                      .doc(employeeId)
                      .get(),
                  builder: (context, empSnap) {
                    if (!empSnap.hasData) return const SizedBox();

                    final emp = empSnap.data!.data() as Map<String, dynamic>;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(emp['faceImageUrl']),
                      ),
                      title: Text(emp['name']),
                      subtitle: Text(
                        'Clocked in at ${TimeOfDay.fromDateTime(clockInTime).format(context)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
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
                _recentClockIns(),
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
    final double progress = _totalEmployees == 0
        ? 0
        : _presentToday / _totalEmployees;

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
                    MaterialPageRoute(
                      builder: (_) => const ManualAttendanceScreen(),
                    ),
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
