import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/auth/login_screen.dart';
import 'package:jengamate/auth/approval_pending_screen.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/screens/dashboard_screen.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    final databaseService = DatabaseService();

    if (firebaseUser != null) {
      return FutureBuilder<UserModel?>(
        future: databaseService.getUser(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;
            return Provider<UserModel?>.value(
              value: user,
              child: user.approvalStatus == 'approved'
                  ? DashboardScreen()
                  : const ApprovalPendingScreen(),
            );
          }

          // Handle case where user is authenticated but not in the database
          return const Scaffold(
            body: Center(
              child: Text('Error: User not found in database.'),
            ),
          );
        },
      );
    }

    return LoginScreen();
  }
}
