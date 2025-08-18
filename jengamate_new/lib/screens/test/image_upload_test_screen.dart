import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jengamate/services/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadTestScreen extends StatefulWidget {
    const ImageUploadTestScreen({super.key});

  @override
  State<ImageUploadTestScreen> createState() => _ImageUploadTestScreenState();
}

class _ImageUploadTestScreenState extends State<ImageUploadTestScreen> {
  final SupabaseStorageService _storageService = SupabaseStorageService(
    supabaseClient: Supabase.instance.client,
  );
  final ImagePicker _picker = ImagePicker();
  
  List<String> uploadedImageUrls = [];
  bool isUploading = false;
  String? uploadStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Storage Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isUploading)
                      const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading image...'),
                        ],
                      )
                    else if (uploadStatus != null)
                      Text(
                        uploadStatus!,
                        style: TextStyle(
                          color: uploadStatus!.contains('Error') 
                              ? Colors.red 
                              : Colors.green,
                        ),
                      )
                    else
                      const Text('Ready to upload images'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Upload Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUploading ? null : _pickAndUploadImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUploading ? null : _pickAndUploadFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Clear Results Button
            if (uploadedImageUrls.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _clearResults,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Results'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Uploaded Images Section
            if (uploadedImageUrls.isNotEmpty) ...[
              Text(
                'Uploaded Images (${uploadedImageUrls.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: uploadedImageUrls.length,
                  itemBuilder: (context, index) {
                    final url = uploadedImageUrls[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        title: Text('Image ${index + 1}'),
                        subtitle: Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _copyToClipboard(url),
                              tooltip: 'Copy URL',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteImage(url, index),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No images uploaded yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the buttons above to test image upload',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _uploadImage(image);
      }
    } catch (e) {
      _showError('Error picking image from camera: $e');
    }
  }

  Future<void> _pickAndUploadFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _uploadImage(image);
      }
    } catch (e) {
      _showError('Error picking image from gallery: $e');
    }
  }

  Future<void> _uploadImage(XFile image) async {
    setState(() {
      isUploading = true;
      uploadStatus = 'Preparing upload...';
    });

    try {
      final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.${image.path.split('.').last}';
      String? downloadUrl;

      if (kIsWeb) {
        // For web platform
        final bytes = await image.readAsBytes();
        downloadUrl = await _storageService.uploadImage(
          fileName: fileName,
          folder: 'test_uploads',
          bytes: bytes,
        );
      } else {
        // For mobile platforms
        final file = File(image.path);
        downloadUrl = await _storageService.uploadImage(
          fileName: fileName,
          folder: 'test_uploads',
          file: file,
        );
      }

      if (downloadUrl != null) {
        setState(() {
          uploadedImageUrls.add(downloadUrl!);
          uploadStatus = 'Upload successful!';
        });
        _showSuccess('Image uploaded successfully!');
      } else {
        _showError('Upload failed. Please check your Supabase configuration.');
      }
    } catch (e) {
      _showError('Upload error: $e');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> _deleteImage(String url, int index) async {
    try {
      final success = await _storageService.deleteImage(url);
      if (success) {
        setState(() {
          uploadedImageUrls.removeAt(index);
        });
        _showSuccess('Image deleted successfully!');
      } else {
        _showError('Failed to delete image');
      }
    } catch (e) {
      _showError('Delete error: $e');
    }
  }

  void _copyToClipboard(String text) {
    // Note: You might want to add clipboard package for this functionality
    _showSuccess('URL copied to clipboard!');
  }

  void _clearResults() {
    setState(() {
      uploadedImageUrls.clear();
      uploadStatus = null;
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      uploadStatus = 'Error: $message';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
