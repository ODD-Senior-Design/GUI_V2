import 'package:flutter/material.dart';
import '/services/api.dart';

class PatientLookupScreen extends StatefulWidget {
  @override
  _PatientLookupScreenState createState() => _PatientLookupScreenState();
}

class _PatientLookupScreenState extends State<PatientLookupScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _patients = [];
  String _patientResult = '';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    List<dynamic> patients = await ApiService.fetchPatients(context);
    setState(() {
      _patients = patients;
    });
  }

  void _performSearch() {
    String query = _controller.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _patientResult = "Please enter a patient ID, first name, or last name.";
      });
      return;
    }

    var matches = _patients.where((patient) {
      String firstName = patient['first_name']?.toLowerCase() ?? '';
      String lastName = patient['last_name']?.toLowerCase() ?? '';
      String id = patient['id'] ?? '';

      // Match by first name, last name, or ID
      return firstName.contains(query) || lastName.contains(query) || id == query;
    }).toList();

    setState(() {
    if (matches.isNotEmpty) {
      _patientResult = matches
          .map((patient) => "${patient['first_name']} ${patient['last_name']} (ID: ${patient['id']})")
          .join("\n"); // Display all matches
    } else {
      _patientResult = "No matching patient found.";
    }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Patient Lookup", style: TextStyle(color: Colors.white))),
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

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: 'Enter Patient ID or Name'),
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: _performSearch,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(200, 60),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: TextStyle(fontSize: 18),
        backgroundColor: Color(0xFFF0F0F0),
      ),
      child: Text('Search'),
    );
  }

  Widget _buildPatientResult() {
    return _patientResult.isNotEmpty
        ? Text(
            _patientResult,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )
        : Container();
  }
}
