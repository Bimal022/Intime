// services/employee_face_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_recognition.dart';

class EmployeeFaceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all employee face embeddings from Firestore
  static Future<Map<String, Map<String, dynamic>>> getAllEmployeeEmbeddings() async {
    try {
      final snapshot = await _firestore.collection('employees').get();
      final embeddings = <String, Map<String, dynamic>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final embeddingData = data['faceEmbedding'];
        
        if (embeddingData != null && embeddingData is List) {
          embeddings[doc.id] = {
            'embedding': List<double>.from(embeddingData),
            'name': data['name'] ?? 'Unknown',
            'phone': data['phone'] ?? '',
            'imageUrl': data['faceImageUrl'] ?? '',
          };
        }
      }

      return embeddings;
    } catch (e) {
      print('Error fetching employee embeddings: $e');
      return {};
    }
  }

  // Generate and store face embedding for an employee
  static Future<bool> generateAndStoreEmbedding({
    required String employeeId,
    required String imageUrl,
  }) async {
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Save temporarily
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_face_$employeeId.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Detect face
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: false,
          enableClassification: true,
        ),
      );

      final inputImage = InputImage.fromFile(tempFile);
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        throw Exception('No face detected in image');
      }

      if (faces.length > 1) {
        throw Exception('Multiple faces detected');
      }

      // Extract face embedding
      final embedding = await FaceRecognitionService.getFaceEmbedding(
        tempFile,
        faces.first,
      );

      if (embedding == null) {
        throw Exception('Failed to extract face embedding');
      }

      // Store embedding in Firestore
      await _firestore.collection('employees').doc(employeeId).update({
        'faceEmbedding': embedding,
        'embeddingGeneratedAt': FieldValue.serverTimestamp(),
      });

      // Clean up
      await tempFile.delete();

      return true;
    } catch (e) {
      print('Error generating embedding: $e');
      return false;
    }
  }

  // Match a captured face with registered employees
  static Future<Map<String, dynamic>?> matchFaceWithEmployees(
    File capturedImage,
    Face detectedFace,
  ) async {
    try {
      // Extract embedding from captured face
      final capturedEmbedding = await FaceRecognitionService.getFaceEmbedding(
        capturedImage,
        detectedFace,
      );

      if (capturedEmbedding == null) {
        throw Exception('Failed to extract face embedding from captured image');
      }

      // Get all employee embeddings
      final employeeData = await getAllEmployeeEmbeddings();
      
      if (employeeData.isEmpty) {
        throw Exception('No registered employees found');
      }

      // Find best match
      String? matchedId;
      double highestSimilarity = 0.0;
      Map<String, dynamic>? matchedEmployee;

      employeeData.forEach((employeeId, data) {
        final storedEmbedding = data['embedding'] as List<double>;
        final similarity = FaceRecognitionService.calculateSimilarity(
          capturedEmbedding,
          storedEmbedding,
        );

        if (similarity > highestSimilarity && similarity >= 70.0) {
          highestSimilarity = similarity;
          matchedId = employeeId;
          matchedEmployee = data;
        }
      });

      if (matchedId == null) {
        return null; // No match found
      }

      return {
        'employeeId': matchedId,
        'name': matchedEmployee!['name'],
        'phone': matchedEmployee!['phone'],
        'imageUrl': matchedEmployee!['imageUrl'],
        'similarity': highestSimilarity,
      };
    } catch (e) {
      print('Error matching face: $e');
      return null;
    }
  }

  // Batch process: Generate embeddings for all employees without embeddings
  static Future<Map<String, bool>> generateEmbeddingsForAllEmployees() async {
    try {
      final snapshot = await _firestore
          .collection('employees')
          .where('faceEmbedding', isNull: true)
          .get();

      final results = <String, bool>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final imageUrl = data['faceImageUrl'];

        if (imageUrl != null && imageUrl.isNotEmpty) {
          final success = await generateAndStoreEmbedding(
            employeeId: doc.id,
            imageUrl: imageUrl,
          );
          results[doc.id] = success;
        }
      }

      return results;
    } catch (e) {
      print('Error in batch processing: $e');
      return {};
    }
  }
}