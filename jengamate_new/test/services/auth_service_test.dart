import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:mockito/mockito.dart';

import 'auth_mocks.mocks.dart';

void main() {
  // Mocks
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;

  // Class under test
  late AuthService authService;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    authService = AuthService(firebaseAuth: mockFirebaseAuth);
  });

  group('AuthService Tests', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';

    group('signInWithEmailAndPassword', () {
      test('should return UserCredential on successful sign in', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInWithEmailAndPassword(testEmail, testPassword);

        // Assert
        expect(result, mockUserCredential);
        verify(mockFirebaseAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).called(1);
      });

      test('should throw FirebaseAuthException on failed sign in', () async {
        // Arrange
        final exception = FirebaseAuthException(code: 'user-not-found');
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(testEmail, testPassword),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('registerWithEmailAndPassword', () {
      test('should return UserCredential on successful user creation', () async {
        // Arrange
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        )).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.registerWithEmailAndPassword(testEmail, testPassword);

        // Assert
        expect(result, mockUserCredential);
      });

      test('should throw FirebaseAuthException on failed user creation', () async {
        // Arrange
        final exception = FirebaseAuthException(code: 'email-already-in-use');
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        // Act & Assert
        expect(
          () => authService.registerWithEmailAndPassword(testEmail, testPassword),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('signOut', () {
      test('should complete successfully when signOut is called', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async => Future.value());

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
      });
    });

    group('authStateChanges', () {
      test('should return a stream of User?', () {
        // Arrange
        when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

        // Act
        final result = authService.authStateChanges;

        // Assert
        expect(result, isA<Stream<User?>>());
        expect(result, emits(mockUser));
      });
    });
  });
}
