import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'dart:io';
import 'dart:async';

class ApiService {
  static String get apiBaseUrl => dotenv.dotenv.isInitialized
      ? dotenv.dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000'
      : 'http://localhost:5000';

  static String get capturePictureUrl => dotenv.dotenv.isInitialized
      ? dotenv.dotenv.env['CAPTURE_PICTURE_URL'] ?? 'http://localhost:5000/images'
      : 'http://localhost:5000/images';

  static String get socketIoUrl => dotenv.dotenv.isInitialized
      ? dotenv.dotenv.env['SOCKET_IO_URL'] ?? 'http://localhost:3000/stream'
      : 'http://localhost:3000/stream';

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

  static Future<List<dynamic>> capturePicture(BuildContext context, {String? patientId}) async {
    debugPrint('Using capturePictureUrl: $capturePictureUrl');
    try {
      final url = Uri.parse(capturePictureUrl);
      final payload = {
        'set_id': null, 
        'patient_id': patientId,
      };
      debugPrint('Capture payload: $payload');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
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

  static Future<String?> submitPatientData(
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
        // Extract patient ID from response
        final responseData = jsonDecode(response.body);
        final patientId = responseData['id']?.toString() ?? responseData['patient_id']?.toString();
        debugPrint('Patient ID: $patientId');
        return patientId;
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
        return null;
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
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchPatientById(String patientId, BuildContext context) async {
    final apiUrl = '$apiBaseUrl/patients/$patientId';
    debugPrint('Fetching patient from: $apiUrl');
    try {
      final url = Uri.parse(apiUrl);
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final patient = jsonDecode(response.body);
        debugPrint('Patient fetched: $patient');
        return patient;
      } else {
        debugPrint('Error response body: ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to Fetch Patient: ${response.statusCode}')),
          );
        }
        return null;
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
      return null;
    }
  }
}