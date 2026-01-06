import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.file_download_outlined, size: 20),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Export feature coming soon!'),
                  backgroundColor: Colors.indigo.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _statCard(
                  icon: Icons.people_outline,
                  title: 'Total',
                  value: '45',
                  color: Colors.indigo,
                ),
                const SizedBox(width: 12),
                _statCard(
                  icon: Icons.check_circle_outline,
                  title: 'Present',
                  value: '38',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _statCard(
                  icon: Icons.cancel_outlined,
                  title: 'Absent',
                  value: '7',
                  color: Colors.red,
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Daily'),
                Tab(text: 'Monthly'),
                Tab(text: 'History'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDailyReport(),
                _buildMonthlyReport(),
                _buildHistoryReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReport() {
    return Column(
      children: [
        // Date Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Attendance List
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('attendance')
                .doc(DateFormat('yyyy-MM-dd').format(_selectedDate))
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.indigo.shade400,
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return _emptyState(
                  icon: Icons.event_busy,
                  title: 'No Attendance Records',
                  subtitle: 'No attendance data for this date',
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final empId = data.keys.elementAt(index);
                  final record = data[empId] as Map<String, dynamic>;

                  return _attendanceCard(
                    employeeName: empId,
                    time: record['time'] ?? 'N/A',
                    status: record['status'] ?? 'absent',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('employees')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.indigo.shade400,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
            icon: Icons.people_outline,
            title: 'No Employees',
            subtitle: 'Register employees to view monthly reports',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final employee = snapshot.data!.docs[index];
            final name = employee['name'] ?? 'Unknown';

            return _monthlyReportCard(
              employeeName: name,
              present: 22,
              absent: 3,
              late: 2,
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.indigo.shade400,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
            icon: Icons.history,
            title: 'No History',
            subtitle: 'Attendance history will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final date = doc.id;
            final data = doc.data() as Map<String, dynamic>;

            return _historyCard(
              date: date,
              totalPresent: data.length,
            );
          },
        );
      },
    );
  }

  Widget _attendanceCard({
    required String employeeName,
    required String time,
    required String status,
  }) {
    final isPresent = status.toLowerCase() == 'present';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPresent
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPresent ? Icons.check_circle : Icons.cancel,
              color: isPresent ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Marked at $time',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPresent
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPresent ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyReportCard({
    required String employeeName,
    required int present,
    required int absent,
    required int late,
  }) {
    final total = present + absent;
    final percentage = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.indigo.shade100,
                child: Text(
                  employeeName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.indigo.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Attendance: $percentage%',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat('Present', present.toString(), Colors.green),
              const SizedBox(width: 12),
              _miniStat('Absent', absent.toString(), Colors.red),
              const SizedBox(width: 12),
              _miniStat('Late', late.toString(), Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyCard({
    required String date,
    required int totalPresent,
  }) {
    DateTime parsedDate;
    try {
      parsedDate = DateFormat('yyyy-MM-dd').parse(date);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.indigo.shade600],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(parsedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalPresent employees marked attendance',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}