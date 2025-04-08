import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screen/history_screen.dart';
import 'widgets/theme.dart';

void main() async {
  await dotenv.load(fileName: "/home/riofrio/ODD/oral_detection_device/.env");
  print('CAPTURE_API_URL: ${dotenv.env['CAPTURE_API_URL']}');
  print('SOCKET_IO_URL: ${dotenv.env['SOCKET_IO_URL']}');
  print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
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