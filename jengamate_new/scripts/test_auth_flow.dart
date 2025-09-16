import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test Firebase connection
  print('Testing Firebase connection...');
  try {
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    print('Firebase user: ${firebaseUser?.email ?? 'Not signed in'}');
  } catch (e) {
    print('Firebase error: $e');
  }

  // Test Supabase connection
  print('Testing Supabase connection...');
  try {
    await Supabase.initialize(
      url: 'https://ednovyqzrbaiyzlegbmy.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkbm92eXF6cmJhaXl6bGVnYm15Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTE1NDg3NCwiZXhwIjoyMDcwNzMwODc0fQ.piyUYeRXzwW1Wk0nSS76Y9eOm6_Frh9h7eFD81708XM',
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Supabase initialization error: $e');
  }
}
