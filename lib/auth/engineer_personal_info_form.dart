import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/engineer_registration_data.dart';
import 'package:jengamate/utils/validators.dart';
// Assuming CustomTextField is still used

class EngineerPersonalInfoForm extends StatefulWidget {
  final EngineerRegistrationData data;
  final VoidCallback onNext;

  const EngineerPersonalInfoForm({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  State<EngineerPersonalInfoForm> createState() =>
      _EngineerPersonalInfoFormState();
}

class _EngineerPersonalInfoFormState extends State<EngineerPersonalInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.data.firstName;
    _middleNameController.text = widget.data.middleName;
    _lastNameController.text = widget.data.lastName;
    _phoneNumberController.text = widget.data.phoneNumber;
    _selectedGender = widget.data.gender.isNotEmpty ? widget.data.gender : null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.data.dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != widget.data.dateOfBirth) {
      setState(() {
        widget.data.dateOfBirth = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.data.firstName = _firstNameController.text;
      widget.data.middleName = _middleNameController.text;
      widget.data.lastName = _lastNameController.text;
      widget.data.phoneNumber = _phoneNumberController.text;
      widget.data.gender = _selectedGender ?? '';
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name*'),
              validator: Validators.validateName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _middleNameController,
              decoration:
                  const InputDecoration(labelText: 'Middle Name (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name*'),
              validator: Validators.validateName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(labelText: 'Phone Number*'),
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhoneNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: widget.data.dateOfBirth == null
                    ? ''
                    : DateFormat('yyyy-MM-dd').format(widget.data.dateOfBirth!),
              ),
              decoration: InputDecoration(
                labelText: 'Date of Birth*',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please select your date of birth'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender*'),
              items: <String>['Male', 'Female', 'Other']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
              validator: (value) => value == null || value.isEmpty
                  ? 'Please select your gender'
                  : null,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
