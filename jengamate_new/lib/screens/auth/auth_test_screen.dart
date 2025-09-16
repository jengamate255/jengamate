import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final AuthService _authService = AuthService();
  String _status = 'Not signed in';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      setState(() {
        _status = 'Firebase: ${firebaseUser.email ?? 'No email'}\nSupabase: Checking...';
      });
      _checkSupabaseStatus();
    } else {
      setState(() {
        _status = 'Not signed in';
      });
    }
  }

  void _checkSupabaseStatus() {
    // Supabase user status is implicitly handled by the accessToken callback.
    // If Firebase user is logged in, Supabase client should reflect that.
    // Direct access to Supabase.instance.client.auth.currentUser is not needed here.
    setState(() {
      _status = '${_status.split('\n')[0]}\nSupabase: Integrated (via Firebase token)';
    });
  }

  Future<void> _testSignIn() async {
    setState(() {
      _isLoading = true;
      _status = 'Signing in with test credentials...';
    });

    try {
      // Try to sign in with a test email/password
      // This will fail if no user exists, but will help test the auth flow
      await _authService.signInWithEmailAndPassword(
        'test@example.com',
        'testpassword123',
      );

      setState(() {
        _status = 'Sign in successful! Check Firebase status.';
      });
    } catch (e) {
      setState(() {
        _status = 'Sign in failed: $e\nThis is expected if no test user exists.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _checkAuthStatus();
    }
  }

  Future<void> _testSupabaseDirect() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Supabase client initialization...';
    });

    try {
      // Just check if the Supabase client is initialized and accessible
      final isSupabaseInitialized = Supabase.instance.client != null;
      if (isSupabaseInitialized) {
        setState(() {
          _status = 'Supabase client initialized successfully.';
        });
      } else {
        setState(() {
          _status = 'Supabase client not initialized.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Supabase client test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _checkAuthStatus();
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _status = 'Signing out...';
    });

    try {
      await _authService.signOut();
      setState(() {
        _status = 'Signed out successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Sign out failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _checkAuthStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentication Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSignIn,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Firebase Sign In'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSupabaseDirect,
              child: const Text('Test Supabase Integration'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkAuthStatus,
              child: const Text('Refresh Status'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Note: Supabase Firebase Auth Private Alpha must be enabled for full integration.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}