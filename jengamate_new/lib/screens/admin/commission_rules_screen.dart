import 'package:flutter/material.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/services/database_service.dart';

class CommissionRulesScreen extends StatefulWidget {
  const CommissionRulesScreen({super.key});

  @override
  State<CommissionRulesScreen> createState() => _CommissionRulesScreenState();
}

class _CommissionRulesScreenState extends State<CommissionRulesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  late Future<List<CommissionModel>> _commissionFuture;

  final _totalController = TextEditingController();
  final _directController = TextEditingController();
  final _referralController = TextEditingController();
  final _activeController = TextEditingController();
  final _minPayoutThresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commissionFuture = _dbService.getCommissionRules();
    _commissionFuture.then((commissions) {
      if (commissions.isNotEmpty) {
        final commission = commissions.first;
        _totalController.text = commission.total.toString();
        _directController.text = commission.direct.toString();
        _referralController.text = commission.referral.toString();
        _activeController.text = commission.active.toString();
        _minPayoutThresholdController.text =
            commission.minPayoutThreshold.toString();
      }
    });
  }

  @override
  void dispose() {
    _totalController.dispose();
    _directController.dispose();
    _referralController.dispose();
    _activeController.dispose();
    _minPayoutThresholdController.dispose();
    super.dispose();
  }

  void _saveCommissionRules() {
    if (_formKey.currentState?.validate() ?? false) {
      final newCommission = CommissionModel(
        id: 'rules',
        total: double.parse(_totalController.text),
        direct: double.parse(_directController.text),
        referral: double.parse(_referralController.text),
        active: double.parse(_activeController.text),
        updatedAt: DateTime.now(),
        userId: '',
        minPayoutThreshold: double.parse(_minPayoutThresholdController.text),
      );
      _dbService.updateCommissionRules({
        'commissionRate':
            newCommission.direct, // Assuming direct is the main rate
        'minPayoutThreshold': newCommission.minPayoutThreshold,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission rules saved successfully')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving commission rules: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Rules'),
      ),
      body: FutureBuilder<List<CommissionModel>>(
        future: _commissionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _totalController,
                  decoration: const InputDecoration(
                    labelText: 'Total Commission (%)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a total commission';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _directController,
                  decoration: const InputDecoration(
                    labelText: 'Direct Commission (%)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a direct commission';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referralController,
                  decoration: const InputDecoration(
                    labelText: 'Referral Commission (%)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a referral commission';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _activeController,
                  decoration: const InputDecoration(
                    labelText: 'Active Commission (%)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an active commission';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minPayoutThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Payout Threshold (TSH)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a minimum payout threshold';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveCommissionRules,
                  child: const Text('Save Commission Rules'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
