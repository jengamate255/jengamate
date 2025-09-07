import 'package:jengamate/models/audit_log_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/ui/design_system/components/jm_form_field.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.returnRoute});

  final String? returnRoute;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Add timeout for login request
      final result = await authService
          .signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Check if login was successful
      if (result.user != null) {
        // Log the login action for audit trail
        try {
          final databaseService = DatabaseService();
          final auditLog = AuditLogModel(
              uid: 'audit_' + DateTime.now().millisecondsSinceEpoch.toString(),
              actorId: result.user!.uid,
              actorName: result.user!.displayName ??
                  result.user!.email ??
                  'Unknown User',
              action: 'LOGIN',
              targetType: 'USER',
              targetId: result.user!.uid,
              targetName: result.user!.displayName ??
                  result.user!.email ??
                  'Unknown User',
              timestamp: DateTime.now(),
              details: 'User logged into the system',
              metadata: {'email': result.user!.email, 'loginMethod': 'email'});
          await databaseService.createAuditLog(auditLog);
        } catch (e) {
          // Don't fail login if audit logging fails
          print('Failed to create login audit log: $e');
        }

        // Successful login - navigate to the return route if provided, otherwise to dashboard
        if (widget.returnRoute != null && widget.returnRoute!.isNotEmpty) {
          try {
            // Try to navigate to the return route
            context.go(widget.returnRoute!);
          } catch (e) {
            // If navigation fails, fall back to dashboard
            if (mounted) {
              context.go(AppRoutes.dashboard);
            }
          }
        } else {
          // Default to dashboard if no return route
          if (mounted) {
            context.go(AppRoutes.dashboard);
          }
        }
      } else {
        // This case should not happen with proper error handling in auth service
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      String errorMessage = 'Login failed';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Login timeout. Please try again.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AdaptivePadding(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: 'JengaMate app logo',
                    hint: 'Engineering services marketplace',
                    child: Icon(
                      Icons.engineering,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text(
                      'Welcome Back, Engineer',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Login subtitle',
                    child: Text(
                      'Log in to manage your commissions',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Semantics(
                    label: 'Email address input field',
                    hint: 'Enter your email address',
                    textField: true,
                    child: JMFormField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Password input field',
                    hint: 'Enter your password',
                    textField: true,
                    child: JMFormField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: _isLoading
                        ? Semantics(
                            label: 'Loading',
                            child: const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : Semantics(
                            button: true,
                            label: 'Log in to your account',
                            child: JMButton(
                              onPressed: _signIn,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login),
                                  SizedBox(width: 8),
                                  Text('Log In'),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    button: true,
                    label: 'Register with phone number',
                    hint: 'Navigate to phone registration',
                    child: JMButton(
                      onPressed: () => context.go(AppRoutes.phoneRegistration),
                      filled: false,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_android),
                          SizedBox(width: 8),
                          Text('Register with Phone Number'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: 'Register as engineer',
                    hint: 'Navigate to engineer registration',
                    child: TextButton(
                      onPressed: () =>
                          context.go(AppRoutes.engineerRegistration),
                      child: const Text('Register as Engineer',
                          style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
