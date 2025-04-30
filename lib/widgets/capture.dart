// lib/widgets/capture.dart

import 'package:flutter/material.dart';
import '/services/api.dart';
import '/widgets/theme.dart';
import '/screen/video_stream_page.dart';

class CaptureSection extends StatefulWidget {
  final Function(List<dynamic>) updateCapturedImages;

  const CaptureSection({Key? key, required this.updateCapturedImages})
      : super(key: key);

  @override
  State<CaptureSection> createState() => _CaptureSectionState();
}

class _CaptureSectionState extends State<CaptureSection> {
  String? _activePatientId;

  /// 1) Capture images, 2) run AI assess on each, 3) return the list
  Future<void> _captureAndAssess(BuildContext context) async {
    final images = await ApiService.capturePicture(context);
    if (images.isEmpty) return;

    for (var item in images) {
      final b64 = item['image']?['base64'];
      if (b64 != null) {
        final result = await ApiService.assessImage(b64, context);
        item['assessment'] = result;
      }
    }

    widget.updateCapturedImages(images);
  }

  /// Show the “Add Patient” dialog
  void _showPatientForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Patient Information"),
        content: PatientForm(onSubmit: (patientData) async {
          final id =
              await ApiService.submitPatientData(patientData, context);
          Navigator.of(context).pop();
          if (id != null && context.mounted) {
            setState(() => _activePatientId = id);
          }
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLiveFeedContainer(context),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add Patient button
              _actionButton(
                context,
                "Add Patient",
                () => _showPatientForm(context),  // <-- wrapped
                w,
                h,
              ),
              SizedBox(width: w * 0.05),
              // Capture & Assess button
              _actionButton(
                context,
                "Capture & Assess",
                () => _captureAndAssess(context),  // <-- wrapped
                w,
                h,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,         // now a true VoidCallback
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          padding: const EdgeInsets.all(8),
        ),
        onPressed: onPressed,       // matches VoidCallback
        child: Text(
          label,
          style: TextStyle(
            fontSize: (screenWidth * 0.03).clamp(16, 40),
          ),
        ),
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

  const PatientForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<PatientForm> createState() => _PatientFormState();
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
          TextFormField(
            decoration: const InputDecoration(
                labelText: 'First Name', hintText: 'Enter First Name'),
            onSaved: (v) => _firstName = v ?? '',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter First Name' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(
                labelText: 'Last Name', hintText: 'Enter Last Name'),
            onSaved: (v) => _lastName = v ?? '',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter Last Name' : null,
          ),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              hintText: _dob == null
                  ? 'Select DOB'
                  : _dob!.toLocal().toString().split(' ')[0],
            ),
            controller: TextEditingController(
                text: _dob == null
                    ? ''
                    : _dob!.toLocal().toString().split(' ')[0]),
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
            validator: (_) =>
                _dob == null ? 'Please select a date of birth' : null,
          ),
          DropdownButtonFormField<String>(
            value: _gender.isEmpty ? null : _gender,
            onChanged: (v) => setState(() => _gender = v ?? ''),
            items: ['Male', 'Female']
                .map((sex) => DropdownMenuItem(
                    value: sex,
                    child: Text(sex)))
                .toList(),
            decoration: const InputDecoration(
              labelText: 'Sex',
              hintText: 'Select Option',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: SizedBox(
              width: w * 0.15,
              height: w * 0.05,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    widget.onSubmit({
                      'first_name': _firstName,
                      'last_name': _lastName,
                      'dob': _dob?.toIso8601String(),
                      'sex': _gender,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: utsaOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)),
                ),
                child: Text(
                  "Submit",
                  style:
                      TextStyle(fontSize: (w * 0.05).clamp(14, 24)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
