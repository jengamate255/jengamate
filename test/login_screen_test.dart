import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:jengamate/screens/dashboard_screen.dart';

// Since build_runner is not available, we can't generate mocks automatically.
// We will have to rely on manual mocks or find ways to test without them.
// For now, let's set up a basic widget test for the LoginScreen.

class MockAuthService extends Mock implements AuthService {
  @override
  Future<String?> signIn({required String email, required String password}) async {
    return super.noSuchMethod(
      Invocation.method(#signIn, [], {#email: email, #password: password}),
      returnValue: Future.value("Signed in"),
      returnValueForMissingStub: Future.value("Signed in"),
    );
  }

  @override
  Future<String?> signUp({required String email, required String password, required String displayName}) async {
    return super.noSuchMethod(
      Invocation.method(#signUp, [], {#email: email, #password: password, #displayName: displayName}),
      returnValue: Future.value("Signed up"),
      returnValueForMissingStub: Future.value("Signed up"),
    );
  }
}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockAuthService mockAuthService;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockAuthService = MockAuthService();
    mockNavigatorObserver = MockNavigatorObserver();
  });

  testWidgets('LoginScreen has a title, email, password fields, and a button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            // We can provide a mock user here if needed for certain tests
            Provider<User?>.value(value: null),
            Provider<AuthService>.value(value: mockAuthService),
          ],
          child: const LoginScreen(),
        ),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );

    // Verify that our widgets are present.
    expect(find.text('Welcome Back, Engineer'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email Address'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

  testWidgets('toggling to sign up shows display name field', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Verify the initial state is Login
    expect(find.text('Welcome Back, Engineer'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Display Name'), findsNothing);

    // Tap the "Sign Up" button
    await tester.tap(find.text('Don\'t have an account? Sign Up'));
    await tester.pump();

    // Verify the state changed to Sign Up
    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Display Name'), findsOneWidget);
  });

  testWidgets('successful login navigates to DashboardScreen', (WidgetTester tester) async {
    // Arrange
    when(mockAuthService.signIn(email: anyNamed('email') as String, password: anyNamed('password') as String))
        .thenAnswer((_) async => 'Signed in');

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: mockAuthService),
          ],
          child: const LoginScreen(),
        ),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );

    // Act
    await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    // Assert
    verify(mockNavigatorObserver.didPush(captureAny as Route<dynamic>, captureAny as Route<dynamic>)).called(1);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('failed login shows error message', (WidgetTester tester) async {
    // Arrange
    when(mockAuthService.signIn(email: anyNamed('email') as String, password: anyNamed('password') as String))
        .thenAnswer((_) async => 'Invalid credentials');

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: mockAuthService),
          ],
          child: const LoginScreen(),
        ),
      ),
    );

    // Act
    await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('successful sign up navigates to DashboardScreen', (WidgetTester tester) async {
    // Arrange
    when(mockAuthService.signUp(email: anyNamed('email') as String, password: anyNamed('password') as String, displayName: anyNamed('displayName') as String))
        .thenAnswer((_) async => 'Signed up');

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: mockAuthService),
          ],
          child: const LoginScreen(),
        ),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );

    // Act
    await tester.tap(find.text('Don\'t have an account? Sign Up'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Display Name'), 'Test User');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    // Assert
    verify(mockNavigatorObserver.didPush(captureAny as Route<dynamic>, captureAny as Route<dynamic>)).called(1);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('failed sign up shows error message', (WidgetTester tester) async {
    // Arrange
    when(mockAuthService.signUp(email: anyNamed('email') as String, password: anyNamed('password') as String, displayName: anyNamed('displayName') as String))
        .thenAnswer((_) async => 'Sign up failed');

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: mockAuthService),
          ],
          child: const LoginScreen(),
        ),
      ),
    );

    // Act
    await tester.tap(find.text('Don\'t have an account? Sign Up'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Display Name'), 'Test User');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Sign up failed'), findsOneWidget);
  });
}