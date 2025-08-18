import 'package:flutter/material.dart';
import 'package:jengamate/models/engineer_registration_data.dart';

class EngineerLocationInfoForm extends StatelessWidget {
  final EngineerRegistrationData registrationData;

  const EngineerLocationInfoForm({super.key, required this.registrationData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Region'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your region';
            }
            return null;
          },
          onSaved: (value) {
            registrationData.region = value;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'City/Town'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your city/town';
            }
            return null;
          },
          onSaved: (value) {
            registrationData.city = value;
          },
        ),
      ],
    );
  }
}
