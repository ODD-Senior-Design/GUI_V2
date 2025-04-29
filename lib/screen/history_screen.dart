// lib/screen/history_screen.dart

import 'package:flutter/material.dart';
import 'package:namer_app/screen/patient_lookup_screen.dart';
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
      _capturedImages.insertAll(0, newImages);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: oddRed,
      appBar: screenWidth >= 600
          ? customAppBar(_onItemTapped, _selectedIndex)
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(child: _getBodyContent()),
          ],
        ),
      ),
      bottomNavigationBar: screenWidth < 600
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.camera), label: 'Capture'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.history), label: 'History'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.search), label: 'Search'),
              ],
            )
          : null,
    );
  }

  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return CaptureSection(updateCapturedImages: updateCapturedImages);
      case 1:
        return HistorySection(capturedImages: _capturedImages);
      case 2:
      default:
        return PatientLookupScreen();
    }
  }
}
