import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // e.g., 'engineer', 'supplier', 'admin'

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'engineer', // Default role
  });

  // Factory constructor to create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'engineer',
    );
  }

  // Method to convert a UserModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
    };
  }
}
