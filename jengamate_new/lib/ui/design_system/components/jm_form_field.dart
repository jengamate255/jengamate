import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JMFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;

  const JMFormField({
    super.key, 
    this.controller, 
    this.label, 
    this.hint, 
    this.keyboardType, 
    this.validator, 
    this.obscureText = false, 
    this.prefixIcon,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
