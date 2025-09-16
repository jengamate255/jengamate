import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/utils/logger.dart';

class UserStateProvider extends ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = true;
  StreamSubscription<fb_auth.User?>? _authSubscription;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  UserStateProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authSubscription = _auth.authStateChanges().listen(
      _onAuthStateChanged,
      onError: (error) {
        Logger.logError('Auth state change error', error, StackTrace.current);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _onAuthStateChanged(fb_auth.User? firebaseUser) async {
    try {
      if (firebaseUser == null) {
        _currentUser = null;
        _isLoading = false;
        Logger.log('User signed out');
      } else {
        Logger.log('Firebase user detected: ${firebaseUser.uid}');
        await _loadUserData(firebaseUser);
      }
    } catch (e, stackTrace) {
      Logger.logError('Error handling auth state change', e, stackTrace);
      _currentUser = null;
      _isLoading = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadUserData(fb_auth.User firebaseUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to get user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        _currentUser = UserModel.fromFirestore(userDoc);
        Logger.log('User data loaded from Firestore: ${_currentUser!.displayName}');
      } else {
        // Create a basic user model from Firebase user data
        _currentUser = UserModel(
          uid: firebaseUser.uid,
          firstName: firebaseUser.displayName?.split(' ').first ?? 'User',
          lastName: firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          email: firebaseUser.email,
          photoUrl: firebaseUser.photoURL,
          phoneNumber: firebaseUser.phoneNumber,
          role: UserRole.engineer, // Default role
          isApproved: false,
          createdAt: DateTime.now(),
        );
        Logger.log('Created basic user model from Firebase user');
      }
    } catch (e, stackTrace) {
      Logger.logError('Error loading user data', e, stackTrace);
      // Create a basic user model as fallback
      _currentUser = UserModel(
        uid: firebaseUser.uid,
        firstName: firebaseUser.displayName?.split(' ').first ?? 'User',
        lastName: firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
        phoneNumber: firebaseUser.phoneNumber,
        role: UserRole.engineer,
        isApproved: false,
        createdAt: DateTime.now(),
      );
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refreshUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}






