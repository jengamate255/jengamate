// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class SupplierModel {
  final String id;
  final String name;
  final String? description;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? website;
  final List<String>? categories; // Categories this supplier provides
  final bool isActive;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const SupplierModel({
    required this.id,
    required this.name,
    this.description,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.website,
    this.categories,
    this.isActive = true,
    this.logoUrl,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return SupplierModel(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'],
      contactPerson: data['contactPerson'],
      email: data['email'],
      phone: data['phone'],
      address: data['address'],
      city: data['city'],
      country: data['country'],
      website: data['website'],
      categories: List<String>.from(data['categories'] ?? []),
      isActive: data['isActive'] ?? true,
      logoUrl: data['logoUrl'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: (data['updatedAt'] is String) ? DateTime.parse(data['updatedAt']) : _parseOptionalDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'website': website,
      'categories': categories,
      'isActive': isActive,
      'logoUrl': logoUrl,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? description,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? website,
    List<String>? categories,
    bool? isActive,
    String? logoUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      website: website ?? this.website,
      categories: categories ?? this.categories,
      isActive: isActive ?? this.isActive,
      logoUrl: logoUrl ?? this.logoUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SupplierModel(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplierModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

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
        return value.toDate(); // This is the key fix!
      } catch (e) {
        print('Error converting Timestamp to DateTime: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Helper method to parse optional timestamps safely from Firestore
  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
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
        return null;
      }
    }
    return null;
  }
}
