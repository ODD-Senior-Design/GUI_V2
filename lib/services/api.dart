import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'dart:io';
class ApiService {
  static String get apiBaseUrl => dotenv.dotenv.isInitialized
      ? dotenv.dotenv.env['API_BASE_URL'] ?? 'https://api.ranga-family.com'
      : 'https://api.ranga-family.com';  

  static String get socketIoUrl => dotenv.dotenv.isInitialized
      ? dotenv.dotenv.env['SOCKET_IO_URL'] ?? 'http://172.20.10.5:3000/stream'
      : 'http://172.20.10.5:3000/stream';  


  static Future<List<dynamic>> capturePicture(BuildContext context) async {
    debugPrint('Using apiBaseUrl: $apiBaseUrl');
    try {
      final url = Uri.parse('$apiBaseUrl/images');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Connection": "close",
        },
   
        body: jsonEncode({
          'patient_id': '9f3f7241-41d2-4d19-8ad3-42579faaba13',
          'set_id': 'eaf09650-210a-4cb8-8653-aa97461b338d'
        }),
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
