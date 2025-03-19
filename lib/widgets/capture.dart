import 'package:flutter/material.dart';
import '/services/api.dart';
import '/widgets/theme.dart';

class CaptureSection extends StatelessWidget {
  final Function(List<dynamic>) updateCapturedImages;

  const CaptureSection({super.key, required this.updateCapturedImages});

  // Capture picture functionality
  void _capturePicture(BuildContext context) async {
    List<dynamic> newImages = await ApiService.capturePicture(context);
    if (newImages.isNotEmpty) {
      updateCapturedImages(newImages);
    }
  }

  // Show patient form dialog
  void _showPatientForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Patient Information"),
          content: PatientForm(),
          actions: _buildDialogActions(context),
        );
      },
    );
  }

  // Building the dialog actions
  List<Widget> _buildDialogActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text("Cancel"),
      ),
      ElevatedButton(
        onPressed: () {
          // Handle form submission logic here
          Navigator.of(context).pop();
        },
        child: Text("Submit"),
      ),
    ];
  }

  // Building the buttons
  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton("Add Patient", () => _showPatientForm(context)),
        SizedBox(width: 20), // Space between buttons
        _buildActionButton("Capture Picture", () => _capturePicture(context)),
      ],
    );
  }

  // Button styling
  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 350,
      height: 100,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: utsaOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: TextStyle(fontSize: 40.0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLiveFeedContainer(),
          _buildButtons(context),
        ],
      ),
    );
  }

  // Live feed container
  Widget _buildLiveFeedContainer() {
    return Container(
      margin: EdgeInsets.all(15),
      width: 1200,
      height: 600,
      color: Colors.grey,
      child: Center(
        child: Text("Live Feed", style: TextStyle(color: Colors.white, fontSize: 50.0)),
      ),
    );
  }
}

// Patient Form Widget
class PatientForm extends StatefulWidget {
  @override
  _PatientFormState createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  DateTime _dob = DateTime.now();
  String _gender = 'Male';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField("First Name", (value) => _firstName = value ?? ''),
          _buildTextField("Last Name", (value) => _lastName = value ?? ''),
          _buildTextField("Date of Birth", (value) {
            if (value != null) _dob = DateTime.parse(value);
          }),
          _buildGenderDropdown(),
        ],
      ),
    );
  }

  // Common text field builder
  Widget _buildTextField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      onSaved: onSaved,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  // Gender dropdown builder
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      onChanged: (value) {
        setState(() {
          _gender = value ?? 'Male';
        });
      },
      items: ['Male', 'Female'].map((String gender) {
        return DropdownMenuItem<String>(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      decoration: InputDecoration(labelText: 'Gender'),
    );
  }
}
