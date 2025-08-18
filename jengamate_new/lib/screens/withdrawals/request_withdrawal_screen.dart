import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/withdrawal_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';

class RequestWithdrawalScreen extends StatefulWidget {
  const RequestWithdrawalScreen({super.key});

  @override
  State<RequestWithdrawalScreen> createState() =>
      _RequestWithdrawalScreenState();
}

class _RequestWithdrawalScreenState extends State<RequestWithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Withdrawal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'KES ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final currentUser = context.read<UserModel?>();
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'You must be logged in to make a withdrawal request.')),
                      );
                      return;
                    }
                    final amount = double.parse(_amountController.text);
                    final withdrawal = WithdrawalModel(
                      id: '',
                      amount: amount,
                      status: 'Pending',
                      createdAt: Timestamp.now(),
                      userId: currentUser.uid,
                    );
                    final dbService = DatabaseService();
                    dbService.requestWithdrawal(withdrawal);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Withdrawal request submitted successfully!')),
                    );
                  }
                },
                child: const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 