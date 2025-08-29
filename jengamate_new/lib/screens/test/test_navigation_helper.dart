import 'package:flutter/material.dart';
import 'image_upload_test_screen.dart';
import 'pdf_test_screen.dart';

class TestNavigationHelper {
  /// Navigate to the Image Upload Test Screen
  static void navigateToImageUploadTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImageUploadTestScreen(),
      ),
    );
  }

  /// Navigate to the PDF Generation Test Screen
  static void navigateToPdfTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PdfTestScreen(),
      ),
    );
  }

  /// Show a floating action button to access test screens (for development)
  static Widget buildTestFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => navigateToImageUploadTest(context),
      backgroundColor: Colors.orange,
      child: const Icon(Icons.cloud_upload),
      tooltip: 'Test Image Upload',
    );
  }

  /// Build a test menu for accessing various test screens
  static Widget buildTestMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.bug_report, color: Colors.orange),
      tooltip: 'Test Menu',
      onSelected: (value) {
        switch (value) {
          case 'image_upload':
            navigateToImageUploadTest(context);
            break;
          case 'pdf_test':
            navigateToPdfTest(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'image_upload',
          child: Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.blue),
              SizedBox(width: 8),
              Text('Test Image Upload'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pdf_test',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 8),
              Text('Test PDF Generation'),
            ],
          ),
        ),
      ],
    );
  }
}
