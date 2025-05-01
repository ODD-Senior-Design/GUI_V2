// lib/widgets/capture.dart

import 'package:flutter/material.dart';
import '/services/api.dart';
import '/widgets/theme.dart';
import '/screen/video_stream_page.dart';

/// A section widget that handles selecting/adding a patient, capturing images,
/// performing AI assessment, and returning the results to its parent.
class CaptureSection extends StatefulWidget {
  /// Callback to send captured images (with assessments) back to parent
  final Function(List<dynamic>) updateCapturedImages;

  const CaptureSection({super.key, required this.updateCapturedImages});

  @override
  State<CaptureSection> createState() => _CaptureSectionState();
}

class _CaptureSectionState extends State<CaptureSection> {
  /// Currently selected patient ID (null if none chosen)
  String? _activePatientId;

  /// Current session/set ID for grouping captures (resets with new patient)
  String? _activeSetId;

  /// 1) Ensure a patient is selected, 2) start session if needed,
  /// 3) capture images from API, 4) run AI assessments, 5) return list
  Future<void> _captureAndAssess(BuildContext ctx) async {
    // Log tap event and check patient
    debugPrint('Capture tapped; patient=$_activePatientId');
    if (_activePatientId == null) {
      // Prompt user to add/select a patient first
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Please add or select a patient first')),
      );
      return;
    }

    // Start a new session if this is the first capture
    if (_activeSetId == null) {
      final session = await ApiService.startSession(_activePatientId!, ctx);
      debugPrint(session.toString());
      if (session == null) return;
      setState(() {
        _activeSetId = session['id'].toString();
      });
    }

    // Build payload for capture API
    final payload = {
      'patient_id': _activePatientId,
      'set_id': _activeSetId,
    };

    // Perform image capture
    final images = await ApiService.capturePicture(payload, ctx);
    if (images.isEmpty) return;

    // Optionally assess each image via AI endpoint
    for (var item in images) {
      final b64 = item['image']?['base64'];
      if (b64 != null) {
        final result = await ApiService.assessImage(b64, ctx);
        item['assessment'] = result;
      }
    }

    // Send results back to parent widget
    widget.updateCapturedImages(images);
  }

  /// Displays a dialog form for adding or selecting a patient
  void _showPatientForm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Patient Information'),
        content: PatientForm(onSubmit: (data) async {
          // Submit new patient data to API
          final created = await ApiService.submitPatientData(data, context);
          Navigator.of(context).pop();
          if (created != null && context.mounted) {
            // Update state with new patient ID and reset session
            setState(() {
              _activePatientId = created['id']?.toString();
              _activeSetId = null;
            });
          }
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate responsive widths/heights
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Live video feed preview
          Container(
            margin: const EdgeInsets.all(15),
            width: w * 0.75,
            height: h * 0.55,
            color: const Color.fromARGB(0, 158, 158, 158),
            child: VideoStreamPage(activePatientId: _activePatientId),
          ),
          const SizedBox(height: 20),
          // Row of action buttons: Add Patient & Capture
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton('Add Patient', _showPatientForm, w, h),
              SizedBox(width: w * 0.05),
              _actionButton(
                'Capture Image',
                // Disable button if no patient selected
                _activePatientId != null
                    ? () => _captureAndAssess(context)
                    : null,
                w,
                h,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a styled elevated button with rounded corners
  /// `onPressed` can be null to disable the button automatically
  Widget _actionButton(
      String label, VoidCallback? onPressed, double w, double h) {
    return SizedBox(
      width: w * 0.25,
      height: h * 0.1,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: utsaOrange,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: (w * 0.03).clamp(16.0, 40.0))),
      ),
    );
  }
}

/// Stateful form widget for entering patient details
class PatientForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const PatientForm({super.key, required this.onSubmit});

  @override
  State<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '', _lastName = '', _gender = '';
  DateTime? _dob;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First Name input field
          TextFormField(
            decoration: const InputDecoration(
                labelText: 'First Name', hintText: 'Enter First Name'),
            onSaved: (v) => _firstName = v ?? '',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter First Name' : null,
          ),
          // Last Name input field
          TextFormField(
            decoration: const InputDecoration(
                labelText: 'Last Name', hintText: 'Enter Last Name'),
            onSaved: (v) => _lastName = v ?? '',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter Last Name' : null,
          ),
          // Date of Birth picker field
          TextFormField(
            decoration: InputDecoration(
                labelText: 'Date of Birth',
                hintText: _dob == null
                    ? 'Select DOB'
                    : _dob!.toLocal().toString().split(' ')[0]),
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
          // Gender dropdown field
          DropdownButtonFormField<String>(
            value: _gender.isEmpty ? null : _gender,
            onChanged: (v) => setState(() => _gender = v ?? ''),
            items: ['Male', 'Female']
                .map((sex) => DropdownMenuItem(value: sex, child: Text(sex)))
                .toList(),
            decoration: const InputDecoration(
                labelText: 'Sex', hintText: 'Select Option'),
          ),
          // Submit button for patient data
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
                child: Text('Submit',
                    style: TextStyle(fontSize: (w * 0.05).clamp(14.0, 24.0))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
