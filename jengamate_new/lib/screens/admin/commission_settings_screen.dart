import 'package:flutter/material.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class CommissionSettingsScreen extends StatefulWidget {
  const CommissionSettingsScreen({super.key});

  @override
  State<CommissionSettingsScreen> createState() =>
      _CommissionSettingsScreenState();
}

class _CommissionSettingsScreenState extends State<CommissionSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  // Referral Commission Settings
  final TextEditingController _directCommissionPercentageController =
      TextEditingController();
  final TextEditingController _referralCommissionPercentageController =
      TextEditingController();
  final TextEditingController _referralLevelDepthController =
      TextEditingController();
  final TextEditingController _minimumActiveReferralsController =
      TextEditingController();
  final TextEditingController _referralLimitController =
      TextEditingController();
  final TextEditingController _maxReferralBonusAmountController =
      TextEditingController();
  final TextEditingController _commissionExpiryDaysController =
      TextEditingController();
  String _referralCommissionStatus = 'Enabled'; // Default value

  // Order Commission Settings
  final TextEditingController _minimumOrderValueController =
      TextEditingController();
  final TextEditingController _orderCommissionPercentageController =
      TextEditingController();
  final TextEditingController _orderCommissionCapController =
      TextEditingController();
  String _orderCommissionType = 'Percentage'; // Default value
  String _orderCommissionStatus = 'Enabled'; // Default value

  // Payout Settings
  final TextEditingController _minimumPayoutAmountController =
      TextEditingController();
  final TextEditingController _maximumPayoutAmountController =
      TextEditingController();
  String _autoPayoutStatus = 'Disabled'; // Default value
  String _payoutFrequency = 'Monthly'; // Default value

  @override
  void initState() {
    super.initState();
    _loadCommissionSettings();
  }

  Future<void> _loadCommissionSettings() async {
    try {
      final settings = await _databaseService
          .getCommissionRules(); // Reusing CommissionModel for settings
      if (settings != null) {
        setState(() {
          // Referral
          _directCommissionPercentageController.text =
              settings.direct.toStringAsFixed(2);
          _referralCommissionPercentageController.text =
              settings.referral.toStringAsFixed(2);
          _referralLevelDepthController.text =
              (settings.metadata?['referralLevelDepth'] as int? ?? 1)
                  .toString();
          _minimumActiveReferralsController.text =
              (settings.metadata?['minimumActiveReferrals'] as int? ?? 0)
                  .toString();
          _referralLimitController.text =
              (settings.metadata?['referralLimit'] as double? ?? 0.0)
                  .toStringAsFixed(2);
          _maxReferralBonusAmountController.text =
              (settings.metadata?['maxReferralBonusAmount'] as double? ?? 0.0)
                  .toStringAsFixed(2);
          _commissionExpiryDaysController.text =
              (settings.metadata?['commissionExpiryDays'] as int? ?? 30)
                  .toString();
          _referralCommissionStatus =
              (settings.metadata?['referralCommissionStatus'] as String? ??
                  'Enabled');

          // Order
          _minimumOrderValueController.text =
              (settings.metadata?['minimumOrderValue'] as double? ?? 0.0)
                  .toStringAsFixed(2);
          _orderCommissionPercentageController.text = settings.active
              .toStringAsFixed(2); // Reusing 'active' for order percentage
          _orderCommissionCapController.text =
              (settings.metadata?['orderCommissionCap'] as double? ?? 100.0)
                  .toStringAsFixed(2);
          _orderCommissionType =
              (settings.metadata?['orderCommissionType'] as String? ??
                  'Percentage');
          _orderCommissionStatus =
              (settings.metadata?['orderCommissionStatus'] as String? ??
                  'Enabled');

          // Payout
          _minimumPayoutAmountController.text =
              settings.minPayoutThreshold.toStringAsFixed(2);
          _maximumPayoutAmountController.text =
              (settings.metadata?['maximumPayoutAmount'] as double? ?? 1000.0)
                  .toStringAsFixed(2);
          _autoPayoutStatus =
              (settings.metadata?['autoPayoutStatus'] as String? ?? 'Disabled');
          _payoutFrequency =
              (settings.metadata?['payoutFrequency'] as String? ?? 'Monthly');
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading commission settings: $e')),
      );
    }
  }

  Future<void> _saveCommissionSettings() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedSettings = CommissionModel(
          id: 'rules', // Document ID for global settings
          userId: '',
          total: 0.0, // Not directly used for settings, but required by model
          direct: double.parse(_directCommissionPercentageController.text),
          referral: double.parse(_referralCommissionPercentageController.text),
          active: double.parse(_orderCommissionPercentageController
              .text), // Reusing for order percentage
          updatedAt: DateTime.now(),
          status: 'Active',
          minPayoutThreshold: double.parse(_minimumPayoutAmountController.text),
          metadata: {
            'referralLevelDepth': int.parse(_referralLevelDepthController.text),
            'minimumActiveReferrals':
                int.parse(_minimumActiveReferralsController.text),
            'referralLimit': double.parse(_referralLimitController.text),
            'maxReferralBonusAmount':
                double.parse(_maxReferralBonusAmountController.text),
            'commissionExpiryDays':
                int.parse(_commissionExpiryDaysController.text),
            'referralCommissionStatus': _referralCommissionStatus,
            'minimumOrderValue':
                double.parse(_minimumOrderValueController.text),
            'orderCommissionCap':
                double.parse(_orderCommissionCapController.text),
            'orderCommissionType': _orderCommissionType,
            'orderCommissionStatus': _orderCommissionStatus,
            'maximumPayoutAmount':
                double.parse(_maximumPayoutAmountController.text),
            'autoPayoutStatus': _autoPayoutStatus,
            'payoutFrequency': _payoutFrequency,
          },
        );
        await _databaseService.updateCommissionRules({
          'commissionRate': updatedSettings.active,
          'minPayoutThreshold': updatedSettings.minPayoutThreshold,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Commission settings saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _directCommissionPercentageController.dispose();
    _referralCommissionPercentageController.dispose();
    _referralLevelDepthController.dispose();
    _minimumActiveReferralsController.dispose();
    _referralLimitController.dispose();
    _maxReferralBonusAmountController.dispose();
    _commissionExpiryDaysController.dispose();
    _minimumOrderValueController.dispose();
    _orderCommissionPercentageController.dispose();
    _orderCommissionCapController.dispose();
    _minimumPayoutAmountController.dispose();
    _maximumPayoutAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Disable Sections'),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _referralCommissionStatus,
                            decoration: const InputDecoration(
                                labelText: 'Referral Commission Status'),
                            items: ['Enabled', 'Disabled'].map((status) {
                              return DropdownMenuItem(
                                  value: status, child: Text(status));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _referralCommissionStatus = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _orderCommissionStatus,
                            decoration: const InputDecoration(
                                labelText: 'Order Commission Status'),
                            items: ['Enabled', 'Disabled'].map((status) {
                              return DropdownMenuItem(
                                  value: status, child: Text(status));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _orderCommissionStatus = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildSectionTitle('Referral Commission Settings'),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildNumberField(
                                'Direct Commission Percentage',
                                _directCommissionPercentageController,
                                '%')),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildNumberField(
                                'Referral Commission Percentage',
                                _referralCommissionPercentageController,
                                '%')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildNumberField('Referral Level Depth',
                                _referralLevelDepthController)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildNumberField('Minimum Active Referrals',
                                _minimumActiveReferralsController)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildNumberField(
                                'Referral Limit', _referralLimitController)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildNumberField(
                                'Max Referral Bonus Amount',
                                _maxReferralBonusAmountController,
                                'TSH')),
                      ],
                    ),
                    _buildNumberField('Commission Expiry (Days)',
                        _commissionExpiryDaysController),
                  ],
                ),
              ),
            ),
            _buildSectionTitle('Order Commission Settings'),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildNumberField('Minimum Order Value',
                        _minimumOrderValueController, 'TSH'),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _orderCommissionType,
                            decoration: const InputDecoration(
                                labelText: 'Commission Type'),
                            items: ['Percentage', 'Fixed Amount'].map((type) {
                              return DropdownMenuItem(
                                  value: type, child: Text(type));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _orderCommissionType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildNumberField('Commission Percentage',
                                _orderCommissionPercentageController, '%')),
                      ],
                    ),
                    _buildNumberField(
                        'Commission Cap', _orderCommissionCapController, 'TSH'),
                  ],
                ),
              ),
            ),
            _buildSectionTitle('Payout Settings'),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildNumberField('Minimum Payout Amount',
                                _minimumPayoutAmountController, 'TSH')),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildNumberField('Maximum Payout Amount',
                                _maximumPayoutAmountController, 'TSH')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _autoPayoutStatus,
                            decoration:
                                const InputDecoration(labelText: 'Auto Payout'),
                            items: ['Enabled', 'Disabled'].map((status) {
                              return DropdownMenuItem(
                                  value: status, child: Text(status));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _autoPayoutStatus = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _payoutFrequency,
                            decoration: const InputDecoration(
                                labelText: 'Payout Frequency'),
                            items: [
                              'Daily',
                              'Weekly',
                              'Monthly',
                              'Quarterly',
                              'Annually'
                            ].map((frequency) {
                              return DropdownMenuItem(
                                  value: frequency, child: Text(frequency));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _payoutFrequency = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _saveCommissionSettings,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child:
                    const Text('Save Settings', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller,
      [String? suffix]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixText: suffix,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }
}
