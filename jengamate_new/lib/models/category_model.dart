// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

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

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return CategoryModel(
      id: docId,
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
