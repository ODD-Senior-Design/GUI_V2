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

  static String get startSessionUrl => '$apiBaseUrl/image_sets';
  static String get capturePictureUrl => '$apiBaseUrl/images';
  static String get assessmentsUrl => '$apiBaseUrl/assessments';

  static dynamic _makeSerializable(dynamic value) {
    if (value is Set) return value.toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k, _makeSerializable(v)));
    if (value is Iterable && value is! String)
      return value.map(_makeSerializable).toList();
    return value;
  }

  /// Start a new image capture session for a patient.
  static Future<Map<String, dynamic>?> startSession(
      String patient_id, BuildContext ctx) async {
    final url = Uri.parse(startSessionUrl);
    final payload = jsonEncode({'patient_id': patient_id});
    debugPrint('POST $startSessionUrl → $payload');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to Start Session: ${response.statusCode} — ${response.body}',
              ),
            ),
          );
        }
        return null;
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('startSession error: $e');
      if (ctx.mounted) {
        String errMsg;
        if (e is SocketException) {
          errMsg = 'No network connection.';
        } else if (e is TimeoutException) {
          errMsg = 'Request timed out.';
        } else {
          errMsg = 'Error: $e';
        }
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(errMsg)),
        );
      }
      return null;
    }
  }

  /// 1) Capture pictures (`imageData` contains session and patient IDs)
  static Future<Map<String, dynamic>?> capturePicture(
      Map<String, dynamic> imageData, BuildContext context) async {
    final url = Uri.parse(capturePictureUrl);
    final payload = jsonEncode(imageData);
    debugPrint('POST $capturePictureUrl → $payload');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (context.mounted) {

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: Container(
                  height: 60,               // ↑ bump this up as you like
                  alignment: Alignment.centerLeft,
                child: Text('Captured Image Successfully!!',
                style: const TextStyle(fontSize: 18),),
                )
              ),
            );
          }
          return data;
        }
      if (response.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to Capture: ${response.statusCode} — ${response.body}',
              ),
            ),
          );
        }
        return null;
      }
    } catch (e) {
      debugPrint('Capture exception: $e');
      if (context.mounted) {
        String err = e is SocketException
            ? 'No network connection.'
            : e is TimeoutException
                ? 'Request timed out.'
                : 'Error: $e';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
      return null;
    }
    return null;
  }

  /// 2) Assess a single image via `/assessments`
  static Future<Map<String, dynamic>?> assessImage(
      Map<String, dynamic> payload, BuildContext context) async {
    final url = Uri.parse(assessmentsUrl);
    final body = jsonEncode(payload);
    debugPrint('POST $assessmentsUrl → [payload]');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (context.mounted) {
            // build the verdict string first
            final verdict = (data['assessment'] as bool) ? 'Positive' : 'Negative';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: Container(
                  height: 60,               // ↑ bump this up as you like
                  alignment: Alignment.centerLeft,
                child: Text('Assessed image; Verdict: $verdict',
                style: const TextStyle(fontSize: 18),),
                )
              ),
            );
          }
          return data;
        }

      if (response.statusCode != 200) {
        debugPrint(
            'Assessment failed ${response.statusCode}: ${response.body}');
        return null;
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Assessment exception: $e');
      return null;
    }
  }

  /// Submit new patient data, return the created patient object
  static Future<Map<String, dynamic>?> submitPatientData(
      Map<String, dynamic> patientData, BuildContext context) async {
    final apiUrl = '$apiBaseUrl/patients';
    debugPrint('Submitting patient to: $apiUrl');
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient Added Successfully!')),
          );
        }
        return data;
      } else {
        debugPrint(
          'submitPatientData failed: ${response.statusCode} — ${response.body}',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to Add Patient: ${response.statusCode} - ${response.body}',
              ),
            ),
          );
        }
        return null;
      }
    } catch (e) {
      debugPrint('submitPatientData error: $e');
      if (context.mounted) {
        String errMsg;
        if (e is SocketException) {
          errMsg = 'No network connection.';
        } else if (e is TimeoutException) {
          errMsg = 'Request timed out.';
        } else {
          errMsg = 'Error: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg)),
        );
      }
      return null;
    }
  }

  /// Fetch list of patients
  static Future<List<dynamic>> fetchPatients(BuildContext context) async {
    final apiUrl = '$apiBaseUrl/patients';
    debugPrint('Fetching patients from: $apiUrl');
    try {
      final url = Uri.parse(apiUrl);
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse.isEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No Patients Found')),
          );
        }
        return jsonResponse is List ? jsonResponse : [];
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to Fetch Patients: ${response.statusCode}',
              ),
            ),
          );
        }
        return [];
      }
    } catch (e) {
      debugPrint('fetchPatients error: $e');
      if (context.mounted) {
        String errMsg;
        if (e is SocketException) {
          errMsg = 'No network connection.';
        } else if (e is TimeoutException) {
          errMsg = 'Request timed out.';
        } else {
          errMsg = 'Error: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg)),
        );
      }
      return [];
    }
  }

  /// Fetch single patient by ID
  static Future<Map<String, dynamic>?> fetchPatientById(
      String patientId, BuildContext context) async {
    final apiUrl = '$apiBaseUrl/patients/$patientId';
    debugPrint('Fetching patient from: $apiUrl');
    try {
      final url = Uri.parse(apiUrl);
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to Fetch Patient: ${response.statusCode}',
              ),
            ),
          );
        }
        return null;
      }
    } catch (e) {
      debugPrint('fetchPatientById error: $e');
      if (context.mounted) {
        String errMsg;
        if (e is SocketException) {
          errMsg = 'No network connection.';
        } else if (e is TimeoutException) {
          errMsg = 'Request timed out.';
        } else {
          errMsg = 'Error: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg)),
        );
      }
      return null;
    }
  }
}
