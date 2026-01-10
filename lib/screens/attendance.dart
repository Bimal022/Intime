// screens/attendance_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_recognition.dart';
import '../services/employee_face_service.dart';
import '../services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  bool _detecting = false;
  bool _faceDetected = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _faceCount = 0;

  // Face recognition data
  Map<String, dynamic>? _matchedEmployee;
  File? _capturedImage;
  Face? _detectedFace;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize face recognition model
      await FaceRecognitionService.initialize();

      // Initialize camera
      await _initCamera();

      // Initialize face detector
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: false,
          enableClassification: true,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Initialization failed: $e');
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() => _errorMessage = 'No cameras found');
        return;
      }
      await _setupCamera(_currentCameraIndex);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize camera: $e');
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      _cameras![cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _errorMessage = 'Camera error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() => _isLoading = true);
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    await _setupCamera(_currentCameraIndex);
    setState(() => _isLoading = false);
  }

  Future<void> _detectAndRecognizeFace() async {
    if (_detecting || _cameraController == null) return;

    setState(() {
      _detecting = true;
      _errorMessage = null;
      _matchedEmployee = null;
    });

    try {
      // Capture image
      final image = await _cameraController!.takePicture();
      _capturedImage = File(image.path);

      // Detect faces
      final inputImage = InputImage.fromFile(_capturedImage!);
      final faces = await _faceDetector!.processImage(inputImage);

      setState(() => _faceCount = faces.length);

      if (faces.isEmpty) {
        setState(() {
          _faceDetected = false;
          _errorMessage =
              'No face detected. Please position your face in the frame.';
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _faceDetected = false;
          _errorMessage =
              'Multiple faces detected. Please ensure only one person is in frame.';
        });
        return;
      }

      setState(() => _faceDetected = true);
      _detectedFace = faces.first;

      // Show processing indicator
      _showProcessingDialog();

      // Match face with employees
      final matchResult = await EmployeeFaceService.matchFaceWithEmployees(
        _capturedImage!,
        _detectedFace!,
      );

      // Close processing dialog
      if (mounted) Navigator.pop(context);

      if (matchResult == null) {
        setState(() {
          _errorMessage = 'Face not recognized. Please register first.';
          _faceDetected = false;
        });
        return;
      }

      // Check if already marked today
      final alreadyMarked = await AttendanceService.hasMarkedToday(
        matchResult['employeeId'],
      );

      if (alreadyMarked) {
        setState(() {
          _errorMessage =
              '${matchResult['name']} has already marked attendance today.';
          _faceDetected = false;
        });
        return;
      }

      setState(() {
        _matchedEmployee = matchResult;
      });

      // Show confirmation dialog
      _showConfirmationDialog();
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _faceDetected = false;
        _errorMessage = 'Recognition failed: $e';
      });
    } finally {
      setState(() => _detecting = false);
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Recognizing face...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    if (_matchedEmployee == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_matchedEmployee!['imageUrl'] != null &&
                _matchedEmployee!['imageUrl'].isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _matchedEmployee!['imageUrl'],
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              _matchedEmployee!['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${_matchedEmployee!['phone']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Match: ${_matchedEmployee!['similarity'].toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _matchedEmployee = null;
                _faceDetected = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _markAttendance();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAttendance() async {
    if (_matchedEmployee == null) return;

    setState(() => _isLoading = true);

    try {
      await AttendanceService.markAttendance(
        employeeId: _matchedEmployee!['employeeId'],
        employeeName: _matchedEmployee!['name'],
        photoUrl: _matchedEmployee!['imageUrl'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Attendance marked for ${_matchedEmployee!['name']}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        setState(() {
          _faceDetected = false;
          _faceCount = 0;
          _matchedEmployee = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _errorMessage != null && _cameraController == null
          ? _buildErrorView()
          : _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _buildCameraView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _errorMessage = null);
                _initializeServices();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        Column(
          children: [
            // Camera Preview
            Expanded(
              child: Container(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),

                    // Face detection overlay
                    Center(
                      child: Container(
                        width: 250,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _matchedEmployee != null
                                ? Colors.green
                                : _faceDetected
                                ? Colors.blue
                                : Colors.white,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(150),
                        ),
                      ),
                    ),

                    // Camera switch button
                    if (_cameras != null && _cameras!.length > 1)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _isLoading ? null : _switchCamera,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.black,
                          ),
                        ),
                      ),

                    // Instructions
                    Positioned(
                      top: 16,
                      left: 16,
                      right: _cameras != null && _cameras!.length > 1 ? 72 : 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Position your face within the oval',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Control Panel
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status indicator
                  if (_matchedEmployee != null)
                    _buildMatchedEmployeeCard()
                  else
                    _buildStatusIndicator(),

                  if (_errorMessage != null && _cameraController != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorMessage(),
                  ],

                  const SizedBox(height: 20),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _detecting || _isLoading
                          ? null
                          : _detectAndRecognizeFace,
                      icon: _detecting || _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.face_retouching_natural),
                      label: Text(
                        _detecting
                            ? 'Detecting...'
                            : _isLoading
                            ? 'Processing...'
                            : 'Scan Face',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _faceDetected ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _faceDetected ? Colors.blue : Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _faceDetected ? Icons.check_circle : Icons.face,
            color: _faceDetected ? Colors.blue : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _faceDetected ? 'Face Detected ($_faceCount)' : 'Ready to Scan',
            style: TextStyle(
              color: _faceDetected ? Colors.blue[900] : Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedEmployeeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _matchedEmployee!['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Match: ${_matchedEmployee!['similarity'].toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.green[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.orange[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
