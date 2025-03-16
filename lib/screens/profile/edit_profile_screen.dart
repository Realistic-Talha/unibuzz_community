import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unibuzz_community/models/user_model.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/widgets/user_avatar.dart';
import 'dart:io';
import 'package:unibuzz_community/services/image_hosting_service.dart';  // Add this import
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import for Timestamp

class EditProfileScreen extends StatefulWidget {
  final UserModel userModel;

  const EditProfileScreen({super.key, required this.userModel});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  File? _imageFile;
  bool _isLoading = false;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  String _selectedGender = 'Prefer not to say';
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    debugPrint('EditProfileScreen initialized'); // Debug print
    debugPrint('User data: ${widget.userModel}');
    _usernameController = TextEditingController(text: widget.userModel.username);
    _bioController = TextEditingController(text: widget.userModel.bio);
    _locationController = TextEditingController(text: widget.userModel.location);
    _phoneController = TextEditingController(text: widget.userModel.phone);
    _websiteController = TextEditingController(text: widget.userModel.website);
    _instagramController = TextEditingController(
      text: widget.userModel.socialLinks['instagram'],
    );
    _linkedinController = TextEditingController(
      text: widget.userModel.socialLinks['linkedin'],
    );
    _githubController = TextEditingController(
      text: widget.userModel.socialLinks['github'],
    );
    _selectedGender = widget.userModel.gender ?? 'Prefer not to say';
    _birthDate = widget.userModel.birthDate;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? photoUrl = widget.userModel.profileImageUrl;  // Initialize with current URL
      if (_imageFile != null) {
        photoUrl = await ImageHostingService().uploadImage(_imageFile!);
      }

      // Update all user settings including the photo URL
      final userUpdates = {
        'bio': _bioController.text,
        'location': _locationController.text,
        'phone': _phoneController.text,
        'website': _websiteController.text,
        'gender': _selectedGender,
        'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
        'socialLinks': {
          'instagram': _instagramController.text,
          'linkedin': _linkedinController.text,
          'github': _githubController.text,
        },
        'profileImageUrl': photoUrl,  // Make sure to include the photo URL in the update
      };

      // Update username and basic profile info
      await AuthService().updateProfile(
        username: _usernameController.text,
        photoUrl: photoUrl,
      );

      // Update all other user settings
      await AuthService().updateUserSettings(userUpdates);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TextButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _buildProfileImagePicker(),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Basic Information', Icons.person_outline),
              _buildTextField(
                controller: _usernameController,
                label: 'Username',
                prefixIcon: Icons.alternate_email,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter a username';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Contact Information', Icons.contact_mail_outlined),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _websiteController,
                label: 'Website',
                prefixIcon: Icons.language_outlined,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Personal Details', Icons.person_pin_outlined),
              _buildGenderSelector(),
              const SizedBox(height: 16),
              _buildDateSelector(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Social Links', Icons.link),
              _buildTextField(
                controller: _instagramController,
                label: 'Instagram',
                prefixIcon: Icons.camera_alt_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _linkedinController,
                label: 'LinkedIn',
                prefixIcon: Icons.work_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _githubController,
                label: 'GitHub',
                prefixIcon: Icons.code,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _buildGenderSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: ['Male', 'Female', 'Non-binary', 'Prefer not to say']
          .map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedGender = value);
      },
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _birthDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _birthDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birth Date',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        child: Text(
          _birthDate != null
              ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
              : 'Select date',
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          _imageFile != null
              ? CircleAvatar(
                  radius: 50,
                  backgroundImage: FileImage(_imageFile!),
                )
              : UserAvatar(
                  imageUrl: widget.userModel.profileImageUrl,  // Changed from photoUrl to profileImageUrl
                  username: widget.userModel.username,
                  radius: 50,
                ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
