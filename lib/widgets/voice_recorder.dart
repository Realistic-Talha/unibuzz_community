import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VoiceRecorder extends StatefulWidget {
  final Function(File audioFile) onStop;

  const VoiceRecorder({
    super.key,
    required this.onStop,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final _audioRecorder = AudioRecorder();  // Changed from Record to AudioRecorder
  bool _isRecording = false;
  bool _isCanceled = false;
  DateTime? _startTime;
  String _recordingPath = '';
  double _dragDistance = 0;

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();  // Add permission check
      if (status.isGranted) {
        final dir = await getTemporaryDirectory();
        _recordingPath = '${dir.path}/audio_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath,
        );
        
        setState(() {
          _isRecording = true;
          _startTime = DateTime.now();
          _isCanceled = false;
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording({bool canceled = false}) async {
    try {
      if (!_isRecording) return;
      
      setState(() {
        _isRecording = false;
        _isCanceled = canceled;
      });

      await _audioRecorder.stop();

      if (!canceled && _recordingPath.isNotEmpty) {
        final audioFile = File(_recordingPath);
        if (await audioFile.exists()) {
          widget.onStop(audioFile);
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  String _getRecordingDuration() {
    if (_startTime == null) return '0:00';
    final duration = DateTime.now().difference(_startTime!);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(canceled: _isCanceled),
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragDistance += details.primaryDelta ?? 0;
          _isCanceled = _dragDistance < -50; // Cancel if dragged left more than 50px
        });
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 50),
        child: _isRecording
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isCanceled)
                    const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    )
                  else ...[
                    const Icon(
                      Icons.mic,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(_getRecordingDuration()),
                    const SizedBox(width: 8),
                    const Text('← Slide to cancel'),
                  ],
                ],
              )
            : const Icon(Icons.mic_none),
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
