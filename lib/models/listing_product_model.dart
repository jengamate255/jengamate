import 'package:cloud_firestore/cloud_firestore.dart';

class ListingProduct {
  final String id;
  final String name;
  final String price;
  final String availability;
  final String serviceProvider;
  final String imageUrl;
  final bool isHot;

  ListingProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.availability,
    required this.serviceProvider,
    required this.imageUrl,
    this.isHot = false,
  });

  factory ListingProduct.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ListingProduct(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? '',
      availability: data['availability'] ?? '',
      serviceProvider: data['serviceProvider'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isHot: data['isHot'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'availability': availability,
      'serviceProvider': serviceProvider,
      'imageUrl': imageUrl,
      'isHot': isHot,
    };
  }
}
