// lib/screen/video_stream_page.dart

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
          setState(() => _activePatient = patient);
          return;
        }
      }
      // Fallback to latest patient
      final patients = await ApiService.fetchPatients(context);
      if (patients.isNotEmpty) {
        setState(() => _activePatient = patients.last);
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
    return LayoutBuilder(builder: (context, constraints) {
      final panelWidth = constraints.maxWidth * 0.15;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Active Patient Panel ───────────────────────────
          Container(
            width: panelWidth,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF5A8296).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Active Patient',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 10),
                if (_activePatient != null) ...[
                  Text(
                    '${_activePatient!['first_name'] ?? 'Unknown'} '
                    '${_activePatient!['last_name'] ?? ''}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'ID: ${_activePatient!['id'] ?? 'N/A'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'DOB: ${_activePatient!['dob']?.split('T')[0] ?? 'N/A'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Sex: ${_activePatient!['sex'] ?? 'N/A'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70, fontSize: 15),
                  ),
                ] else
                  Text(
                    'No Patient',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70, fontSize: 15),
                  ),
              ],
            ),
          ),

          // ─── Live Video Feed ────────────────────────────────
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isConnected ? 'Connected' : 'Connecting...',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: const Color.fromARGB(187, 255, 255, 255)),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.8,
                      maxHeight: constraints.maxHeight * 0.8,
                    ),
                    child: _currentFrame != null
                        ? Image.memory(
                            _currentFrame!,
                            gaplessPlayback: true,
                            fit: BoxFit.contain,
                          )
                        : const CircularProgressIndicator(
                            color: oddRed,
                            strokeWidth: 2.5,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
