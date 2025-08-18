import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/enhanced_user.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Predefined roles and their permissions
  static const Map<String, Map<String, dynamic>> rolePermissions = {
    'super_admin': {
      'permissions': {
        'users:read': true,
        'users:write': true,
        'users:delete': true,
        'roles:manage': true,
        'system:admin': true,
        'audit:read': true,
        'gdpr:manage': true,
      },
      'description': 'Full system access',
    },
    'admin': {
      'permissions': {
        'users:read': true,
        'users:write': true,
        'users:delete': false,
        'roles:assign': true,
        'audit:read': true,
        'gdpr:read': true,
      },
      'description': 'Administrative access',
    },
    'moderator': {
      'permissions': {
        'users:read': true,
        'users:write': true,
        'users:delete': false,
        'content:moderate': true,
      },
      'description': 'Content moderation access',
    },
    'user': {
      'permissions': {
        'profile:read': true,
        'profile:write': true,
        'content:read': true,
        'content:write': true,
      },
      'description': 'Standard user access',
    },
    'guest': {
      'permissions': {
        'content:read': true,
      },
      'description': 'Read-only access',
    },
  };

  // Get current user's roles
  Future<List<String>> getCurrentUserRoles() async {
    final user = _auth.currentUser;
    if (user == null) return ['guest'];

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return ['user'];

    final data = userDoc.data() as Map<String, dynamic>;
    return List<String>.from(data['roles'] ?? ['user']);
  }

  // Check if user has specific role
  Future<bool> hasRole(String uid, String role) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data() as Map<String, dynamic>;
    final roles = List<String>.from(data['roles'] ?? []);
    return roles.contains(role);
  }

  // Assign role to user
  Future<void> assignRole(String uid, String role) async {
    if (!rolePermissions.containsKey(role)) {
      throw Exception('Invalid role: $role');
    }

    final userRef = _firestore.collection('users').doc(uid);
    await userRef.update({
      'roles': FieldValue.arrayUnion([role]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateUserClaims(uid);
  }

  // Remove role from user
  Future<void> removeRole(String uid, String role) async {
    final userRef = _firestore.collection('users').doc(uid);
    await userRef.update({
      'roles': FieldValue.arrayRemove([role]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateUserClaims(uid);
  }

  // Get user permissions based on roles
  Map<String, bool> getUserPermissions(List<String> roles) {
    final permissions = <String, bool>{};
    
    for (final role in roles) {
      if (rolePermissions.containsKey(role)) {
        final rolePerms = rolePermissions[role]!['permissions'] as Map<String, dynamic>;
        rolePerms.forEach((perm, value) {
          permissions[perm] = permissions[perm] ?? (value as bool);
        });
      }
    }
    
    return permissions;
  }

  // Update user custom claims
  Future<void> _updateUserClaims(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;
    final roles = List<String>.from(data['roles'] ?? []);
    final permissions = getUserPermissions(roles);

    await _firestore.collection('userClaims').doc(uid).set({
      'roles': roles,
      'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream user roles
  Stream<List<String>> streamUserRoles(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return ['guest'];
      final data = snapshot.data() as Map<String, dynamic>;
      return List<String>.from(data['roles'] ?? ['user']);
    });
  }

  // Check if user has specific permission
  Future<bool> hasPermission(String permission) async {
    final roles = await getCurrentUserRoles();
    final permissions = getUserPermissions(roles);
    return permissions[permission] ?? false;
  }

  // Stream all users for admin dashboard
  Stream<List<EnhancedUser>> streamAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EnhancedUser(
          uid: doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? '',
          photoURL: data['photoURL'],
          phoneNumber: data['phoneNumber'],
          emailVerified: data['emailVerified'] ?? false,
          phoneVerified: data['phoneVerified'] ?? false,
          roles: List<String>.from(data['roles'] ?? ['user']),
          permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
          lastLoginAt: data['lastLoginAt']?.toDate(),
          isActive: data['isActive'] ?? true,
          isDeleted: data['isDeleted'] ?? false,
          preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
          consent: Map<String, dynamic>.from(data['consent'] ?? {}),
          linkedAccounts: List<String>.from(data['linkedAccounts'] ?? []),
          security: Map<String, dynamic>.from(data['security'] ?? {}),
        );
      }).toList();
    });
  }

  // Get available roles
  List<String> getAvailableRoles() {
    return rolePermissions.keys.toList();
  }

  // Set user roles (replace all existing roles)
  Future<void> setUserRoles(String uid, List<String> newRoles) async {
    // Validate all roles
    for (final role in newRoles) {
      if (!rolePermissions.containsKey(role)) {
        throw Exception('Invalid role: $role');
      }

    final userRef = _firestore.collection('users').doc(uid);
    await userRef.update({
      'roles': newRoles,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateUserClaims(uid);
  }
}
}