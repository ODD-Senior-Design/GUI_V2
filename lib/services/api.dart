import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class ApiService {
  static const String apiBaseUrl = "https://api.ranga-family.com";

  static Future<List<dynamic>> capturePicture(BuildContext context) async {
    final String apiUrl = "$apiBaseUrl/generate/assessments?num=1";

    try {
      final url = Uri.parse(apiUrl);
      final response = await http.get(url, headers: {"Connection": "close"});

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image Captured Successfully!")));
        return jsonResponse;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An Error occurred: $e")));
    }
    return [];
  }
}
