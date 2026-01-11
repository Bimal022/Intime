import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/employee_model.dart';

class SelfieCaptureScreen extends StatefulWidget {
  final Employee employee;
  final bool isClockIn;

  const SelfieCaptureScreen({
    super.key,
    required this.employee,
    required this.isClockIn,
  });

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  CameraController? _controller;
  bool _captured = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    setState(() {});

    // ⏱ Auto capture after camera opens
    Future.delayed(const Duration(seconds: 2), _autoCapture);
  }

  Future<void> _autoCapture() async {
    if (_captured || !_controller!.value.isInitialized) return;
    _captured = true;

    final image = await _controller!.takePicture();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await image.saveTo(file.path);

    await _saveAttendance(file.path);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveAttendance(String imagePath) async {
    final today = DateTime.now();
    final date =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final docId = "${widget.employee.id}_$date";

    final ref =
        FirebaseFirestore.instance.collection('attendance').doc(docId);

    if (widget.isClockIn) {
      await ref.set({
        'employeeId': widget.employee.id,
        'date': date,
        'clockInTime': FieldValue.serverTimestamp(),
        'clockInImage': imagePath,
      }, SetOptions(merge: true));
    } else {
      await ref.update({
        'clockOutTime': FieldValue.serverTimestamp(),
        'clockOutImage': imagePath,
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CameraPreview(_controller!),
    );
  }
}
