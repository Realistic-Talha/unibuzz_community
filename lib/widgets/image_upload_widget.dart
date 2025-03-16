import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:unibuzz_community/services/image_hosting_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final void Function(List<String>) onImagesUploaded;
  final int maxImages;

  const ImageUploadWidget({
    super.key,
    required this.onImagesUploaded,
    this.maxImages = 5,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final List<File> _images = [];
  final ImageHostingService _imageHosting = ImageHostingService();
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickImage() async {
    if (_images.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxImages} images allowed'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_images.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final urls = await _imageHosting.uploadMultipleImages(
        _images,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      widget.onImagesUploaded(urls);
      
      if (mounted) {
        setState(() {
          _images.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_images.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(_images[index]),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _images.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_isUploading)
            LinearProgressIndicator(value: _uploadProgress),
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadImages,
            child: Text(_isUploading ? 'Uploading...' : 'Upload Images'),
          ),
        ],
        TextButton.icon(
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Image'),
          onPressed: _isUploading ? null : _pickImage,
        ),
      ],
    );
  }
}
