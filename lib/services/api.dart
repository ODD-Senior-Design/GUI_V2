// lib/services/api.dart

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
    if (value is Set) return value.toList();
    if (value is Map) return value.map((k, v) => MapEntry(k, _makeSerializable(v)));
    if (value is Iterable && value is! String) return value.map(_makeSerializable).toList();
    return value;
  }

  /// Capture picture.
  /// Sends an empty JSON {} so backend can generate both set_id and patient_id.
  static Future<List<dynamic>> capturePicture(BuildContext context) async {
    final url = Uri.parse(capturePictureUrl);
    final payload = jsonEncode({});                      // <-- empty JSON
    debugPrint('📤 POST to $capturePictureUrl');
    debugPrint('📦 Request body: $payload');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📄 Body: ${response.body}');

      if (response.statusCode != 200) {
        final body = response.body;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to Capture Image: ${response.statusCode} — $body')),
          );
        }
        return [];
      }

      final rawData = jsonDecode(response.body);
      final items = rawData is List ? rawData : [rawData];
      final withBase64 = <dynamic>[];

      for (var item in items) {
        final uriString = item['image']?['uri'];
        if (uriString != null) {
          try {
            final imgResp = await http.get(Uri.parse(uriString));
            if (imgResp.statusCode == 200) {
              final b64 = base64Encode(imgResp.bodyBytes);
              item['image']['base64'] = 'data:image/png;base64,$b64';
            }
          } catch (e) {
            debugPrint('Error fetching image bytes: $e');
          }
        }
        withBase64.add(item);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Image Captured Successfully!')));
      }
      return withBase64;
    } catch (e) {
      debugPrint('⚠️ Capture error: $e');
      if (context.mounted) {
        String err = 'Capture Error: $e';
        if (e is SocketException) {
          err = 'No Internet connection. Please check your network.';
        } else if (e is TimeoutException) {
          err = 'Request timed out. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
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
        if (jsonResponse.isEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No Patients Found')),
          );
        }
        return jsonResponse is List ? jsonResponse : [];
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to Fetch Patients: ${response.statusCode}')),
          );
        }
        return [];
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      if (context.mounted) {
        String err = 'Fetch Error: $e';
        if (e is SocketException) {
          err = 'No Internet connection. Please check your network.';
        } else if (e is TimeoutException) {
          err = 'Request timed out. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return [];
    }
  }

  static Future<String?> submitPatientData(
    Map<String, dynamic> patientData,
    BuildContext context,
  ) async {
    final apiUrl = '$apiBaseUrl/patients';
    debugPrint('Submitting to: $apiUrl');
    try {
      final serializableData = _makeSerializable(patientData);
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
        final data = jsonDecode(response.body);
        return data['id']?.toString() ?? data['patient_id']?.toString();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to Add Patient: ${response.statusCode}')),
          );
        }
        return null;
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      if (context.mounted) {
        String err = 'Submit Error: $e';
        if (e is SocketException) {
          err = 'No Internet connection. Please check your network.';
        } else if (e is TimeoutException) {
          err = 'Request timed out. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchPatientById(
    String patientId,
    BuildContext context,
  ) async {
    final apiUrl = '$apiBaseUrl/patients/$patientId';
    debugPrint('Fetching patient from: $apiUrl');
    try {
      final url = Uri.parse(apiUrl);
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to Fetch Patient: ${response.statusCode}')),
          );
        }
        return null;
      }
    } catch (e) {
      debugPrint('Fetch by ID error: $e');
      if (context.mounted) {
        String err = 'Fetch Error: $e';
        if (e is SocketException) {
          err = 'No Internet connection. Please check your network.';
        } else if (e is TimeoutException) {
          err = 'Request timed out. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return null;
    }
  }
}
