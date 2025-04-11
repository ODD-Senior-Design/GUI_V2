import 'package:flutter/material.dart';
import '/services/api.dart';
import '/widgets/theme.dart';
import '/screen/video_stream_page.dart';

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
          title: const Text("Patient Information"),
          content: PatientForm(
            onSubmit: (patientData) {
              ApiService.submitPatientData(patientData, context);
              Navigator.of(context).pop();
            },
          ),
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
        child: const Text("Cancel"),
      ),
    ];
  }

  // Building the buttons
  Widget _buildButtons(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          context,
          "Add Patient",
          () => _showPatientForm(context),
          screenWidth,
          screenHeight,
        ),
        SizedBox(width: screenWidth * 0.05), // 5% of screen width
        _buildActionButton(
          context,
          "Capture Picture",
          () => _capturePicture(context),
          screenWidth,
          screenHeight,
        ),
      ],
    );
  }

  // Button styling
  Widget _buildActionButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
    double screenWidth,
    double screenHeight,
  ) {
    return SizedBox(
      width: screenWidth * 0.25, // 25% of screen width
      height: screenHeight * 0.1, // 10% of screen height
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: utsaOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          padding: const EdgeInsets.all(8),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: (screenWidth * 0.03).clamp(16, 40), // 5% of width, min 16px, max 40px
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLiveFeedContainer(context),
          const SizedBox(height: 20),
          _buildButtons(context),
        ],
      ),
    );
  }

  // Live feed container
  Widget _buildLiveFeedContainer(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double containerWidth = screenWidth * 0.75;
    double containerHeight = screenHeight * 0.55;

    return Container(
      margin: const EdgeInsets.all(15),
      width: containerWidth,
      height: containerHeight,
      color: const Color.fromARGB(0, 158, 158, 158),
      child: const VideoStreamPage(),
    );
  }
}

// Patient Form Widget
class PatientForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const PatientForm({super.key, required this.onSubmit});

  @override
  _PatientFormState createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  DateTime? _dob;
  String _gender = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField("First Name", (value) => _firstName = value ?? ''),
          _buildTextField("Last Name", (value) => _lastName = value ?? ''),
          _buildDOBField(),
          _buildGenderDropdown(),
          _buildSubmitButton(context, screenWidth),
        ],
      ),
    );
  }

  // Common text field builder
  Widget _buildTextField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter $label',
      ),
      onSaved: onSaved,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  // Date of Birth field
  Widget _buildDOBField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        hintText: _dob == null ? 'Select DOB' : _dob!.toLocal().toString().split(' ')[0],
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            _dob = pickedDate;
          });
        }
      },
      controller: TextEditingController(
          text: _dob == null ? '' : _dob!.toLocal().toString().split(' ')[0]),
      readOnly: true,
      validator: (value) {
        if (_dob == null) {
          return 'Please select a date of birth';
        }
        return null;
      },
    );
  }

  // Gender dropdown
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender.isEmpty ? null : _gender,
      onChanged: (value) {
        setState(() {
          _gender = value ?? '';
        });
      },
      items: ['Male', 'Female'].map((String sex) {
        return DropdownMenuItem<String>(
          value: sex,
          child: Text(sex),
        );
      }).toList(),
      decoration: const InputDecoration(
        labelText: 'Sex',
        hintText: 'Select Option',
      ),
    );
  }

  // Handle form submission
  void _handleSubmit() {
    final formState = _formKey.currentState;
    if (formState?.validate() ?? false) {
      formState?.save();
      Map<String, dynamic> patientData = {
        'first_name': _firstName,
        'last_name': _lastName,
        'dob': _dob?.toIso8601String(),
        'sex': _gender,
      };
      widget.onSubmit(patientData);
    }
  }

  // Submit button for the form
  Widget _buildSubmitButton(BuildContext context, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: screenWidth * 0.15, // 15% of screen width
        height: screenWidth * 0.05, // Scales with width
        child: ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: utsaOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: Text(
            "Submit",
            style: TextStyle(
              fontSize: (screenWidth * 0.05).clamp(14, 24), // 5% of width, min 14px, max 24px
            ),
          ),
        ),
      ),
    );
  }
}