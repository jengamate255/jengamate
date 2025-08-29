import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/widgets/custom_text_field.dart';
import 'dart:io'; // Import for File
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jengamate/services/hybrid_storage_service.dart';
import 'package:jengamate/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _storageService = HybridStorageService(
    supabaseClient: Supabase.instance.client,
    firebaseStorageService: StorageService(),
  );
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _companyNameController;
  late TextEditingController _lastNameController;
  XFile? _profileImage;


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _addressController = TextEditingController(text: widget.user.address);
    _phoneNumberController =
        TextEditingController(text: widget.user.phoneNumber);
    _companyNameController =
        TextEditingController(text: widget.user.companyName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _profileImage = image;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        String? newPhotoUrl = widget.user.photoUrl;
        if (_profileImage != null) {
          final imageBytes = await _profileImage!.readAsBytes();
          final imageFile = kIsWeb ? null : File(_profileImage!.path);

          final uploadedUrl = await _storageService.uploadImage(
            folder: 'profile_images',
            fileName: widget.user.uid,
            bytes: imageBytes,
            file: imageFile,
          );

          if (uploadedUrl == null) {
            throw Exception('Image upload failed.');
          }
          newPhotoUrl = uploadedUrl;
        }

        final updatedUser = UserModel(
          uid: widget.user.uid,
          firstName: _nameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          photoUrl: newPhotoUrl,
          address: _addressController.text,
          phoneNumber: _phoneNumberController.text,
          companyName: _companyNameController.text,
          role: widget.user.role,
        );

        await DatabaseService().updateUser(updatedUser);

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading indicator
          Navigator.of(context).pop(); // Go back to profile screen
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading indicator
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImage != null
                        ? (kIsWeb
                            ? NetworkImage(_profileImage!.path)
                            : FileImage(File(_profileImage!.path))) as ImageProvider
                        : (widget.user.photoUrl != null
                            ? NetworkImage(widget.user.photoUrl!)
                                as ImageProvider
                            : null), // Use null for fallback to child widget
                    child: _profileImage == null && widget.user.photoUrl == null
                        ? const Icon(Icons.camera_alt,
                            size: 40, color: Colors.white70)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                labelText: 'First Name',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your first name' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _lastNameController,
                labelText: 'Last Name',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your last name' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                readOnly: true, // Email is typically not editable from profile
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                labelText: 'Address',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneNumberController,
                labelText: 'Phone Number',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _companyNameController,
                labelText: 'Company Name',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
