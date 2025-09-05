import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';
import 'package:jengamate/ui/design_system/components/jm_form_field.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/models/enums/user_role.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String name;
  final String? company;
  final UserRole role;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.name,
    this.company,
    required this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final otp = _otpController.text.trim();

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // TODO: The verifyOTP method may need to be updated to handle user registration
      // with the new parameters, or a separate registration call is needed.
      final result = await authService.verifyOTP(
        widget.verificationId,
        otp,
      );

      if (result != null && result.user != null) {
        // TODO: Implement user creation in Firestore database.
        // The AuthService does not currently have a method to create user profiles.
        // A new method like `createUserProfile` should be added to `auth_service.dart`
        // or a separate `database_service.dart` to store user details.
        /* 
        await authService.createUserInDatabase(
          uid: result.user!.uid, 
          name: widget.name,
          phoneNumber: widget.phoneNumber,
          company: widget.company,
          role: widget.role,
        );
        */
        // Navigate to dashboard or pending approval screen
        context.go(AppRoutes.dashboard);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = widget.phoneNumber;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Verify OTP'),
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
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: JMCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(
                                  Icons.sms,
                                  size: 64,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: JMSpacing.lg),
                                const Text(
                                  'Enter Verification Code',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: JMSpacing.md),
                                Text(
                                  'We sent a 6-digit code to $phoneNumber',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: JMSpacing.xl),
                                JMFormField(
                                  controller: _otpController,
                                  label: 'OTP Code',
                                  prefixIcon: const Icon(Icons.lock),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(6),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter the OTP code';
                                    }
                                    if (value.trim().length != 6) {
                                      return 'OTP must be 6 digits';
                                    }
                                    if (!RegExp(r'^[0-9]{6}$')
                                        .hasMatch(value.trim())) {
                                      return 'Please enter a valid OTP code';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: JMSpacing.xl),
                                JMButton(
                                  onPressed: _isLoading ? null : _verifyOtp,
                                  isLoading: _isLoading,
                                  child: const Text('Verify OTP'),
                                ),
                                const SizedBox(height: JMSpacing.lg),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                      'Didn\'t receive code? Resend'),
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
