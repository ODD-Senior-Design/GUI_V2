import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'screen/history_screen.dart';
import 'widgets/theme.dart';

void main() async {
  // Try loading .env for local development, fall back to --dart-define
  try {
    await dotenv.dotenv.load(fileName: "/home/riofrio/ODD/oral_detection_device/.env");
  } catch (e) {
    print('No .env file found, using --dart-define: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O.D.D. Guard',
      theme: customTheme,
      home: CameraHistoryPage(),
    );
  }
}