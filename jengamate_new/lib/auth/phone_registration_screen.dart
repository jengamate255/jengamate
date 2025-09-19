import 'package:jengamate/config/app_route_builders.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';
import 'package:jengamate/ui/design_system/components/jm_form_field.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/models/enums/user_role.dart';

class PhoneRegistrationScreen extends StatefulWidget {
  const PhoneRegistrationScreen({super.key});

  @override
  State<PhoneRegistrationScreen> createState() =>
      _PhoneRegistrationScreenState();
}

class _PhoneRegistrationScreenState extends State<PhoneRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  UserRole _selectedRole = UserRole.engineer;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final tanzanianPhoneRegex = RegExp(r'^(?:\+255|0)[67]\d{8}$');
    if (!tanzanianPhoneRegex.hasMatch(value)) {
      return 'Enter a valid Tanzanian phone number (e.g., 0712345678)';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phoneNumber = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final company = _companyController.text.trim();

    // Ensure phone number has country code
    String formattedPhone = phoneNumber;
    if (!phoneNumber.startsWith('+')) {
      formattedPhone = '+255${phoneNumber.substring(1)}'; // Default to Tanzania
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.sendOTP(
        formattedPhone,
        (verificationId) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          context.go(
            AppRouteBuilders.otpVerificationPath(verificationId),
            extra: {
              'phoneNumber': formattedPhone,
              'name': name,
              'company': company,
              'role': _selectedRole.toString().split('.').last,
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Phone Registration'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: AdaptivePadding(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: JMCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  label: 'Phone registration icon',
                                  child: const Icon(
                                    Icons.phone_android,
                                    size: 64,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: JMSpacing.lg),
                                Semantics(
                                  header: true,
                                  child: const Text(
                                    'Register with Phone',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: JMSpacing.md),
                                const Text(
                                  'We\'ll send you a verification code',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: JMSpacing.xl),
                                Semantics(
                                  label: 'Full name input field',
                                  hint: 'Enter your full name as registered',
                                  textField: true,
                                  child: JMFormField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    hint: 'Enter your full name',
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Please enter your name'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: JMSpacing.lg),
                                JMFormField(
                                  controller: _companyController,
                                  label: 'Company/Organization (Optional)',
                                  prefixIcon: const Icon(Icons.business),
                                ),
                                const SizedBox(height: JMSpacing.lg),
                                DropdownButtonFormField<UserRole>(
                                  value: _selectedRole,
                                  decoration: const InputDecoration(
                                    labelText: 'Role',
                                    prefixIcon: Icon(Icons.work),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: UserRole.values.map((role) {
                                    return DropdownMenuItem<UserRole>(
                                      value: role,
                                      child:
                                          Text(role.toString().split('.').last),
                                    );
                                  }).toList(),
                                  onChanged: (UserRole? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedRole = newValue;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: JMSpacing.lg),
                                Semantics(
                                  label: 'Phone number input field',
                                  hint:
                                      'Enter your phone number including country code',
                                  textField: true,
                                  child: JMFormField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    hint: '0712345678',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: const Icon(Icons.phone),
                                    validator: _validatePhone,
                                  ),
                                ),
                                const SizedBox(height: JMSpacing.xl),
                                Semantics(
                                  button: true,
                                  label: 'Send one-time password via SMS',
                                  child: JMButton(
                                    onPressed: _isLoading ? null : _sendOtp,
                                    isLoading: _isLoading,
                                    child: const Text('Send OTP'),
                                  ),
                                ),
                                const SizedBox(height: JMSpacing.lg),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: const Text(
                                      'Already have an account? Sign in'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
