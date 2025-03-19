import 'package:flutter/material.dart';
import 'package:namer_app/widgets/theme.dart';
import '/widgets/app_bar.dart'; 
import '/widgets/capture.dart';
import '/widgets/history.dart';

class CameraHistoryPage extends StatefulWidget {
  @override
  _CameraHistoryPageState createState() => _CameraHistoryPageState();
}

class _CameraHistoryPageState extends State<CameraHistoryPage> {
  int _selectedIndex = 0;
  List<dynamic> _capturedImages = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void updateCapturedImages(List<dynamic> newImages) {
    setState(() {
      _capturedImages.addAll(newImages);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: oddRed,
      appBar: screenWidth >= 600 ? customAppBar(_onItemTapped, _selectedIndex) : null, // Hide app bar on small screens
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: _selectedIndex == 0
                  ? CaptureSection(updateCapturedImages: updateCapturedImages)
                  : HistorySection(capturedImages: _capturedImages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: screenWidth < 600
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Capture'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
              ],
            )
          : null,
    );
  }
}
