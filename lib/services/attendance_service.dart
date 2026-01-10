// services/attendance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mark attendance for an employee
  static Future<bool> markAttendance({
    required String employeeId,
    required String employeeName,
    String? photoUrl,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timeStr = DateFormat('hh:mm a').format(now);

      // Check if already marked today
      final todayDoc = await _firestore
          .collection('attendance')
          .doc(dateStr)
          .get();

      if (todayDoc.exists) {
        final data = todayDoc.data();
        if (data != null && data.containsKey(employeeId)) {
          throw Exception('Attendance already marked for today');
        }
      }

      // Mark attendance
      await _firestore.collection('attendance').doc(dateStr).set({
        employeeId: {
          'employeeName': employeeName,
          'time': timeStr,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'present',
          'photoUrl': photoUrl,
        },
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow;
    }
  }

  // Check if employee has already marked attendance today
  static Future<bool> hasMarkedToday(String employeeId) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);

      final doc = await _firestore
          .collection('attendance')
          .doc(dateStr)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      return data?.containsKey(employeeId) ?? false;
    } catch (e) {
      print('Error checking attendance: $e');
      return false;
    }
  }

  // Get attendance for a specific date
  static Future<Map<String, dynamic>> getAttendanceByDate(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _firestore
          .collection('attendance')
          .doc(dateStr)
          .get();

      if (!doc.exists) return {};

      return doc.data() ?? {};
    } catch (e) {
      print('Error fetching attendance: $e');
      return {};
    }
  }

  // Get attendance history for an employee
  static Future<List<Map<String, dynamic>>> getEmployeeAttendanceHistory({
    required String employeeId,
    int days = 30,
  }) async {
    try {
      final now = DateTime.now();
      final history = <Map<String, dynamic>>[];

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        final doc = await _firestore
            .collection('attendance')
            .doc(dateStr)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null && data.containsKey(employeeId)) {
            history.add({
              'date': dateStr,
              'time': data[employeeId]['time'],
              'status': data[employeeId]['status'],
              'timestamp': data[employeeId]['timestamp'],
            });
          }
        }
      }

      return history;
    } catch (e) {
      print('Error fetching employee history: $e');
      return [];
    }
  }

  // Get today's attendance count
  static Future<int> getTodayAttendanceCount() async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);

      final doc = await _firestore
          .collection('attendance')
          .doc(dateStr)
          .get();

      if (!doc.exists) return 0;

      final data = doc.data();
      return data?.keys.length ?? 0;
    } catch (e) {
      print('Error getting today count: $e');
      return 0;
    }
  }

  // Get attendance statistics for a date range
  static Future<Map<String, int>> getAttendanceStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      int totalDays = 0;
      int totalPresent = 0;
      final employeeAttendance = <String, int>{};

      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        totalDays++;
        final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

        final doc = await _firestore
            .collection('attendance')
            .doc(dateStr)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            totalPresent += data.keys.length;
            
            data.forEach((employeeId, _) {
              employeeAttendance[employeeId] = (employeeAttendance[employeeId] ?? 0) + 1;
            });
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      return {
        'totalDays': totalDays,
        'totalPresent': totalPresent,
        'uniqueEmployees': employeeAttendance.keys.length,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {};
    }
  }
}