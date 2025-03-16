// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:unibuzz_community/models/chat_model.dart';

// class AudioMessageBubble extends StatefulWidget {
//   final ChatMessage message;
//   final bool isMe;

//   const AudioMessageBubble({
//     super.key,
//     required this.message,
//     required this.isMe,
//   });

//   @override
//   State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
// }

// class _AudioMessageBubbleState extends State<AudioMessageBubble> {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   bool _isPlaying = false;
//   Duration _duration = Duration.zero;
//   Duration _position = Duration.zero;

//   @override
//   void initState() {
//     super.initState();
//     _audioPlayer.onDurationChanged.listen((duration) {
//       setState(() => _duration = duration);
//     });

//     _audioPlayer.onPositionChanged.listen((position) {
//       setState(() => _position = position);
//     });

//     _audioPlayer.onPlayerComplete.listen((_) {
//       setState(() {
//         _isPlaying = false;
//         _position = Duration.zero;
//       });
//     });
//   }

//   Future<void> _playPause() async {
//     if (_isPlaying) {
//       await _audioPlayer.pause();
//     } else {
//       if (widget.message.audioUrl != null) {  // Add null check
//         await _audioPlayer.play(UrlSource(widget.message.audioUrl!));
//       }
//     }
//     setState(() => _isPlaying = !_isPlaying);
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return '$minutes:$seconds';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           IconButton(
//             icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
//             onPressed: _playPause,
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               SizedBox(
//                 width: 150,
//                 child: LinearProgressIndicator(
//                   value: _duration.inSeconds > 0
//                       ? _position.inSeconds / _duration.inSeconds
//                       : 0,
//                 ),
//               ),
//               Text(
//                 _formatDuration(_position),
//                 style: Theme.of(context).textTheme.bodySmall,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     super.dispose();
//   }
// }
