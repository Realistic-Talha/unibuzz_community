import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String url;

  const VoiceMessagePlayer({
    super.key,
    required this.url,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('Initializing player with Supabase URL: ${widget.url}');
      
      // Load and cache the audio file
      await _player.setUrl(widget.url);
      _duration = _player.duration ?? Duration.zero;
      debugPrint('Audio duration: $_duration');

      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state.playing);
        }
      });
    } catch (e) {
      debugPrint('Error initializing player: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (_isPlaying) {
              _player.pause();
            } else {
              _player.play();
            }
          },
        ),
        Expanded(
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble(),
            onChanged: (value) {
              _player.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Text(_formatDuration(_position)),
      ],
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
