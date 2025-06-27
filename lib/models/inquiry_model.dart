import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/product_model.dart';

class Inquiry {
  final String id;
  final String projectName;
  final String deliveryAddress;
  final String timeline;
  final List<Product> products;
  final String status;
  final DateTime createdAt;

  Inquiry({
    this.id = '',
    this.projectName = '',
    this.deliveryAddress = '',
    this.timeline = '',
    required this.products,
    this.status = 'Pending',
    required this.createdAt,
  });

  factory Inquiry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Inquiry(
      id: doc.id,
      projectName: data['projectName'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      timeline: data['timeline'] ?? '',
      products: (data['products'] as List<dynamic>?)
              ?.map((productData) => Product.fromMap(productData as Map<String, dynamic>))
              .toList() ??
          [],
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectName': projectName,
      'deliveryAddress': deliveryAddress,
      'timeline': timeline,
      'products': products.map((product) => product.toMap()).toList(),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
