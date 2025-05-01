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
      final url = dotenv.dotenv.isInitialized
          ? dotenv.dotenv.env['SOCKET_IO_URL']!
          : 'http://localhost:3000/stream';
      _socket = IO.io(url, {
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 5,
      });
      _socket.connect();
      _socket.onConnect((_) => setState(() => _isConnected = true));
      _socket.on('message', (data) {
        if (data?['frame'] != null) {
          try {
            final b64 = data['frame'].toString().split(',').last;
            setState(() => _currentFrame = base64Decode(b64));
          } catch (_) {}
        }
      });
      _socket.onDisconnect((_) => setState(() => _isConnected = false));
    } catch (e) {
      debugPrint('Socket init error: $e');
    }
  }

  Future<void> _fetchActivePatient() async {
    try {
      if (widget.activePatientId != null) {
        final p = await ApiService.fetchPatientById(widget.activePatientId!, context);
        if (p != null) {
          setState(() => _activePatient = p);
          return;
        }
      }
      final list = await ApiService.fetchPatients(context);
      if (list.isNotEmpty) setState(() => _activePatient = list.last);
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
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final panelWidth   = screenWidth * 0.15;

    return Stack(
      children: [
        // ─── Centered (now smaller) feed ─────────────────
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isConnected ? 'Connected' : 'Connecting...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color.fromARGB(187, 255, 255, 255),
                    ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:  screenWidth * 0.5,  
                  maxHeight: screenHeight * 0.5,  
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

        // ─── Floating Active Patient Panel ───────────────
        Positioned(
          top: 16,
          left: -2,
          child: Container(
            width: 235, //panelWidth,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF5A8296).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Patient',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white, fontSize: 25),
                ),
                const SizedBox(height: 10),
                if (_activePatient != null) ...[
                  Text(
                    '${_activePatient!['first_name'] ?? 'Unknown'} '
                    '${_activePatient!['last_name'] ?? ''}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'ID: ${_activePatient!['id'] ?? 'N/A'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70, fontSize: 20),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'DOB: ${_activePatient!['dob']?.split('T')[0] ?? 'N/A'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70, fontSize: 20),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Sex: ${_activePatient!['sex'] ?? 'N/A'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70, fontSize: 20),
                  ),
                ] else
                  Text(
                    'No Patient',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70, fontSize: 25),
                  ),
              ],
            ),
          ),
        ),
        // ----------------Floating Accessments-------------------
        
      ],
    );
  }
}
