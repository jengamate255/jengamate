import 'package:jengamate/models/enums/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName; // Changed from name
  final String lastName; // New field
  final String? middleName; // New field
  final String? email;
  final String? photoUrl;
  final String?
      address; // Keep address for other users, though engineers use companyAddress
  final String? phoneNumber;
  final String? companyName;
  final String? companyAddress; // New field
  final String? companyPhone; // New field
  final UserRole role; // e.g., 'engineer', 'supplier', 'admin'
  final bool isApproved;
  final String? identityDocumentUrl;
  final String? identityDocumentType;
  final bool identityVerificationSubmitted;
  final bool identityVerificationApproved;
  final String? approvalStatus; // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? dateOfBirth; // New field
  final String? gender; // New field
  final String? region; // New field
  final String? cityTown; // New field
  final String? referralCode; // New field
  final DateTime? lastLogin; // New field
  final List<String>? fcmTokens; // Changed from String? fcmToken
  final List<String> inquiryIds;
  final List<String> rfqIds;
  final List<String> subscribedCategoryIds;
  final String? tier; // New field

  String get displayName => '$firstName $lastName'; // Updated getter
  String get name => displayName; // Alias for compatibility
  
  // Location related fields
  String? get location => _location ?? (cityTown != null && region != null 
      ? '$cityTown, $region' 
      : cityTown ?? region ?? address);
  final String? _location; // For backward compatibility
  
  // Backward compatible location setter
  UserModel withLocation(String? value) {
    if (value == null) return this;
    
    final parts = value.split(',').map((e) => e.trim()).toList();
    if (parts.length > 1) {
      return copyWith(cityTown: parts[0], region: parts[1]);
    } else if (parts.isNotEmpty) {
      return copyWith(cityTown: parts[0]);
    }
    return this;
  }

  UserModel({
    required this.uid,
    this.inquiryIds = const [],
    this.rfqIds = const [],
    this.subscribedCategoryIds = const [],
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.email,
    this.photoUrl,
    this.address,
    this.phoneNumber,
    this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.role = UserRole.engineer, // Default role
    this.isApproved = false,
    this.identityDocumentUrl,
    this.identityDocumentType,
    this.identityVerificationSubmitted = false,
    this.identityVerificationApproved = false,
    this.approvalStatus = 'pending',
    this.createdAt,
    this.updatedAt,
    this.dateOfBirth,
    this.gender,
    this.region,
    this.cityTown,
    this.referralCode,
    this.lastLogin,
    this.fcmTokens, // Changed from this.fcmToken
    this.tier,
  }) : _location = null;

  // Factory constructor to create a UserModel from a map (e.g., from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      middleName: data['middleName'],
      email: data['email'],
      photoUrl: data['photoUrl'],
      address: data['address'],
      phoneNumber: data['phoneNumber'],
      companyName: data['companyName'],
      companyAddress: data['companyAddress'],
      companyPhone: data['companyPhone'],
      role: _parseUserRole(data['roles'], data['role']),
      isApproved: data['isApproved'] ?? false,
      identityDocumentUrl: data['identityDocumentUrl'],
      identityDocumentType: data['identityDocumentType'],
      identityVerificationSubmitted:
          data['identityVerificationSubmitted'] ?? false,
      identityVerificationApproved:
          data['identityVerificationApproved'] ?? false,
      approvalStatus: data['approvalStatus'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: data['gender'],
      region: data['region'],
      cityTown: data['cityTown'],
      referralCode: data['referralCode'],
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      fcmTokens: (data['fcmTokens'] as List<dynamic>?)?.map((e) => e.toString()).toList(), // Changed from fcmToken
      inquiryIds: List<String>.from(data['inquiryIds'] ?? []),
      rfqIds: List<String>.from(data['rfqIds'] ?? []),
      subscribedCategoryIds:
          List<String>.from(data['subscribedCategoryIds'] ?? []),
      tier: data['tier'],
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json, json['uid'] ?? '');
  }

  // Helper method to parse UserRole from roles array or singular role string
  static UserRole _parseUserRole(dynamic rolesData, dynamic singularRoleData) {
    if (rolesData is List) {
      List<String> roles =
          List<String>.from(rolesData.map((e) => e.toString().toLowerCase()));
      if (roles.contains('super_admin') || roles.contains('admin')) {
        return UserRole.admin;
      }
      if (roles.contains('supplier')) {
        return UserRole.supplier;
      }
    }

    // Fallback to singular role if roles array doesn't provide admin/supplier or is not a list
    if (singularRoleData != null) {
      return UserRole.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            singularRoleData.toString().toLowerCase(),
        orElse: () => UserRole.engineer,
      );
    }

    return UserRole.engineer; // Default fallback
  }

  // Method to convert a UserModel instance to a map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'email': email,
      'photoUrl': photoUrl,
      'address': address,
      'phoneNumber': phoneNumber,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'role': role.name,
      'isApproved': isApproved,
      'identityDocumentUrl': identityDocumentUrl,
      'identityDocumentType': identityDocumentType,
      'identityVerificationSubmitted': identityVerificationSubmitted,
      'identityVerificationApproved': identityVerificationApproved,
      'approvalStatus': approvalStatus,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'region': region,
      'cityTown': cityTown,
      'referralCode': referralCode,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'fcmTokens': fcmTokens, // Changed from fcmToken
      'inquiryIds': inquiryIds,
      'rfqIds': rfqIds,
      'subscribedCategoryIds': subscribedCategoryIds,
      'tier': tier,
    };
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? middleName,
    String? email,
    String? photoUrl,
    String? address,
    String? phoneNumber,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    UserRole? role,
    bool? isApproved,
    String? identityDocumentUrl,
    String? identityDocumentType,
    bool? identityVerificationSubmitted,
    bool? identityVerificationApproved,
    String? approvalStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dateOfBirth,
    String? gender,
    String? region,
    String? cityTown,
    String? referralCode,
    DateTime? lastLogin,
    List<String>? fcmTokens, // Changed from String? fcmToken
    List<String>? inquiryIds,
    List<String>? rfqIds,
    List<String>? subscribedCategoryIds,
    String? tier,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      identityDocumentUrl: identityDocumentUrl ?? this.identityDocumentUrl,
      identityDocumentType: identityDocumentType ?? this.identityDocumentType,
      identityVerificationSubmitted:
          identityVerificationSubmitted ?? this.identityVerificationSubmitted,
      identityVerificationApproved:
          identityVerificationApproved ?? this.identityVerificationApproved,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      region: region ?? this.region,
      cityTown: cityTown ?? this.cityTown,
      referralCode: referralCode ?? this.referralCode,
      lastLogin: lastLogin ?? this.lastLogin,
      fcmTokens: fcmTokens ?? this.fcmTokens, // Changed from fcmToken
      inquiryIds: inquiryIds ?? this.inquiryIds,
      rfqIds: rfqIds ?? this.rfqIds,
      subscribedCategoryIds:
          subscribedCategoryIds ?? this.subscribedCategoryIds,
      tier: tier ?? this.tier,
    );
  }

  bool get isVerified => identityVerificationApproved;
}


