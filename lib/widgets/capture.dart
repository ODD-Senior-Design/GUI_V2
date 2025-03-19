import 'package:flutter/material.dart';
import '/services/api.dart';
import '/widgets/theme.dart';

class CaptureSection extends StatelessWidget {
  final Function(List<dynamic>) updateCapturedImages;

  const CaptureSection({super.key, required this.updateCapturedImages});

  void _capturePicture(BuildContext context) async {
    List<dynamic> newImages = await ApiService.capturePicture(context);
    if (newImages.isNotEmpty) {
      updateCapturedImages(newImages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.all(15),
            width: 1200,
            height: 600,
            color: Colors.grey,
            child: Center(
              child: Text("Live Feed", style: TextStyle(color: Colors.white, fontSize: 50.0)),
            ),
          ),
          SizedBox(
            width: 800,
            height: 100,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: utsaOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              onPressed: () => _capturePicture(context),
              child: Text("Capture Picture", style: TextStyle(fontSize: 50.0)),
            ),
          ),
        ],
      ),
    );
  }
}
