import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static const String cloudName = 'dvztm9xyl';
  static const String uploadPreset = 'Employee';

  static Future<String> uploadEmployeeImage({
    required File image,
    required String employeeId,
  }) async {
    // Validate file exists
    if (!await image.exists()) {
      throw Exception('Image file does not exist');
    }

    // Check file size (e.g., max 10MB)
    final fileSize = await image.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('Image size exceeds 10MB limit');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final mimeType = lookupMimeType(image.path);
    if (mimeType == null) {
      throw Exception('Unable to determine image type');
    }

    final mimeTypeSplit = mimeType.split('/');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'employee/employees/$employeeId'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
        ),
      );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    
    debugPrint("Cloudinary response status: ${response.statusCode}");
    debugPrint("Cloudinary response body: $resBody");

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      final url = data['secure_url'];
      if (url == null || url.isEmpty) {
        throw Exception('Invalid URL received from Cloudinary');
      }
      return url;
    } else {
      throw Exception('Cloudinary upload failed (${response.statusCode}): $resBody');
    }
  }
}