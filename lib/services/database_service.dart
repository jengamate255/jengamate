import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jengamate/models/inquiry_model.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/listing_product_model.dart';
import 'package:jengamate/models/order_stats_model.dart';
import 'package:jengamate/models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Upserts a user document in the 'users' collection.
  /// If the user doesn't exist, it creates a new document.
  /// If the user exists, it merges the new data.
  Future<void> upsertUser(UserModel user) async {
    final docRef = _db.collection('users').doc(user.uid);
    await docRef.set(user.toMap(), SetOptions(merge: true));
  }

  /// Fetches a user document from Firestore.
  Future<UserModel?> getUser(String uid) async {
    final docRef = _db.collection('users').doc(uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      return UserModel.fromFirestore(docSnap);
    }
    return null;
  }

  /// Streams a user document from Firestore.
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  /// Streams a list of products from Firestore.
  Stream<List<ListingProduct>> getProductsStream() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ListingProduct.fromFirestore(doc)).toList();
    });
  }

  /// Streams a list of inquiries from Firestore.
  Stream<List<Inquiry>> getInquiriesStream() {
    return _db.collection('inquiries').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Inquiry.fromFirestore(doc)).toList();
    });
  }

  /// Adds a new inquiry to the 'inquiries' collection.
  Future<void> addInquiry(Inquiry inquiry) async {
    await _db.collection('inquiries').add(inquiry.toMap());
  }

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String> uploadDrawing(XFile file) async {
    try {
      // Create a unique file name
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = FirebaseStorage.instance.ref().child('drawings/$fileName');

      // Read file data as bytes
      final Uint8List data = await file.readAsBytes();

      // Upload to Firebase Storage
      final uploadTask = ref.putData(data);

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  /// Streams a commission document from Firestore for a specific user.
  Stream<CommissionModel?> streamCommission(String uid) {
    return _db.collection('users').doc(uid).collection('commissions').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return CommissionModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  /// Streams an order stats document from Firestore for a specific user.
  Stream<OrderStatsModel?> streamOrderStats(String uid) {
    return _db.collection('users').doc(uid).collection('orderStats').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return OrderStatsModel.fromFirestore(snapshot);
      }
      return null;
    });
  }
}
