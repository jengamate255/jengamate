import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'jengamate_new/lib/firebase_options.dart';
import 'jengamate_new/lib/screens/test/image_upload_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ImageUploadTestApp());
}

class ImageUploadTestApp extends StatelessWidget {
  const ImageUploadTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Image Upload Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ImageUploadTestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
