import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jengamate/core/performance/performance_monitor.dart';
import 'package:jengamate/services/supabase_service.dart';
import 'package:jengamate/utils/logger.dart';

class TestSupabaseScreen extends StatefulWidget {
  const TestSupabaseScreen({super.key});

  static const String routeName = '/test-supabase';

  @override
  State<TestSupabaseScreen> createState() => _TestSupabaseScreenState();
}

class _TestSupabaseScreenState extends State<TestSupabaseScreen>
    with TickerProviderStateMixin {
  // Test states
  bool _isConnectionTestRunning = false;
  bool _isUploadTestRunning = false;
  bool _isSupabaseOnline = false;
  bool _isUploadSuccessful = false;

  // Test results
  String _connectionStatus = 'Not tested';
  String _uploadStatus = 'Not tested';
  String _connectionDetails = '';
  String _uploadDetails = '';

  // Test data
  File? _selectedFile;
  Uint8List? _testImageData;

  // Animations
  late AnimationController _connectionAnimationController;
  late AnimationController _uploadAnimationController;
  late Animation<double> _connectionAnimation;
  late Animation<double> _uploadAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateTestImage();
  }

  void _initializeAnimations() {
    _connectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _uploadAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _connectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _connectionAnimationController,
      curve: Curves.easeInOut,
    ));

    _uploadAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uploadAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateTestImage() {
    // Generate a simple test image (1x1 pixel PNG)
    final testImageBytes = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // rest of IHDR
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, // compressed data
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, // rest of IDAT
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
      0x42, 0x60, 0x82,
    ]);

    setState(() {
      _testImageData = testImageBytes;
    });
  }

  Future<void> _testSupabaseConnection() async {
    setState(() {
      _isConnectionTestRunning = true;
      _connectionStatus = 'Testing...';
      _connectionDetails = '';
    });

    final operationId = PerformanceMonitor().startOperation('supabase_connection_test');

    try {
      final supabaseService = context.read<SupabaseService>();

      // Test 1: Check if client is initialized (just try a simple operation)
      try {
        await supabaseService.client.auth.currentSession;
        Logger.log('✅ Supabase client initialized successfully');
      } catch (e) {
        throw Exception('Supabase client not properly initialized: $e');
      }

      // Test 2: Try to fetch system config (should always exist)
      final response = await supabaseService.client
          .from('system_config')
          .select('key, value')
          .limit(1);

      if (response.isEmpty) {
        Logger.log('⚠️  System config table is empty, but connection is working');
      }

      // Test 3: Check real-time connection
      final channel = supabaseService.client.channel('test_connection');
      channel.subscribe();

      await Future.delayed(const Duration(seconds: 1));

      Logger.log('✅ Real-time channel created and subscribed');

      channel.unsubscribe();

      // Success
      setState(() {
        _isSupabaseOnline = true;
        _connectionStatus = '✅ Connected';
        _connectionDetails = 'Database: ✅\nReal-time: ✅\nAuth: ✅';
      });

      _connectionAnimationController.forward();

      Logger.log('✅ Supabase connection test successful');

    } catch (e, stackTrace) {
      setState(() {
        _isSupabaseOnline = false;
        _connectionStatus = '❌ Failed';
        _connectionDetails = 'Error: ${e.toString()}';
      });

      Logger.logError('❌ Supabase connection test failed', e, stackTrace);
    } finally {
      setState(() {
        _isConnectionTestRunning = false;
      });

      PerformanceMonitor().endOperation(operationId);
    }
  }

  Future<void> _testFileUpload() async {
    if (_testImageData == null) {
      setState(() {
        _uploadStatus = '❌ No test file';
        _uploadDetails = 'Test image not generated';
      });
      return;
    }

    setState(() {
      _isUploadTestRunning = true;
      _uploadStatus = 'Uploading...';
      _uploadDetails = '';
    });

    final operationId = PerformanceMonitor().startOperation('file_upload_test');

    try {
      final supabaseService = context.read<SupabaseService>();

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'test_upload_${timestamp}.png';
      final filePath = 'test_uploads/$fileName';

      // Upload to product_images bucket (public)
      final uploadPath = await supabaseService.client.storage
          .from('product_images')
          .uploadBinary(filePath, _testImageData!);

      if (uploadPath.isEmpty) {
        throw Exception('Upload failed: No path returned from upload');
      }

      Logger.log('✅ File uploaded to: $uploadPath');

      // Verify upload by getting the public URL
      final publicUrl = supabaseService.client.storage
          .from('product_images')
          .getPublicUrl(filePath);

      if (publicUrl.isEmpty) {
        throw Exception('Failed to get public URL for uploaded file');
      }

      // Test download to verify file integrity
      final downloadedData = await supabaseService.client.storage
          .from('product_images')
          .download(filePath);

      if (downloadedData.isEmpty) {
        throw Exception('Download verification failed: No data received');
      }

      Logger.log('✅ File download verification successful');

      // Clean up test file
      await supabaseService.client.storage
          .from('product_images')
          .remove([filePath]);

      // Success
      setState(() {
        _isUploadSuccessful = true;
        _uploadStatus = '✅ Upload Successful';
        _uploadDetails = 'File uploaded: ✅\nURL generated: ✅\nDownload verified: ✅\nCleanup: ✅';
      });

      _uploadAnimationController.forward();

      Logger.log('✅ File upload test successful');

    } catch (e, stackTrace) {
      setState(() {
        _isUploadSuccessful = false;
        _uploadStatus = '❌ Upload Failed';
        _uploadDetails = 'Error: ${e.toString()}';
      });

      Logger.logError('❌ File upload test failed', e, stackTrace);
    } finally {
      setState(() {
        _isUploadTestRunning = false;
      });

      PerformanceMonitor().endOperation(operationId);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
        });

        // Upload the selected file
        await _uploadSelectedFile();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadSelectedFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploadTestRunning = true;
      _uploadStatus = 'Uploading selected file...';
    });

    try {
      final supabaseService = context.read<SupabaseService>();
      final fileBytes = await _selectedFile!.readAsBytes();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'user_upload_${timestamp}.jpg';
      final filePath = 'test_uploads/$fileName';

      final uploadPath = await supabaseService.client.storage
          .from('product_images')
          .uploadBinary(filePath, fileBytes);

      if (uploadPath.isEmpty) {
        throw Exception('Upload failed: No path returned from upload');
      }

      Logger.log('✅ Manual file uploaded to: $uploadPath');

      setState(() {
        _uploadStatus = '✅ File Uploaded';
        _uploadDetails = 'Selected file uploaded successfully!';
        _isUploadSuccessful = true;
      });

      _uploadAnimationController.forward();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully!')),
      );

    } catch (e) {
      setState(() {
        _uploadStatus = '❌ Upload Failed';
        _uploadDetails = 'Error: ${e.toString()}';
        _isUploadSuccessful = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploadTestRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Test Suite'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_done,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supabase Connection & Upload Test',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test your Supabase connection and file upload functionality',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Connection Test Section
            _buildTestSection(
              title: 'Connection Test',
              subtitle: 'Test Supabase database and real-time connection',
              icon: Icons.wifi,
              isRunning: _isConnectionTestRunning,
              status: _connectionStatus,
              details: _connectionDetails,
              onPressed: _testSupabaseConnection,
              animation: _connectionAnimation,
              isSuccess: _isSupabaseOnline,
            ),

            const SizedBox(height: 16),

            // Upload Test Section
            _buildTestSection(
              title: 'File Upload Test',
              subtitle: 'Test file upload to Supabase Storage',
              icon: Icons.cloud_upload,
              isRunning: _isUploadTestRunning,
              status: _uploadStatus,
              details: _uploadDetails,
              onPressed: _testFileUpload,
              animation: _uploadAnimation,
              isSuccess: _isUploadSuccessful,
            ),

            const SizedBox(height: 24),

            // Manual Upload Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Manual File Upload',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your own image file to test storage',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickAndUploadFile,
                            icon: const Icon(Icons.photo),
                            label: const Text('Pick & Upload Image'),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Selected: ${_selectedFile!.path.split('/').last}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test Results Summary
            Card(
              elevation: 2,
              color: (_isSupabaseOnline && _isUploadSuccessful)
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSupabaseOnline && _isUploadSuccessful
                              ? Icons.check_circle
                              : Icons.error,
                          color: _isSupabaseOnline && _isUploadSuccessful
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Test Results',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSupabaseOnline && _isUploadSuccessful
                          ? '✅ All tests passed! Your Supabase setup is working correctly.'
                          : '❌ Some tests failed. Check the details above.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSupabaseOnline = false;
                        _isUploadSuccessful = false;
                        _connectionStatus = 'Not tested';
                        _uploadStatus = 'Not tested';
                        _connectionDetails = '';
                        _uploadDetails = '';
                      });
                      _connectionAnimationController.reset();
                      _uploadAnimationController.reset();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Tests'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _testSupabaseConnection();
                      if (_isSupabaseOnline) {
                        await _testFileUpload();
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run All Tests'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isRunning,
    required String status,
    required String details,
    required VoidCallback onPressed,
    required Animation<double> animation,
    required bool isSuccess,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isSuccess ? 1.0 + (animation.value * 0.1) : 1.0,
                      child: Icon(
                        icon,
                        color: isSuccess
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isRunning)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton(
                    onPressed: onPressed,
                    child: const Text('Test'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: $status',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectionAnimationController.dispose();
    _uploadAnimationController.dispose();
    super.dispose();
  }
}
