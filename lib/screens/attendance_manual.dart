import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee_model.dart';
import 'selfie_capture_screen.dart';

class ManualAttendanceScreen extends StatelessWidget {
  const ManualAttendanceScreen({super.key});

  String _todayDocId(String empId) {
    final today = DateTime.now();
    final date =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    return "${empId}_$date";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Employees")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = snapshot.data!.docs.map((doc) {
            return Employee.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              final attendanceDocId = _todayDocId(emp.id);

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('attendance')
                    .doc(attendanceDocId)
                    .snapshots(),
                builder: (context, attSnap) {
                  final data =
                      attSnap.data?.data() as Map<String, dynamic>?;

                  final bool isClockedIn =
                      data != null && data['clockInTime'] != null;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(emp.faceImageUrl),
                      ),
                      title: Text(emp.name),
                      subtitle: Text(emp.phone),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isClockedIn ? Colors.red : Colors.green,
                        ),
                        child: Text(isClockedIn ? "Clock Out" : "Clock In"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SelfieCaptureScreen(
                                employee: emp,
                                isClockIn: !isClockedIn,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
