import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee_model.dart';
import 'selfie_capture_screen.dart';

class ManualAttendanceScreen extends StatelessWidget {
  const ManualAttendanceScreen({super.key});

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
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(emp.faceImageUrl),
                  ),
                  title: Text(emp.name),
                  subtitle: Text(emp.phone),
                  trailing: ElevatedButton(
                    child: const Text("Attendance"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SelfieCaptureScreen(employee: emp),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
