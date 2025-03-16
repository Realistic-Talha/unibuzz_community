import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:unibuzz_community/services/lost_found_service.dart';
import 'package:unibuzz_community/widgets/location_picker.dart';
import 'package:unibuzz_community/services/ai_service.dart'; // Add this import

class ReportItemScreen extends StatefulWidget {
  final bool isLost;

  const ReportItemScreen({super.key, required this.isLost});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  final List<File> _selectedImages = [];
  String? _selectedCategory;
  DateTime? _dateLostFound;
  GeoPoint _coordinates = const GeoPoint(0, 0);
  bool _isSubmitting = false;
  bool _isGeneratingTags = false;
  final AIService _aiService = AIService();

  final List<String> _categories = [
    'Electronics',
    'Documents',
    'Accessories',
    'Others',
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

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _generateTags() async {
    if (_descriptionController.text.isEmpty) return;

    setState(() => _isGeneratingTags = true);
    try {
      final suggestedTags = await _aiService.generateTags(
        _descriptionController.text,
      );
      setState(() {
        _tags.addAll(suggestedTags);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate tags')),
        );
      }
    }
    setState(() => _isGeneratingTags = false);
  }

  void _autoCategorizeLostItem() async {
    if (_descriptionController.text.isEmpty) return;
    
    setState(() => _isGeneratingTags = true);
    try {
      final category = await AIService().categorizePost(_descriptionController.text);
      setState(() {
        _selectedCategory = category;
      });
      
      final tags = await AIService().generateTags(_descriptionController.text);
      setState(() {
        _tags.addAll(tags);
      });
    } catch (e) {
      // Handle error
    }
    setState(() => _isGeneratingTags = false);
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await LostFoundService().reportItem(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        coordinates: _coordinates,
        isLost: widget.isLost,
        category: _selectedCategory,
        tags: _tags,
        images: _selectedImages,
        dateLostFound: _dateLostFound,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report ${widget.isLost ? 'Lost' : 'Found'} Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                if (value.length > 50) {
                  _autoCategorizeLostItem();
                }
              },
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Add Tags',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isGeneratingTags
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.add),
                  onPressed: _isGeneratingTags ? null : _addTag,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () async {
                    final result = await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => LocationPicker(
                        onLocationSelected: (location, coordinates) {
                          setState(() {
                            _locationController.text = location;
                            _coordinates = coordinates;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                    
                    if (result != null) {
                      setState(() {
                        _locationController.text = result['location'] as String;
                        _coordinates = result['coordinates'] as GeoPoint;
                      });
                    }
                  },
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please select a location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dateLostFound == null
                    ? 'Select Date'
                    : 'Date: ${_dateLostFound?.day}/${_dateLostFound?.month}/${_dateLostFound?.year}',
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _dateLostFound = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            if (_selectedImages.isNotEmpty)
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
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: const Text('Add Images'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}
