import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _detecting = false;
  bool _faceDetected = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: false,
      ),
    );
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
    );
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _detectFace() async {
    if (_detecting) return;
    _detecting = true;

    final image = await _cameraController!.takePicture();
    final inputImage = InputImage.fromFile(File(image.path));
    final faces = await _faceDetector!.processImage(inputImage);

    setState(() {
      _faceDetected = faces.isNotEmpty;
    });

    _detecting = false;
  }

  Future<void> _markAttendance() async {
    if (!_faceDetected) return;

    const empId = "demo_emp"; // TEMP (will come from face match later)
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final time = DateFormat('hh:mm a').format(DateTime.now());

    await FirebaseFirestore.instance.collection('attendance').doc(date).set({
      empId: {'time': time, 'status': 'present'},
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Attendance Marked')));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
          const SizedBox(height: 12),

          Text(
            _faceDetected ? 'Face Detected ✅' : 'No Face Detected ❌',
            style: TextStyle(
              color: _faceDetected ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _detectFace,
            icon: const Icon(Icons.face),
            label: const Text('Detect Face'),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: _faceDetected ? _markAttendance : null,
            child: const Text('Mark Attendance'),
          ),
        ],
      ),
    );
  }
}
