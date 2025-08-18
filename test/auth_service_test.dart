import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  group('AuthService', () {
    final mockFirebaseAuth = MockFirebaseAuth();
    final mockDatabaseService = MockDatabaseService();
    final authService = AuthService();

    test('signIn returns a user on success', () async {
      final mockUser = MockUser();
      final mockUserCredential = MockUserCredential();
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockFirebaseAuth.signInWithEmailAndPassword(
              email: 'test@test.com', password: 'password'))
          .thenAnswer((_) async => mockUserCredential);
      when(mockDatabaseService.getUser(mockUser.uid)).thenAnswer((_) async =>
          UserModel(
              uid: mockUser.uid,
              firstName: 'Test',
              lastName: 'User',
              email: 'test@test.com'));

      final result = await authService.signInWithEmailAndPassword(
          'test@test.com', 'password');

      expect(result, isA<UserCredential>());
    });

    test('signOut calls signOut on FirebaseAuth', () async {
      await authService.signOut();
      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('authStateChanges emits a user when a user is signed in', () {
      final mockUser = MockUser();
      when(mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));

      expect(authService.authStateChanges, emits(mockUser));
    });
  });
}
