import 'package:firebase_auth/firebase_auth.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final DatabaseService _databaseService = DatabaseService();

  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create or update the user document in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          // Use email prefix as a temporary display name
          displayName: email.split('@').first,
        );
        await _databaseService.upsertUser(userModel);
      }

      return 'Signed in';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  User? get currentUser => _firebaseAuth.currentUser;
}
