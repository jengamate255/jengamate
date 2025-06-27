import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/auth/login_screen.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/screens/dashboard_screen.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    final dbService = DatabaseService();

    if (firebaseUser != null) {
      return StreamProvider<UserModel?>.value(
        value: dbService.streamUser(firebaseUser.uid),
        initialData: null,
        child: const DashboardScreen(),
      );
    }
    return const LoginScreen();
  }
}
