// lib/widgets/capture.dart

import 'package:flutter/material.dart';
import '/services/api.dart';
import '/widgets/theme.dart';
import '/screen/video_stream_page.dart';

class CaptureSection extends StatefulWidget {
  final Function(List<dynamic>) updateCapturedImages;

  const CaptureSection({super.key, required this.updateCapturedImages});

  @override
  _CaptureSectionState createState() => _CaptureSectionState();
}

class _CaptureSectionState extends State<CaptureSection> {
  String? _activePatientId;

  void _capturePicture(BuildContext context) async {
    // No arguments needed—API handles IDs internally
    List<dynamic> newImages = await ApiService.capturePicture(context);
    if (newImages.isNotEmpty) {
      widget.updateCapturedImages(newImages);
    }
  }

  void _showPatientForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Patient Information"),
          content: PatientForm(
            onSubmit: (patientData) async {
              final patientId =
                  await ApiService.submitPatientData(patientData, context);
              Navigator.of(context).pop();
              if (patientId != null && context.mounted) {
                setState(() => _activePatientId = patientId);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButtons(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          context,
          "Add Patient",
          () => _showPatientForm(context),
          w,
          h,
        ),
        SizedBox(width: w * 0.05),
        _buildActionButton(
          context,
          "Capture Picture",
          () => _capturePicture(context),
          w,
          h,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
    double screenWidth,
    double screenHeight,
  ) {
    return SizedBox(
      width: screenWidth * 0.25,
      height: screenHeight * 0.1,
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
          style: TextStyle(fontSize: (screenWidth * 0.03).clamp(16, 40)),
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

  Widget _buildLiveFeedContainer(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.all(15),
      width: w * 0.75,
      height: h * 0.55,
      color: const Color.fromARGB(0, 158, 158, 158),
      child: VideoStreamPage(activePatientId: _activePatientId),
    );
  }
}

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
    final w = MediaQuery.of(context).size.width;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField("First Name", (v) => _firstName = v ?? ''),
          _buildTextField("Last Name", (v) => _lastName = v ?? ''),
          _buildDOBField(),
          _buildGenderDropdown(),
          _buildSubmitButton(context, w),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(labelText: label, hintText: 'Enter $label'),
      onSaved: onSaved,
      validator: (v) => (v == null || v.isEmpty) ? 'Please enter $label' : null,
    );
  }

  Widget _buildDOBField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        hintText: _dob == null
            ? 'Select DOB'
            : _dob!.toLocal().toString().split(' ')[0],
      ),
      controller: TextEditingController(
          text: _dob == null ? '' : _dob!.toLocal().toString().split(' ')[0]),
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _dob = picked);
      },
      validator: (_) => _dob == null ? 'Please select a date of birth' : null,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender.isEmpty ? null : _gender,
      onChanged: (v) => setState(() => _gender = v ?? ''),
      items: ['Male', 'Female']
          .map((sex) => DropdownMenuItem(value: sex, child: Text(sex)))
          .toList(),
      decoration: const InputDecoration(labelText: 'Sex', hintText: 'Select Option'),
    );
  }

  void _handleSubmit() {
    if ((_formKey.currentState?.validate() ?? false)) {
      _formKey.currentState?.save();
      widget.onSubmit({
        'first_name': _firstName,
        'last_name': _lastName,
        'dob': _dob?.toIso8601String(),
        'sex': _gender,
      });
    }
  }

  Widget _buildSubmitButton(BuildContext context, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: screenWidth * 0.15,
        height: screenWidth * 0.05,
        child: ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: utsaOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          ),
          child: Text(
            "Submit",
            style: TextStyle(fontSize: (screenWidth * 0.05).clamp(14, 24)),
          ),
        ),
      ),
    );
  }
}
