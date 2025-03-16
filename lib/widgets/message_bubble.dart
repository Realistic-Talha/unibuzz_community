// import 'package:flutter/material.dart';
// import 'package:unibuzz_community/models/chat_model.dart';
// import 'package:url_launcher/url_launcher.dart' as url_launcher;
// import 'package:timeago/timeago.dart' as timeago;

// class MessageStatus extends StatelessWidget {
//   final bool isRead;
//   final bool isMe;
//   final DateTime timestamp;

//   const MessageStatus({
//     super.key,
//     required this.isRead,
//     required this.isMe,
//     required this.timestamp,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Add debug print
//     print('MessageStatus: isRead=$isRead, isMe=$isMe, timestamp=$timestamp');
    
//     return Container(
//       padding: const EdgeInsets.only(top: 4),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//         children: [
//           Text(
//             timeago.format(timestamp, locale: 'en'),
//             style: TextStyle(
//               fontSize: 12,
//               color: Theme.of(context).colorScheme.onSurfaceVariant,
//             ),
//           ),
//           if (isMe) ...[
//             const SizedBox(width: 4),
//             Icon(
//               isRead ? Icons.done_all : Icons.done,
//               size: 16,
//               color: isRead ? Colors.blue : Colors.grey,
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class MessageBubble extends StatelessWidget {
//   final ChatMessage message;
//   final bool isMe;

//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isMe,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Add debug print
//     print('MessageBubble: type=${message.type}, content=${message.content}, timestamp=${message.timestamp}');
    
//     return Padding(
//       padding: EdgeInsets.only(
//         left: isMe ? 64 : 16,
//         right: isMe ? 16 : 64,
//         top: 4,
//         bottom: 4,
//       ),
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Container(
//             constraints: const BoxConstraints(maxWidth: 280),
//             decoration: BoxDecoration(
//               color: isMe 
//                   ? Theme.of(context).colorScheme.primary 
//                   : Theme.of(context).colorScheme.surfaceVariant,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Column(
//               crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: _buildMessageContent(context),
//             ),
//           ),
//           MessageStatus(
//             isRead: message.isRead,
//             isMe: isMe,
//             timestamp: message.timestamp,
//           ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildMessageContent(BuildContext context) {
//     switch (message.type) {
//       case MessageType.text:
//         return [
//           Text(
//             message.content,
//             style: TextStyle(
//               color: isMe 
//                   ? Theme.of(context).colorScheme.onPrimary 
//                   : Theme.of(context).colorScheme.onSurfaceVariant,
//             ),
//           ),
//         ];
//       case MessageType.image:
//         return [
//           GestureDetector(
//             onTap: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => _FullScreenImage(url: message.mediaUrl!),
//               ),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Image.network(
//                 message.mediaUrl!,
//                 width: 200,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         ];
//       case MessageType.file:
//         return [
//           InkWell(
//             onTap: () async {
//               final uri = Uri.parse(message.mediaUrl!);
//               if (await url_launcher.canLaunchUrl(uri)) {
//                 await url_launcher.launchUrl(uri);
//               } else {
//                 if (context.mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Could not open file')),
//                   );
//                 }
//               }
//             },
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.attach_file),
//                 const SizedBox(width: 8),
//                 Flexible(
//                   child: Text(
//                     message.content,
//                     style: TextStyle(
//                       color: isMe 
//                           ? Theme.of(context).colorScheme.onPrimary 
//                           : Theme.of(context).colorScheme.onSurfaceVariant,
//                       decoration: TextDecoration.underline,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ];
//       case MessageType.link:
//         return [
//           InkWell(
//             onTap: () async {
//               final uri = Uri.parse(message.content);
//               if (await url_launcher.canLaunchUrl(uri)) {
//                 await url_launcher.launchUrl(uri);
//               } else {
//                 if (context.mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Could not open link')),
//                   );
//                 }
//               }
//             },
//             child: Text(
//               message.content,
//               style: TextStyle(
//                 color: isMe 
//                     ? Theme.of(context).colorScheme.onPrimary 
//                     : Theme.of(context).colorScheme.onSurfaceVariant,
//                 decoration: TextDecoration.underline,
//               ),
//             ),
//           ),
//         ];
//       case MessageType.location:
//         return [
//           InkWell(
//             onTap: () async {
//               final uri = Uri.parse(
//                 'https://www.google.com/maps/search/?api=1&query=${message.content}'
//               );
//               if (await url_launcher.canLaunchUrl(uri)) {
//                 await url_launcher.launchUrl(uri);
//               } else {
//                 if (context.mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Could not open location')),
//                   );
//                 }
//               }
//             },
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.location_on),
//                 const SizedBox(width: 8),
//                 Flexible(
//                   child: Text(
//                     'View Location',
//                     style: TextStyle(
//                       color: isMe 
//                           ? Theme.of(context).colorScheme.onPrimary 
//                           : Theme.of(context).colorScheme.onSurfaceVariant,
//                       decoration: TextDecoration.underline,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ];
//     }
//   }
// }

// class _FullScreenImage extends StatelessWidget {
//   final String url;

//   const _FullScreenImage({required this.url});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Center(
//         child: InteractiveViewer(
//           child: Image.network(url),
//         ),
//       ),
//     );
//   }
// }
