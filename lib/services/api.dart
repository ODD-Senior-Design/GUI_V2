import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'dart:io';
import 'dart:async';

class ApiService {
  static String get apiBaseUrl => dotenv.dotenv.isInitialized
      ? dotenv.dotenv.env['API_BASE_URL'] ?? 'https://api.ranga-family.com'
      : 'https://api.ranga-family.com';

  static String get capturePictureUrl => dotenv.dotenv.isInitialized
      ? dotenv.dotenv.env['CAPTURE_PICTURE_URL'] ?? 'http://host.docker.internal:3000/images'
      : 'http://host.docker.internal:3000/images';

  static String get socketIoUrl => dotenv.dotenv.isInitialized
      ? dotenv.dotenv.env['SOCKET_IO_URL'] ?? 'http://host.docker.internal:3000/stream'
      : 'http://host.docker.internal:3000/stream';

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
      debugPrint('Capture error: $e');
      if (context.mounted) {
        String errorMessage = 'Capture Error: $e';
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
    debugPrint('Fetching patients from: $apiUrl');
    try {
      final url = Uri.parse(apiUrl);
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Response body: ${response.body}');
        if (jsonResponse.isEmpty) {
          debugPrint('No patients returned');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No Patients Found')),
            );
          }
        }
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
      debugPrint('Fetch error: $e');
      if (context.mounted) {
        String errorMessage = 'Fetch Error: $e';
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
    debugPrint('Submitting to: $apiUrl');
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

      if (response.statusCode == 200 || response.statusCode == 201) {
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
      debugPrint('Submit error: $e');
      if (context.mounted) {
        String errorMessage = 'Submit Error: $e';
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