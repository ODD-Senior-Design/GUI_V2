// lib/widgets/history.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class HistorySection extends StatelessWidget {
  final List<dynamic> capturedImages;

  const HistorySection({Key? key, required this.capturedImages})
      : super(key: key);

  Uint8List _decodeBase64(String data) {
    final commaIndex = data.indexOf(',');
    final base64Str =
        commaIndex != -1 ? data.substring(commaIndex + 1) : data;
    return base64Decode(base64Str);
  }

  void _showImageDialog(BuildContext context, String base64Data) {
    final bytes = _decodeBase64(base64Data);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color.fromRGBO(0, 0, 0, 0.8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(bytes, fit: BoxFit.contain),
                const SizedBox(height: 20),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (capturedImages.isEmpty) {
      return const Center(child: Text("No history"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: capturedImages.length,
      itemBuilder: (context, index) {
        final item = capturedImages[index];
        final patient = item['image']['image_set']?['patient'];
        final base64Data = item['image']['base64'];
        if (patient == null || base64Data == null) {
          return const Center(child: Text("Invalid data received"));
        }
        final bytes = _decodeBase64(base64Data);

        return GestureDetector(
          onTap: () => _showImageDialog(context, base64Data),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${patient['first_name']} ${patient['last_name']}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  "Patient ID: ${patient['id']}",
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 89, 86, 86)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (ctx, err, stack) =>
                        const Center(child: Icon(Icons.error, color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
