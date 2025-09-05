class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final String supplierId;
  final bool isHot;
  final int numberOfReviews;
  final double averageRating;
  final String type;
  final String thickness;
  final String color;
  final String dimensions;
  final String availability;
  final String serviceProvider;
  final String? drawingUrl;
  final String? videoUrl;
  final List<ProductVariant> variants;
  final String? unitId;
  final String? brandId;
  final String status;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.supplierId,
    this.isHot = false,
    this.numberOfReviews = 0,
    this.averageRating = 0.0,
    this.type = '',
    this.thickness = '',
    this.color = '',
    this.dimensions = '',
    this.availability = 'Available',
    this.serviceProvider = '',
    this.drawingUrl,
    this.videoUrl,
    this.variants = const [],
    this.unitId,
    this.brandId,
    this.status = 'active',
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      categoryId: map['categoryId'] ?? '',
      supplierId: map['supplierId'] ?? '',
      isHot: map['isHot'] ?? false,
      numberOfReviews: (map['numberOfReviews'] as num?)?.toInt() ?? 0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? '',
      thickness: map['thickness'] ?? '',
      color: map['color'] ?? '',
      dimensions: map['dimensions'] ?? '',
      availability: map['availability'] ?? 'Available',
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'supplierId': supplierId,
      'isHot': isHot,
      'numberOfReviews': numberOfReviews,
      'averageRating': averageRating,
      'type': type,
      'thickness': thickness,
      'color': color,
      'dimensions': dimensions,
      'availability': availability,
      'serviceProvider': serviceProvider,
      'drawingUrl': drawingUrl,
      'videoUrl': videoUrl,
      'variants': variants.map((v) => v.toMap()).toList(),
      'unitId': unitId,
      'brandId': brandId,
      'status': status,
    };
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
