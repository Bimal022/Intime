import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'models/facenet.tflite',
    );
  }

  List<double> generateEmbedding(img.Image faceImage) {
    final resized = img.copyResize(faceImage, width: 112, height: 112);

    final input = Float32List(1 * 112 * 112 * 3);
    int i = 0;

    for (var y = 0; y < 112; y++) {
      for (var x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);
        input[i++] = (pixel.r - 128) / 128;
        input[i++] = (pixel.g - 128) / 128;
        input[i++] = (pixel.b - 128) / 128;
      }
    }

    final output = List.filled(1 * 128, 0.0).reshape([1, 128]);
    _interpreter.run(input.reshape([1, 112, 112, 3]), output);

    return List<double>.from(output[0]);
  }

  double euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }
}
