import 'package:flutter/material.dart';

class PatientLookupScreen extends StatefulWidget {
  @override
  _PatientLookupScreenState createState() => _PatientLookupScreenState();
}

class _PatientLookupScreenState extends State<PatientLookupScreen> {
  final TextEditingController _controller = TextEditingController();
  String _patientResult = '';  // To hold the search result

  void _performSearch() {
    setState(() {
      _patientResult = "Found patient: ${_controller.text}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Patient Lookup")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(),
            SizedBox(height: 20),
            _buildSearchButton(),
            SizedBox(height: 20),
            _buildPatientResult(),
          ],
        ),
      ),
    );
  }

  // TextField
  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: 'Enter Patient ID or Name'),
    );
  }

  // Search Button
  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: _performSearch,
      child: Text('Search'),
    );
  }

  // Displaying the result
  Widget _buildPatientResult() {
    if (_patientResult.isNotEmpty) {
      return Text(
        _patientResult,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
    }
    return Container();  // Return an empty container if no result
  }
}
