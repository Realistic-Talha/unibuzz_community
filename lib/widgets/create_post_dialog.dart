import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:unibuzz_community/services/feed_service.dart';
import 'package:unibuzz_community/services/ai_service.dart';
import 'package:unibuzz_community/services/image_hosting_service.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'General';
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;

  final AIService _aiService = AIService();
  final ImageHostingService _imageHosting = ImageHostingService(); // Add this line

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
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _analyzeContent() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isAnalyzing = true);
    try {
      final suggestedCategory = await _aiService.categorizePost(
        _contentController.text,
      );
      setState(() {
        _selectedCategory = suggestedCategory;
      });
    } catch (e) {
      // Fallback to manual selection
    }
    setState(() => _isAnalyzing = false);
  }

  Future<void> _submitPost() async {
    if (_contentController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // First upload image to Imgur
      String? imageUrl;
      if (_selectedImages.isNotEmpty) {
        try {
          debugPrint('Starting Imgur upload...');
          imageUrl = await _imageHosting.uploadImage(_selectedImages.first);
          debugPrint('Successfully uploaded to Imgur: $imageUrl');
        } catch (e) {
          debugPrint('Failed to upload to Imgur: $e');
          throw Exception('Image upload failed');
        }
      }

      // Create post with Imgur URL
      await FeedService().createPost(
        _contentController.text,
        _selectedCategory,
        imageUrl: imageUrl, // Pass the Imgur URL directly
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error in post creation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.length > 50) {
                  _analyzeContent();
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: _isAnalyzing
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
              decoration: InputDecoration(
                labelText: 'Category',
                border: const OutlineInputBorder(),
                suffixIcon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.file(_selectedImages[index]),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Add Image'),
                  onPressed: _pickImage,
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
