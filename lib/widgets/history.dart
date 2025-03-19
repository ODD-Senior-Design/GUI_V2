import 'package:flutter/material.dart';

class HistorySection extends StatelessWidget {
  final List<dynamic> capturedImages;

  const HistorySection({super.key, required this.capturedImages});

  // Function to show enlarged image in a pop-out dialog
  void _showImageDialog(BuildContext context, String imageUri) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Color.fromRGBO(0, 0, 0, 0.8), 
          child: _buildImageDialogContent(imageUri, context),
        );
      },
    );
  }

  // Widget to handle image dialog
  Widget _buildImageDialogContent(String imageUri, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogImage(imageUri),
          SizedBox(height: 20),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  // Widget to display the image in the dialog
  Widget _buildDialogImage(String imageUri) {
    return Image.network(
      imageUri,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(child: Icon(Icons.error, color: Colors.red));
      },
    );
  }

  // Widget to build the close button in the dialog
  Widget _buildCloseButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.close, color: Colors.white, size: 30),
      onPressed: () {
        Navigator.of(context).pop(); // Close the dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return capturedImages.isEmpty
        ? Center(child: Text("No history"))
        : _buildGridView(context);
  }

  // Widget to build the GridView
  Widget _buildGridView(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: capturedImages.length,
      itemBuilder: (context, index) {
        final imageItem = capturedImages[index];
        final patient = imageItem['image']['image_set']?['patient'];
        final imageUri = imageItem['image']['uri'];

        if (patient == null || imageUri == null) {
          return Center(child: Text("Invalid data received"));
        }

        return _buildImagePreview(context, imageUri, patient);
      },
    );
  }

  // Widget to build each image preview in the GridView
  Widget _buildImagePreview(BuildContext context, String imageUri, dynamic patient) {
    return GestureDetector(
      onTap: () => _showImageDialog(context, imageUri), // Trigger dialog on tap
      child: Container(
        margin: EdgeInsets.only(bottom: 30, right: 10, left: 10),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("${patient['first_name']} ${patient['last_name']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40)),
            SizedBox(height: 4),
            Text("Patient ID: ${patient['id']}", style: TextStyle(fontSize: 25, color: const Color.fromARGB(255, 89, 86, 86))),
            SizedBox(height: 8),
            _buildImagePreviewThumbnail(imageUri),
          ],
        ),
      ),
    );
  }

  // Widget to build the image thumbnail in the GridView
  Widget _buildImagePreviewThumbnail(String imageUri) {
    return Image.network(
      imageUri,
      width: 650, // Adjudt image size
      height: 650, 
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) =>
          loadingProgress == null ? child : Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.error, color: Colors.red)),
    );
  }
}
