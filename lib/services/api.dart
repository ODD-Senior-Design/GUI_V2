import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'dart:io'; 
import 'dart:async'; 

class ApiService {
  static String get apiBaseUrl =>
      dotenv.dotenv.env['API_BASE_URL'] ?? 'https://api.ranga-family.com';

  static String get socketIoUrl =>
      dotenv.dotenv.env['SOCKET_IO_URL'] ?? 'http://172.20.10.5:3000/stream';

  static String get capturePictureUrl =>
      dotenv.dotenv.env['CAPTURE_PICTURE_URL'] ?? 'http://172.20.10.5:3000/images';


  // Utility function to convert Sets to Lists
  static dynamic _makeSerializable(dynamic value) {
    if (value is Set) {
      return value.toList();
    } else if (value is Map) {
      return value.map((key, val) => MapEntry(key, _makeSerializable(val)));
    } else if (value is List) {
      return value.map(_makeSerializable).toList();
    } else if (value is Iterable && value is! String) {
      return value.map(_makeSerializable).toList();
    }
    return value;
  }

  static Future<List<dynamic>> capturePicture(BuildContext context) async {
    debugPrint('Using capturePictureUrl: $capturePictureUrl');
    try {
      final url = Uri.parse(capturePictureUrl);
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'set_id': 'eaf09650-210a-4cb8-8653-aa97461b338d',
              'patient_id': '9f3f7241-41d2-4d19-8ad3-42579faaba13',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Response body: ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image Captured Successfully!')),
          );
        }
        // Handle both List and Map responses
        return jsonResponse is List
            ? jsonResponse
            : jsonResponse is Map
                ? [jsonResponse]
                : [];
      } else {
        debugPrint('Error response body: ${response.body}');
        if (context.mounted) {
          String errorMessage =
              'Failed to Capture Image: ${response.statusCode}';
          if (response.body.isNotEmpty) {
            errorMessage += ' (${response.body.substring(0, response.body.length.clamp(0, 50))})';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
        return [];
      }
    } catch (e) {
      debugPrint('Exception: $e');
      if (context.mounted) {
        String errorMessage = 'An Error occurred: $e';
        if (e is SocketException) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (e is TimeoutException) {
          errorMessage = 'Request timed out. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      return [];
    }
  }

  static Future<List<dynamic>> fetchPatients(BuildContext context) async {
    final apiUrl = '$apiBaseUrl/patients';

    try {
      final url = Uri.parse(apiUrl);
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Response body: ${response.body}');
        return jsonResponse is List ? jsonResponse : [];
      } else {
        debugPrint('Error response body: ${response.body}');
        if (context.mounted) {
          String errorMessage = 'Failed to Fetch Patients: ${response.statusCode}';
          if (response.body.isNotEmpty) {
            errorMessage += ' (${response.body.substring(0, response.body.length.clamp(0, 50))})';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
        return [];
      }
    } catch (e) {
      debugPrint('Exception: $e');
      if (context.mounted) {
        String errorMessage = 'An Error occurred: $e';
        if (e is SocketException) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (e is TimeoutException) {
          errorMessage = 'Request timed out. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      return [];
    }
  }

  static Future<void> submitPatientData(
      Map<String, dynamic> patientData, BuildContext context) async {
    final apiUrl = '$apiBaseUrl/patients';

    try {
      final serializableData = _makeSerializable(patientData);
      debugPrint('Serialized patientData: $serializableData');

      final url = Uri.parse(apiUrl);
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(serializableData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient Added Successfully!')),
          );
        }
      } else {
        debugPrint('Error response body: ${response.body}');
        if (context.mounted) {
          String errorMessage = 'Failed to Add Patient: ${response.statusCode}';
          if (response.body.isNotEmpty) {
            errorMessage += ' (${response.body.substring(0, response.body.length.clamp(0, 50))})';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception: $e');
      if (context.mounted) {
        String errorMessage = 'An Error occurred: $e';
        if (e is SocketException) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (e is TimeoutException) {
          errorMessage = 'Request timed out. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }
}