import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      categoryId: data['categoryId'] ?? '',
      subCategoryId: data['subCategoryId'],
      supplierId: data['supplierId'] ?? '',
      isHot: data['isHot'] ?? false,
      numberOfReviews: (data['numberOfReviews'] as num?)?.toInt() ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      type: data['type'] ?? '',
      thickness: data['thickness'] ?? '',
      color: data['color'] ?? '',
      dimensions: data['dimensions'] ?? '',
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      serviceProvider: data['serviceProvider'] ?? '',
      drawingUrl: data['drawingUrl'],
      videoUrl: data['videoUrl'],
      variants: (data['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          const [],
      unitId: data['unitId'],
      brandId: data['brandId'],
      status: data['status'] ?? 'active',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      specifications: data['specifications'] as Map<String, dynamic>?,
    );
  }
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> imageUrls; // New field
  final String categoryId;
  final String? subCategoryId;
  final String supplierId;
  final bool isHot;
  final int numberOfReviews;
  final double averageRating;
  final String type;
  final String thickness;
  final String color;
  final String dimensions;
  final int stock;
  final String serviceProvider;
  final String? drawingUrl;
  final String? videoUrl;
  final List<ProductVariant> variants;
  final String? unitId;
  final String? brandId;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? specifications;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.imageUrls = const [], // Initialize new field
    required this.categoryId,
    this.subCategoryId,
    required this.supplierId,
    this.isHot = false,
    this.numberOfReviews = 0,
    this.averageRating = 0.0,
    this.type = '',
    this.thickness = '',
    this.color = '',
    this.dimensions = '',
    this.stock = 0,
    this.serviceProvider = '',
    this.drawingUrl,
    this.videoUrl,
    this.variants = const [],
    this.unitId,
    this.brandId,
    this.status = 'active',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.specifications,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []), // Parse new field
      categoryId: map['categoryId'] ?? '',
      subCategoryId: map['subCategoryId'],
      supplierId: map['supplierId'] ?? '',
      isHot: map['isHot'] ?? false,
      numberOfReviews: (map['numberOfReviews'] as num?)?.toInt() ?? 0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? '',
      thickness: map['thickness'] ?? '',
      color: map['color'] ?? '',
      dimensions: map['dimensions'] ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      serviceProvider: map['serviceProvider'] ?? '',
      drawingUrl: map['drawingUrl'],
      videoUrl: map['videoUrl'],
      variants: (map['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          const [],
      unitId: map['unitId'],
      brandId: map['brandId'],
      status: map['status'] ?? 'active',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      specifications: map['specifications'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls, // Include new field
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'supplierId': supplierId,
      'isHot': isHot,
      'numberOfReviews': numberOfReviews,
      'averageRating': averageRating,
      'type': type,
      'thickness': thickness,
      'color': color,
      'dimensions': dimensions,
      'stock': stock,
      'serviceProvider': serviceProvider,
      'drawingUrl': drawingUrl,
      'videoUrl': videoUrl,
      'variants': variants.map((v) => v.toMap()).toList(),
      'unitId': unitId,
      'brandId': brandId,
      'status': status,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'specifications': specifications,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    List<String>? imageUrls,
    String? categoryId,
    String? subCategoryId,
    String? supplierId,
    bool? isHot,
    int? numberOfReviews,
    double? averageRating,
    String? type,
    String? thickness,
    String? color,
    String? dimensions,
    int? stock,
    String? serviceProvider,
    String? drawingUrl,
    String? videoUrl,
    List<ProductVariant>? variants,
    String? unitId,
    String? brandId,
    String? status,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? specifications,
    bool? isDeleted, // This will be mapped to isActive
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      supplierId: supplierId ?? this.supplierId,
      isHot: isHot ?? this.isHot,
      numberOfReviews: numberOfReviews ?? this.numberOfReviews,
      averageRating: averageRating ?? this.averageRating,
      type: type ?? this.type,
      thickness: thickness ?? this.thickness,
      color: color ?? this.color,
      dimensions: dimensions ?? this.dimensions,
      stock: stock ?? this.stock,
      serviceProvider: serviceProvider ?? this.serviceProvider,
      drawingUrl: drawingUrl ?? this.drawingUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      variants: variants ?? this.variants,
      unitId: unitId ?? this.unitId,
      brandId: brandId ?? this.brandId,
      status: status ?? this.status,
      isActive: isDeleted != null ? !isDeleted : (isActive ?? this.isActive),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      specifications: specifications ?? this.specifications,
    );
  }
}

class ProductVariant {
  final String id;
  final String thickness;
  final String color;
  final String dimensions;
  final double price;
  final int stock;
  final String? materialSpecification;
  final String? drawingUrl;
  final List<String> imageUrls;

  ProductVariant({
    required this.id,
    this.thickness = '',
    this.color = '',
    this.dimensions = '',
    this.price = 0.0,
    this.stock = 0,
    this.materialSpecification,
    this.drawingUrl,
    this.imageUrls = const [],
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] ?? '',
      thickness: map['thickness'] ?? '',
      color: map['color'] ?? '',
      dimensions: map['dimensions'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      materialSpecification: map['materialSpecification'],
      drawingUrl: map['drawingUrl'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'thickness': thickness,
      'color': color,
      'dimensions': dimensions,
      'price': price,
      'stock': stock,
      'materialSpecification': materialSpecification,
      'drawingUrl': drawingUrl,
      'imageUrls': imageUrls,
    };
  }
}
