import 'package:flutter/material.dart';
import 'package:unibuzz_community/models/chat_model.dart';
import 'package:unibuzz_community/services/chat_service.dart';  // Add this import
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unibuzz_community/widgets/voice_recorder.dart';  // Add this import
import 'package:unibuzz_community/services/supabase_service.dart';

class ChatInput extends StatefulWidget {
  final String conversationId;  // Add this field
  final Function(String content, MessageType type, {File? mediaFile}) onSendMessage;

  const ChatInput({
    super.key,
    required this.conversationId,  // Add this parameter
    required this.onSendMessage,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  bool _isComposing = false;

  void _handleSubmitted() {
    if (_textController.text.isEmpty) return;

    widget.onSendMessage(_textController.text, MessageType.text);
    _textController.clear();
    setState(() => _isComposing = false);
  }

  Future<void> _handleAttachment() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(source: ImageSource.camera);
                if (image != null) {
                  widget.onSendMessage('', MessageType.image, mediaFile: File(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null) {
                  widget.onSendMessage('', MessageType.image, mediaFile: File(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Document'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  widget.onSendMessage(
                    result.files.single.name,
                    MessageType.file,
                    mediaFile: File(result.files.single.path!),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVoiceMessage(File audioFile) async {
    try {
      debugPrint('Voice recording stopped, sending voice message...');
      // Use the ChatService's sendVoiceMessage method instead
      await ChatService().sendVoiceMessage(widget.conversationId, audioFile);
    } catch (e) {
      debugPrint('Error handling voice message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending voice message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _handleAttachment,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: (text) {
                setState(() => _isComposing = text.isNotEmpty);
              },
              decoration: const InputDecoration(
                hintText: 'Send a message',
                border: InputBorder.none,
              ),
            ),
          ),
          if (!_isComposing) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: VoiceRecorder(
                onStop: _handleVoiceMessage,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _handleSubmitted,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
