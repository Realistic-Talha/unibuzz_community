import 'package:flutter/material.dart';
import 'package:unibuzz_community/models/event_model.dart';
import 'package:unibuzz_community/services/event_service.dart';
import 'package:unibuzz_community/widgets/location_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unibuzz_community/services/image_hosting_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _maxAttendeesController;
  DateTime? _selectedDateTime;
  String? _selectedCategory;
  File? _imageFile;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Academic',
    'Social',
    'Sports',
    'Cultural',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _maxAttendeesController = TextEditingController(
      text: widget.event.maxAttendees.toString(),
    );
    _selectedDateTime = widget.event.dateTime;
    _selectedCategory = widget.event.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await ImageHostingService().uploadImage(_imageFile!);
      }

      await EventService().updateEvent(
        widget.event.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        location: _locationController.text,
        coordinates: widget.event.coordinates,  // Keep existing coordinates
        dateTime: _selectedDateTime!,
        maxAttendees: int.tryParse(_maxAttendeesController.text) ?? 0,
        imageUrl: imageUrl ?? widget.event.imageUrl,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating event: $e')),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateEvent,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_imageFile != null || widget.event.imageUrl != null)
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider
                        : NetworkImage(widget.event.imageUrl!),
                  ),
                ),
              ),

            ElevatedButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: const Text('Change Event Image'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter a title';
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
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter a description';
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
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              validator: (value) {
                if (value == null) return 'Please select a category';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter a location';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _maxAttendeesController,
              decoration: const InputDecoration(
                labelText: 'Maximum Attendees',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDateTime == null
                    ? 'Select Date & Time'
                    : 'Date: ${_selectedDateTime?.day}/${_selectedDateTime?.month}/${_selectedDateTime?.year} '
                        'Time: ${_selectedDateTime?.hour}:${_selectedDateTime?.minute.toString().padLeft(2, '0')}',
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      _selectedDateTime ?? DateTime.now(),
                    ),
                  );
                  
                  if (time != null) {
                    setState(() {
                      _selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
