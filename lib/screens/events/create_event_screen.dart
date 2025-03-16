import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/models/event_model.dart';
import 'package:unibuzz_community/services/event_service.dart';
import 'package:unibuzz_community/widgets/location_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  
  DateTime? _selectedDateTime;
  String? _selectedCategory;
  GeoPoint _coordinates = const GeoPoint(0, 0);
  File? _imageFile;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Academic',
    'Social',
    'Sports',
    'Cultural',
    'Other'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Create Event object
      final event = Event(
        id: '', // This will be set by Firestore
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory ?? 'Other',
        location: _locationController.text,
        coordinates: _coordinates,
        dateTime: _selectedDateTime!,
        organizerId: '',  // This will be set by the service
        maxAttendees: int.tryParse(_maxAttendeesController.text) ?? 0,
      );

      await EventService().createEvent(event);
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
        title: const Text('Create Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter an event title';
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
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
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
                      builder: (context) => SizedBox(
                        height: 400,
                        child: LocationPicker(
                          onLocationSelected: (location, coordinates) {
                            setState(() {
                              _locationController.text = location;
                              _coordinates = coordinates;
                            });
                            Navigator.pop(context);
                          },
                        ),
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
            TextFormField(
              controller: _maxAttendeesController,
              decoration: const InputDecoration(
                labelText: 'Maximum Attendees (Optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
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
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _createEvent,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }
}
