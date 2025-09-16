import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/services/audit_service.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/services/role_service.dart';
import 'package:jengamate/models/enums/user_role.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final AuditService _auditService;
  final RoleService _roleService;

  AuthService({AuditService? auditService, RoleService? roleService})
      : _auditService = auditService ?? AuditService(),
        _roleService = roleService ?? RoleService();

  // Get current user (using Firebase auth since Supabase is configured with accessToken)
  fb_auth.User? get currentUser => _auth.currentUser;

  // Auth state stream (using Firebase auth since Supabase is configured with accessToken)
  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Sign In
  Future<fb_auth.UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.log('Firebase sign-in successful');
      if (userCredential.user != null) {
        final user = userCredential.user!;
        // Ensure the user has a default role if not already assigned
        final userDoc = await _roleService.firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists || (userDoc.data()?['roles'] as List? ?? []).isEmpty) {
          await _roleService.setUserRoles(user.uid, [UserRole.user.name]);
        }
        await _roleService.updateUserClaims(user.uid); // Update claims after sign-in

        _auditService.logEvent(AuditLogModel.login(
          userId: user.uid,
          userName: user.displayName ?? user.email ?? 'N/A',
          email: user.email ?? 'N/A',
        ));
      }
      return userCredential;
    } catch (e, s) {
      Logger.logError('Error signing in', e, s);
      rethrow;
    }
  }

  // Email & Password Registration
  Future<fb_auth.UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.log('Firebase registration successful');
      if (userCredential.user != null) {
        final user = userCredential.user!;
        await _roleService.setUserRoles(user.uid, [UserRole.user.name]); // Assign default role
        await _roleService.updateUserClaims(user.uid); // Update claims after registration

        _auditService.logEvent(AuditLogModel.register(
          userId: user.uid,
          userName: user.displayName ?? user.email ?? 'N/A',
          email: user.email ?? 'N/A',
        ));
      }
      return userCredential;
    } catch (e, s) {
      Logger.logError('Error registering', e, s);
      rethrow;
    }
  }

  // Phone Authentication - Send OTP
  Future<void> sendOTP(String phoneNumber, Function(String) onCodeSent) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          if (_auth.currentUser != null) {
            final user = _auth.currentUser!;
            final userDoc = await _roleService.firestore.collection('users').doc(user.uid).get();
            if (!userDoc.exists || (userDoc.data()?['roles'] as List? ?? []).isEmpty) {
              await _roleService.setUserRoles(user.uid, [UserRole.user.name]);
            }
            await _roleService.updateUserClaims(user.uid); // Update claims after phone auth

            _auditService.logEvent(AuditLogModel.login(
              userId: user.uid,
              userName: user.displayName ?? user.phoneNumber ?? 'N/A',
              email: '',
              additionalMetadata: {'method': 'phone'},
            ));
          }
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          Logger.logError('Phone verification failed', e, StackTrace.current);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e, s) {
      Logger.logError('Error sending OTP', e, s);
    }
  }

  // Phone Authentication - Verify OTP
  Future<fb_auth.UserCredential?> verifyOTP(
      String verificationId, String smsCode) async {
    try {
      fb_auth.PhoneAuthCredential credential =
          fb_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userDoc = await _roleService.firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists || (userDoc.data()?['roles'] as List? ?? []).isEmpty) {
          await _roleService.setUserRoles(user.uid, [UserRole.user.name]);
        }
        await _roleService.updateUserClaims(user.uid); // Update claims after phone auth

        _auditService.logEvent(AuditLogModel.login(
          userId: user.uid,
          userName: user.displayName ?? user.phoneNumber ?? 'N/A',
          email: '',
          additionalMetadata: {'method': 'phone'},
        ));
      }
      return userCredential;
    } catch (e, s) {
      Logger.logError('Error verifying OTP', e, s);
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      await _auth.signOut();
      Logger.log('Firebase sign-out successful');
      if (user != null) {
        await _roleService.updateUserClaims(user.uid); // Clear claims on sign out
        _auditService.logEvent(AuditLogModel.logout(
          userId: user.uid,
          userName: user.displayName ?? user.email ?? user.phoneNumber ?? 'N/A',
        ));
      }
    } catch (e, s) {
      Logger.logError('Error during Firebase sign-out', e, s);
      rethrow;
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _auditService.logEvent(AuditLogModel(
        uid: '', // Will be generated by AuditService
        actorId: '',
        actorName: 'System',
        action: 'PASSWORD_RESET_REQUEST',
        targetType: 'USER',
        targetId: '',
        targetName: email,
        timestamp: DateTime.now(),
        details: 'Password reset requested for $email',
        metadata: {'email': email},
      ));
    } catch (e, s) {
      Logger.logError('Error sending password reset email', e, s);
    }
  }

  // Get user custom claims (now deprecated in favor of RoleService.getUserPermissions)
  @Deprecated('Use RoleService.getUserPermissions instead.')
  Future<Map<String, dynamic>?> getCustomClaims() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      // Get Firebase custom claims
      final idTokenResult = await user.getIdTokenResult();
      return idTokenResult.claims;
    } catch (e, s) {
      Logger.logError('Error getting custom claims', e, s);
      rethrow;
    }
  }

  // Get user role from custom claims (now deprecated in favor of RoleService.streamUserRoles)
  @Deprecated('Use RoleService.streamUserRoles or RoleService.hasRole instead.')
  Future<String?> getUserRole() async {
    try {
      final claims = await getCustomClaims();
      return claims?['role'] as String?;
    } catch (e, s) {
      Logger.logError('Error getting user role', e, s);
      rethrow;
    }
  }

  // Check if user has admin role (now deprecated in favor of RoleService.hasPermission)
  @Deprecated('Use RoleService.hasPermission("system:admin") instead.')
  Future<bool> isAdmin() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      return _roleService.hasPermission('system:admin', userId: user.uid); // Check using RoleService
    } catch (e, s) {
      Logger.logError('Error checking admin role', e, s);
      rethrow;
    }
  }

  // Check if current user has a specific permission
  Future<bool> hasPermission(String permission) async {
    final user = currentUser;
    if (user == null) return false;
    return _roleService.hasPermission(permission, userId: user.uid);
  }
}