import 'package:flutter/material.dart';
import 'package:jengamate/models/engineer_registration_data.dart';

class EngineerAccountInfoForm extends StatelessWidget {
  final EngineerRegistrationData registrationData;

  const EngineerAccountInfoForm({super.key, required this.registrationData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Email'),
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
          onSaved: (value) {
            registrationData.email = value;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Password'),
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          onSaved: (value) {
            registrationData.password = value;
          },
          obscureText: true,
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Confirm Password'),
          obscureText: true,
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Referral Code (Optional)'),
          onSaved: (value) {
            registrationData.referralCode = value;
          },
        ),
      ],
    );
  }
}
