import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../models/employee_model.dart';

class SelfieCaptureScreen extends StatefulWidget {
  final Employee employee;

  const SelfieCaptureScreen({super.key, required this.employee});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  CameraController? _controller;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() {});

    _autoCapture();
  }

  Future<void> _autoCapture() async {
    await Future.delayed(const Duration(seconds: 2));
    if (_isCapturing) return;
    _isCapturing = true;

    final image = await _controller!.takePicture();
    final imageUrl = await _uploadImage(File(image.path));
    await _markAttendance(imageUrl);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<String> _uploadImage(File file) async {
    final ref = FirebaseStorage.instance
        .ref('attendance/${widget.employee.id}/${DateTime.now()}.jpg');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _markAttendance(String selfieUrl) async {
    final dateDoc = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(dateDoc)
        .set({
      widget.employee.id: {
        "status": "present",
        "time": DateFormat('hh:mm a').format(DateTime.now()),
        "timestamp": FieldValue.serverTimestamp(),
        "selfie": selfieUrl,
      }
    }, SetOptions(merge: true));
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
      appBar: AppBar(title: const Text("Capturing Selfie")),
      body: CameraPreview(_controller!),
    );
  }
}
