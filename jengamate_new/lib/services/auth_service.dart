import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jengamate/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? firebaseAuth}) : _auth = firebaseAuth ?? FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Sign In
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e, s) {
      Logger.logError('Error signing in', e, s);
      rethrow;
    }
  }

  // Email & Password Registration
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
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
  Future<UserCredential?> verifyOTP(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e, s) {
      Logger.logError('Error verifying OTP', e, s);
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e, s) {
      Logger.logError('Error signing out', e, s);
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e, s) {
      Logger.logError('Error sending password reset email', e, s);
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      await currentUser?.verifyBeforeUpdateEmail(newEmail);
    } catch (e, s) {
      Logger.logError('Error updating email', e, s);
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } catch (e, s) {
      Logger.logError('Error updating password', e, s);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } catch (e, s) {
      Logger.logError('Error deleting account', e, s);
    }
  }

  // Reauthenticate user
  Future<bool> reauthenticateWithEmail(String email, String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await currentUser?.reauthenticateWithCredential(credential);
      return true;
    } catch (e, s) {
      Logger.logError('Error reauthenticating', e, s);
      return false;
    }
  }

  // Get user custom claims
  Future<Map<String, dynamic>?> getCustomClaims() async {
    try {
      final user = currentUser;
      if (user == null) return null;
      
      final tokenResult = await user.getIdTokenResult();
      return tokenResult.claims;
    } catch (e, s) {
      Logger.logError('Error getting custom claims', e, s);
      return null;
    }
  }

  // Get user role from custom claims
  Future<String?> getUserRole() async {
    try {
      final claims = await getCustomClaims();
      return claims?['role'] as String?;
    } catch (e, s) {
      Logger.logError('Error getting user role', e, s);
      return null;
    }
  }

  // Check if user has admin role
  Future<bool> isAdmin() async {
    try {
      final role = await getUserRole();
      return role == 'admin';
    } catch (e, s) {
      Logger.logError('Error checking admin role', e, s);
      return false;
    }
  }

  // Check if user has supplier role
  Future<bool> isSupplier() async {
    try {
      final role = await getUserRole();
      return role == 'supplier';
    } catch (e, s) {
      Logger.logError('Error checking supplier role', e, s);
      return false;
    }
  }

  // Check if user has approved role
  Future<bool> isApproved() async {
    try {
      final role = await getUserRole();
      return role == 'approved';
    } catch (e, s) {
      Logger.logError('Error checking approved role', e, s);
      return false;
    }
  }

  // Check if user has any of the required roles for storage access
  Future<bool> hasStorageAccess() async {
    try {
      final role = await getUserRole();
      return role == 'admin' || role == 'supplier';
    } catch (e, s) {
      Logger.logError('Error checking storage access', e, s);
      return false;
    }
  }

  // Force refresh token to get updated custom claims
  Future<bool> refreshToken() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      await user.getIdToken(true); // Force refresh
      return true;
    } catch (e, s) {
      Logger.logError('Error refreshing token', e, s);
      return false;
    }
  }

  // Stream for custom claims changes
  Stream<Map<String, dynamic>?> get customClaimsStream {
    return authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      return await getCustomClaims();
    });
  }

  // Stream for role changes
  Stream<String?> get roleStream {
    return customClaimsStream.map((claims) => claims?['role'] as String?);
  }
}
