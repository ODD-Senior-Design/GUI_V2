import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'screen/history_screen.dart';
import 'widgets/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.dotenv.load(fileName: '/home/riofrio/ODD/oral_detection_device/.env');
    debugPrint('Loaded .env: ${dotenv.dotenv.env}');
  } catch (e, stackTrace) {
    debugPrint('Failed to load .env: $e\n$stackTrace');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O.D.D. Guard',
      theme: customTheme,
      home: CameraHistoryPage(),
    );
  }
}