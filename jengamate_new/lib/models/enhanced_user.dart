import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedUser {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? photoURL;
  final bool emailVerified;
  final bool phoneVerified;
  final List<String> roles;
  final Map<String, dynamic> permissions;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final bool isDeleted;
  final String? deletedReason;
  final DateTime? deletedAt;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> consent;
  final List<String> linkedAccounts;
  final Map<String, dynamic> security;
  final String? address;

  EnhancedUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.address,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.roles = const ['user'],
    this.permissions = const {},
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
    this.isDeleted = false,
    this.deletedReason,
    this.deletedAt,
    this.preferences = const {},
    this.consent = const {},
    this.linkedAccounts = const [],
    this.security = const {},
  });

  factory EnhancedUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EnhancedUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      emailVerified: data['emailVerified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      roles: List<String>.from(data['roles'] ?? ['user']),
      permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      deletedReason: data['deletedReason'],
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      consent: Map<String, dynamic>.from(data['consent'] ?? {}),
      linkedAccounts: List<String>.from(data['linkedAccounts'] ?? []),
      security: Map<String, dynamic>.from(data['security'] ?? {}),
      address: data['address'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'roles': roles,
      'permissions': permissions,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null 
          ? Timestamp.fromDate(lastLoginAt!) 
          : null,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'deletedReason': deletedReason,
      'deletedAt': deletedAt != null 
          ? Timestamp.fromDate(deletedAt!) 
          : null,
      'preferences': preferences,
      'consent': consent,
      'linkedAccounts': linkedAccounts,
      'security': security,
      'address': address,
    };
  }

  EnhancedUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    bool? emailVerified,
    bool? phoneVerified,
    List<String>? roles,
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
    bool? isDeleted,
    String? deletedReason,
    DateTime? deletedAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? consent,
    List<String>? linkedAccounts,
    Map<String, dynamic>? security,
    String? address,
  }) {
    return EnhancedUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedReason: deletedReason ?? this.deletedReason,
      deletedAt: deletedAt ?? this.deletedAt,
      preferences: preferences ?? this.preferences,
      consent: consent ?? this.consent,
      linkedAccounts: linkedAccounts ?? this.linkedAccounts,
      security: security ?? this.security,
      address: address ?? this.address,
    );
  }

  bool hasRole(String role) => roles.contains(role);
  bool hasPermission(String permission) => permissions[permission] == true;
  bool hasAnyRole(List<String> requiredRoles) => 
      roles.any((role) => requiredRoles.contains(role));

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'roles': roles,
      'permissions': permissions,
      'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'deletedReason': deletedReason,
      'deletedAt': deletedAt,
      'preferences': preferences,
      'consent': consent,
      'linkedAccounts': linkedAccounts,
      'security': security,
      'address': address,
    };
  }
}