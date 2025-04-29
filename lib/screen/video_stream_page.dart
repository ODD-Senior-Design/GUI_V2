import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import '../widgets/theme.dart';
import '../services/api.dart';

class VideoStreamPage extends StatefulWidget {
  final String? activePatientId;
  const VideoStreamPage({super.key, this.activePatientId});

  @override
  State<VideoStreamPage> createState() => _VideoStreamPageState();
}

class _VideoStreamPageState extends State<VideoStreamPage> {
  late IO.Socket _socket;
  Uint8List? _currentFrame;
  bool _isConnected = false;
  Map<String, dynamic>? _activePatient;

  @override
  void initState() {
    super.initState();
    _connectToSocketIO();
    _fetchActivePatient();
  }

  @override
  void didUpdateWidget(covariant VideoStreamPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activePatientId != oldWidget.activePatientId) {
      _fetchActivePatient();
    }
  }

  void _connectToSocketIO() {
    try {
      String socketIoUrl = dotenv.dotenv.isInitialized
          ? dotenv.dotenv.env['SOCKET_IO_URL'] ?? 'http://localhost:3000/stream'
          : 'http://localhost:3000/stream';
      debugPrint('Connecting to Socket.IO at: $socketIoUrl');
      _socket = IO.io(socketIoUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 5,
      });

      _socket.connect();

      _socket.onConnect((_) {
        setState(() => _isConnected = true);
        debugPrint('Connected to Socket.IO server at $socketIoUrl');
        _socket.emit('join', 'video_stream_room');
      });

      _socket.on('message', (data) {
        debugPrint('Received video frame data: $data');
        if (data != null && data['frame'] != null) {
          String base64String = data['frame'].toString().split(',').last;
          try {
            setState(() {
              _currentFrame = base64Decode(base64String);
            });
          } catch (e) {
            debugPrint('Error decoding base64 frame: $e');
          }
        }
      });

      _socket.onDisconnect((_) {
        setState(() => _isConnected = false);
        debugPrint('Disconnected from Socket.IO server');
      });

      _socket.onError((error) {
        debugPrint('Socket.IO Error: $error');
      });

      _socket.onConnectError((error) {
        debugPrint('Connection Error: $error');
      });
    } catch (e) {
      debugPrint('Socket initialization error: $e');
    }
  }

  Future<void> _fetchActivePatient() async {
    try {
      if (widget.activePatientId != null) {
        final patient = await ApiService.fetchPatientById(widget.activePatientId!, context);
        if (patient != null) {
          setState(() {
            _activePatient = patient;
          });
          return;
        }
      }
      // Fallback to latest patient
      final patients = await ApiService.fetchPatients(context);
      if (patients.isNotEmpty) {
        setState(() {
          _activePatient = patients.last;
        });
      }
    } catch (e) {
      debugPrint('Fetch patient error: $e');
    }
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final patientPanelWidth = screenWidth * 0.15; // 15% width

    return Stack(
      children: [
        // Centered Video Feed
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isConnected ? 'Connected' : 'Connecting...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color.fromARGB(187, 255, 255, 255),
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _currentFrame != null
                    ? Image.memory(
                        _currentFrame!,
                        gaplessPlayback: true,
                        fit: BoxFit.contain,
                      )
                    : const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: oddRed,
                          strokeWidth: 2.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
        // Patient Panel near top-left of video feed
        Positioned(
          top: 16, // Small offset from top
          left: 0, // Flush with left edge of video feed
          child: IntrinsicHeight(
            child: Container(
              width: patientPanelWidth,
              padding: const EdgeInsets.all(8), // Minimal padding
              decoration: BoxDecoration(
                color: Color(0xFF5A8296).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8), // Rounded corners
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Shrink to content
                children: [
                  Text(
                    'Active Patient',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 20, // Small title
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (_activePatient != null) ...[
                    Text(
                      '${_activePatient!['first_name'] ?? 'Unknown'} ${_activePatient!['last_name'] ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 15, // Small font
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'ID: ${_activePatient!['id'] ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'DOB: ${_activePatient!['dob']?.split('T')[0] ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Sex: ${_activePatient!['sex'] ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                    ),
                  ] else
                    Text(
                      'No Patient',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
