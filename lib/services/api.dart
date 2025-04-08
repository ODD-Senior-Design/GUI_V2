import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'https://api.ranga-family.com';
  static String get captureApiUrl => dotenv.env['CAPTURE_API_URL'] ?? 'http://192.168.157.225:3000/capture';

  static Future<List<dynamic>> capturePicture(BuildContext context) async {
    debugPrint('Using captureApiUrl: $captureApiUrl');
    try {
      final url = Uri.parse(captureApiUrl);
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Connection": "close",
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image Captured Successfully!")),
        );
        return jsonResponse;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to Capture Image: ${response.statusCode}")),
        );
        return [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An Error occurred: $e")),
      );
      return [];
    }
  }

  static Future<List<dynamic>> fetchPatients(BuildContext context) async {
    final String apiUrl = "$apiBaseUrl/patients";

    try {
      final url = Uri.parse(apiUrl);
      final response = await http.get(url, headers: {"Connection": "close"});

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An Error occurred: $e")),
      );
    }
    return [];
  }

  static Future<void> submitPatientData(Map<String, dynamic> patientData, BuildContext context) async {
    final String apiUrl = "$apiBaseUrl/patients";

    try {
      final url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(patientData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient Added Successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to Add Patient")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An Error occurred: $e")),
      );
    }
  }
}