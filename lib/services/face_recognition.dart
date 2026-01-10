// services/face_recognition_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class FaceRecognitionService {
  static Interpreter? _interpreter;
  static const double _threshold = 1.0; // Euclidean distance threshold

  // Initialize the TFLite model
  static Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model/mobilefacenet.tflite',
      );
      print('Face recognition model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      throw Exception('Failed to load face recognition model');
    }
  }

  // Extract face embeddings from an image
  static Future<List<double>?> getFaceEmbedding(
    File imageFile,
    Face face,
  ) async {
    if (_interpreter == null) {
      await initialize();
    }

    try {
      // Read and decode image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return null;

      // Crop face from image
      final faceImg = _cropFace(image, face);
      if (faceImg == null) return null;

      // Resize to model input size (112x112 for MobileFaceNet)
      final resized = img.copyResize(faceImg, width: 112, height: 112);

      // Convert to input tensor format
      final input = _imageToByteListFloat32(resized);
      if (input == null) return null;

      // Output tensor
      final output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      // Run inference
      _interpreter!.run(input, output);

      // Normalize embedding
      final embedding = List<double>.from(output[0] as Iterable);
      return _normalizeEmbedding(embedding);
    } catch (e) {
      print('Error extracting face embedding: $e');
      return null;
    }
  }

  // Crop face from image using face bounding box
  static img.Image? _cropFace(img.Image image, Face face) {
    try {
      final boundingBox = face.boundingBox;

      // Add padding around face
      final padding = 20;
      final x = max(0, boundingBox.left.toInt() - padding);
      final y = max(0, boundingBox.top.toInt() - padding);
      final width = min(
        image.width - x,
        boundingBox.width.toInt() + (padding * 2),
      );
      final height = min(
        image.height - y,
        boundingBox.height.toInt() + (padding * 2),
      );

      return img.copyCrop(image, x: x, y: y, width: width, height: height);
    } catch (e) {
      print('Error cropping face: $e');
      return null;
    }
  }

  // Convert image to ByteList for model input
  static Float32List? _imageToByteListFloat32(img.Image image) {
    final convertedBytes = Float32List(1 * 112 * 112 * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int i = 0; i < 112; i++) {
      for (int j = 0; j < 112; j++) {
        final pixel = image.getPixel(j, i);

        // Normalize to [-1, 1]
        buffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }

    return convertedBytes;
  }

  // Normalize embedding vector
  static List<double> _normalizeEmbedding(List<double> embedding) {
    final norm = sqrt(embedding.fold(0.0, (sum, val) => sum + val * val));
    return embedding.map((val) => val / norm).toList();
  }

  // Calculate Euclidean distance between two embeddings
  static double calculateDistance(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }

    double sum = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      final diff = embedding1[i] - embedding2[i];
      sum += diff * diff;
    }

    return sqrt(sum);
  }

  // Compare face with stored embeddings
  static String? matchFace(
    List<double> faceEmbedding,
    Map<String, List<double>> storedEmbeddings,
  ) {
    String? matchedId;
    double minDistance = double.infinity;

    storedEmbeddings.forEach((employeeId, storedEmbedding) {
      final distance = calculateDistance(faceEmbedding, storedEmbedding);

      if (distance < minDistance && distance < _threshold) {
        minDistance = distance;
        matchedId = employeeId;
      }
    });

    return matchedId;
  }

  // Calculate similarity percentage
  static double calculateSimilarity(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    final distance = calculateDistance(embedding1, embedding2);
    // Convert distance to similarity percentage (0-100)
    final similarity = max(0.0, (1 - (distance / 2)) * 100) as double;
    return similarity;
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

extension ListExtension<T> on List<T> {
  List<T> reshape(List<int> shape) {
    return this;
  }
}
