import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import '../widgets/theme.dart';

class VideoStreamPage extends StatefulWidget {
  const VideoStreamPage({super.key});

  @override
  State<VideoStreamPage> createState() => _VideoStreamPageState();
}

class _VideoStreamPageState extends State<VideoStreamPage> {
  late IO.Socket _socket;
  Uint8List? _currentFrame;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToSocketIO();
  }

  void _connectToSocketIO() {
    try {
      String socketIoUrl = dotenv.dotenv.isInitialized
          ? dotenv.dotenv.env['SOCKET_IO_URL'] ?? 'http://host.docker.internal:3000/stream'
          : 'http://host.docker.internal:3000/stream';
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

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isConnected ? 'Connected' : 'Connecting...',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color.fromARGB(187, 255, 255, 255)),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _currentFrame != null
              ? Image.memory(
                  _currentFrame!,
                  gaplessPlayback: true,
                  fit: BoxFit.cover,
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
    );
  }
}