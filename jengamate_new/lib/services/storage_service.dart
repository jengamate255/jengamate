import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage({
    required String fileName,
    required String folder,
    Uint8List? bytes,
    File? file,
  }) async {
    try {
      final Reference ref = _storage.ref().child(folder).child(fileName);
      UploadTask uploadTask;

      if (bytes != null) {
        uploadTask = ref.putData(bytes);
      } else if (file != null) {
        uploadTask = ref.putFile(file);
      } else {
        throw ArgumentError('Either bytes or file must be provided.');
      }

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Firebase upload error: $e');
      rethrow;
    }
  }

  Future<bool> deleteImage(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image from Firebase: $e');
      // If the object does not exist, Firebase throws an error.
      // We can consider this a success in the context of deletion.
      if (e is FirebaseException && e.code == 'object-not-found') {
        return true;
      }
      return false;
    }
  }
}
