import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String? parentId; // New field for sub-category relationship

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.parentId,
  });

  // Add uid getter for compatibility
  String get uid => id;

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      parentId: data['parentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'parentId': parentId,
    };
  }
}
