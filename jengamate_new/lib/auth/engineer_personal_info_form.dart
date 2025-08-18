import 'package:flutter/material.dart';
import 'package:jengamate/models/engineer_registration_data.dart';

class EngineerPersonalInfoForm extends StatelessWidget {
  final EngineerRegistrationData registrationData;

  const EngineerPersonalInfoForm({super.key, required this.registrationData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'First Name'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your first name';
            }
            return null;
          },
          onSaved: (value) {
            registrationData.firstName = value;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Middle Name'),
          onSaved: (value) {
            registrationData.middleName = value;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Last Name'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your last name';
            }
            return null;
          },
          onSaved: (value) {
            registrationData.lastName = value;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Phone Number'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
          onSaved: (value) {
            registrationData.phoneNumber = value;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Date of Birth'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your date of birth';
            }
            return null;
          },
          onSaved: (value) {
            registrationData.dateOfBirth = value;
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Gender'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your gender';
            }
            return null;
          },
          onSaved: (value) {
            registrationData.gender = value;
          },
        ),
      ],
    );
  }
}
