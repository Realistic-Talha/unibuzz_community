import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:unibuzz_community/services/ai_service.dart';
import 'package:unibuzz_community/services/post_service.dart';
import 'package:unibuzz_community/services/image_hosting_service.dart';  // Add this import

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'General';
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;
  final _imageHosting = ImageHostingService();  // Add this line

  final List<String> _categories = [
    'General',
    'Academic',
    'Events',
    'Lost & Found',
    'Help Needed',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImages.add(File(image.path)));
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // Upload to Imgur first if there's an image
      String? imageUrl;
      if (_selectedImages.isNotEmpty) {
        imageUrl = await _imageHosting.uploadImage(_selectedImages[0]);
        debugPrint('Image uploaded to Imgur: $imageUrl');
      }

      final postData = {
        'content': _contentController.text,
        'imageUrl': imageUrl,  // Store Imgur URL
        'category': _selectedCategory,
        'likes': [],
        'commentCount': 0,
      };

      await PostService().createPost(postData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _analyzeContent() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isAnalyzing = true);
    try {
      final category = await AIService().categorizePost(_contentController.text);
      setState(() => _selectedCategory = category);
    } catch (e) {
      // Fallback to manual selection
    }
    setState(() => _isAnalyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TextButton(
                  onPressed: _submitPost,
                  child: const Text('Post'),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: "What's on your mind?",
              border: InputBorder.none,
            ),
            maxLines: 5,
            onChanged: (value) {
              if (value.length > 50) _analyzeContent();
            },
          ),
          const Divider(),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: _isAnalyzing ? null : (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(_selectedImages[index]),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() => _selectedImages.removeAt(index));
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: _pickImage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
