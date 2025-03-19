import 'package:flutter/material.dart';
import 'screen/history_screen.dart';
import 'widgets/theme.dart';

void main() {
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
