import 'package:flutter/material.dart';
import 'package:jengamate/auth/engineer_personal_info_form.dart';
import 'package:jengamate/auth/engineer_location_info_form.dart';
import 'package:jengamate/auth/engineer_account_info_form.dart';
import 'package:jengamate/models/engineer_registration_data.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';

class EngineerRegistrationScreen extends StatefulWidget {
  const EngineerRegistrationScreen({super.key});

  @override
  _EngineerRegistrationScreenState createState() =>
      _EngineerRegistrationScreenState();
}

class _EngineerRegistrationScreenState
    extends State<EngineerRegistrationScreen> {
  int _currentStep = 0;
  final EngineerRegistrationData _registrationData = EngineerRegistrationData();
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  void _onStepContinue() {
    final form = _formKeys[_currentStep].currentState;
    if (form != null && form.validate()) {
      form.save();
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });
      } else {
        _submitRegistration();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitRegistration() async {
    final authService = AuthService();
    final dbService = DatabaseService();

    final userCredential = await authService.registerWithEmailAndPassword(
      _registrationData.email!,
      _registrationData.password!,
    );

    if (userCredential != null) {
      final user = UserModel(
        uid: userCredential.user!.uid,
        email: _registrationData.email,
        firstName: _registrationData.firstName!,
        lastName: _registrationData.lastName!,
        role: UserRole.engineer,
      );

      await dbService.updateUser(user);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );

      context.go(AppRoutes.dashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: AdaptivePadding(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: JMCard(
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: JMSpacing.lg),
                    child: Row(
                      children: [
                        if (_currentStep > 0)
                          JMButton(
                            onPressed: details.onStepCancel,
                            filled: false,
                            child: const Text('Back'),
                          ),
                        const Spacer(),
                        JMButton(
                          onPressed: details.onStepContinue,
                          child: Text(_currentStep == 2 ? 'Complete Registration' : 'Next'),
                        ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Personal Information'),
                    content: Form(
                      key: _formKeys[0],
                      child: EngineerPersonalInfoForm(
                        registrationData: _registrationData,
                      ),
                    ),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: const Text('Location Information'),
                    content: Form(
                      key: _formKeys[1],
                      child: EngineerLocationInfoForm(
                        registrationData: _registrationData,
                      ),
                    ),
                    isActive: _currentStep >= 1,
                  ),
                  Step(
                    title: const Text('Account Information'),
                    content: Form(
                      key: _formKeys[2],
                      child: EngineerAccountInfoForm(
                        registrationData: _registrationData,
                      ),
                    ),
                    isActive: _currentStep >= 2,
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
