import 'package:flutter/material.dart';
import '/services/api.dart';
import 'dart:math' show max;

class PatientLookupScreen extends StatefulWidget {
  @override
  _PatientLookupScreenState createState() => _PatientLookupScreenState();
}

class _PatientLookupScreenState extends State<PatientLookupScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _patients = [];
  String _patientResult = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> patients = await ApiService.fetchPatients(context);
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _patientResult = "Error fetching patients: $e";
      });
    }
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
      String id = patient['id']?.toString() ?? '';
      return firstName.contains(query) || lastName.contains(query) || id == query;
    }).toList();

    setState(() {
      _patientResult = matches.isNotEmpty
          ? matches
              .map((patient) =>
                  "${patient['first_name']} ${patient['last_name']} (ID: ${patient['id']})")
              .join("\n")
          : "No matching patient found.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Lookup", style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTextField(screenWidth),
                  SizedBox(height: screenHeight * 0.02),
                  _buildSearchButton(screenWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.02),
                  _buildPatientResult(),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(double screenWidth) {
    return Semantics(
      label: 'Patient ID or Name input',
      child: TextField(
        controller: _controller,
        style: TextStyle(fontSize: 20),
        decoration: InputDecoration(
          labelText: 'Enter Patient ID or Name',
          labelStyle: TextStyle(fontSize: 20),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(width: 2),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, size: 24),
            onPressed: () {
              _controller.clear();
              setState(() => _patientResult = '');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton(double screenWidth, double screenHeight) {
    return ElevatedButton(
      onPressed: _performSearch,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(screenWidth * 0.6, max(screenHeight * 0.08, 60)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        textStyle: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      child: Text('Search', semanticsLabel: 'Search button'),
    );
  }

  Widget _buildPatientResult() {
    return _patientResult.isNotEmpty
        ? Expanded(
            child: SingleChildScrollView(
              child: Text(
                _patientResult,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
          )
        : Container();
  }
}