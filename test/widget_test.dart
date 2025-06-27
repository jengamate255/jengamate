// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/main.dart';

void main() {
  testWidgets('Verifies Login Screen is shown initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // This will initialize Firebase and the providers.
    await tester.pumpWidget(const EngineerCommissionApp());

    // The AuthWrapper should show the LoginScreen because the user is not logged in.
    // We can verify this by looking for a unique piece of text on the login screen.
    expect(find.text('Welcome Back, Engineer'), findsOneWidget);
    expect(find.text('Log in to manage your commissions'), findsOneWidget);
  });
}
