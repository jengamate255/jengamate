// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class ProductModel {
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
  final String? sku; // New field
  final String? supplier; // New field
  final double? weight; // New field
  final double? length; // New field
  final double? width; // New field
  final double? height; // New field
  final bool? isAvailable; // New field

  // Backward compatibility getters
  String? get brand => brandId; // For backward compatibility
  String? get category => categoryId; // For backward compatibility
  String? get subcategory => subCategoryId; // For backward compatibility
  String? get gauge => specifications?['gauge']?.toString(); // Get gauge from specifications
  String? get profile => specifications?['profile']?.toString(); // Get profile from specifications
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
    this.sku, // Initialize new field
    this.supplier, // Initialize new field
    this.weight, // Initialize new field
    this.length, // Initialize new field
    this.width, // Initialize new field
    this.height, // Initialize new field
    this.isAvailable = true, // Initialize new field
    this.status = 'active',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.specifications,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle backward compatibility for fields that might be in different locations
    final specifications = Map<String, dynamic>.from(map['specifications'] ?? {});

    // Migrate top-level fields to specifications if needed
    if (map['gauge'] != null) {
      specifications['gauge'] = map['gauge'];
    }
    if (map['profile'] != null) {
      specifications['profile'] = map['profile'];
    }

    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []), // Parse new field
      categoryId: map['categoryId'] ?? map['category'] ?? '', // Backward compatibility
      subCategoryId: map['subCategoryId'] ?? map['subcategory'], // Backward compatibility
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
      brandId: map['brandId'] ?? map['brand'], // Backward compatibility
      status: map['status'] ?? 'active',
      isActive: map['isActive'] ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      specifications: specifications.isNotEmpty ? specifications : null,
    );
  }

  factory ProductModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return ProductModel.fromMap(data, docId);
  }

  // Helper method to parse timestamps safely from Firestore
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is String) {
      return DateTime.parse(value);
    }
    
    if (value is DateTime) {
      return value;
    }
    
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return value.toDate();
      } catch (e) {
        print('Error converting Timestamp to DateTime: $e');
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'categoryId': categoryId,
      'category': categoryId, // Backward compatibility
      'subCategoryId': subCategoryId,
      'subcategory': subCategoryId, // Backward compatibility
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
      'brand': brandId, // Backward compatibility
      'sku': sku, // Add new field
      'supplier': supplier, // Add new field
      'weight': weight, // Add new field
      'length': length, // Add new field
      'width': width, // Add new field
      'height': height, // Add new field
      'isAvailable': isAvailable, // Add new field
      'status': status,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'specifications': {
        ...?specifications,
        if (gauge != null) 'gauge': gauge, // Ensure gauge is in specifications
        if (profile != null) 'profile': profile, // Ensure profile is in specifications
      },
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
    String? sku, // Add new field
    String? supplier, // Add new field
    double? weight, // Add new field
    double? length, // Add new field
    double? width, // Add new field
    double? height, // Add new field
    bool? isAvailable, // Add new field
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
      sku: sku ?? this.sku, // Copy new field
      supplier: supplier ?? this.supplier, // Copy new field
      weight: weight ?? this.weight, // Copy new field
      length: length ?? this.length, // Copy new field
      width: width ?? this.width, // Copy new field
      height: height ?? this.height, // Copy new field
      isAvailable: isAvailable ?? this.isAvailable, // Copy new field
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
