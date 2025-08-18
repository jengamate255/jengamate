import 'package:flutter/material.dart';
import 'package:jengamate/models/system_config_model.dart';
import 'package:jengamate/services/database_service.dart';

class SystemConfigurationScreen extends StatefulWidget {
  const SystemConfigurationScreen({super.key});

  @override
  State<SystemConfigurationScreen> createState() =>
      _SystemConfigurationScreenState();
}

class _SystemConfigurationScreenState extends State<SystemConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  late Future<SystemConfig> _configFuture;

  final _commissionRateController = TextEditingController();
  final _minimumWithdrawalController = TextEditingController();
  final _maxRfqsPerDayController = TextEditingController();
  bool _requireApprovalForNewUsers = false;

  @override
  void initState() {
    super.initState();
    _configFuture = _dbService.getSystemConfig();
    _configFuture.then((config) {
      _commissionRateController.text = config.commissionRate.toString();
      _minimumWithdrawalController.text = config.minimumWithdrawal.toString();
      _maxRfqsPerDayController.text = config.maxRfqsPerDay.toString();
      setState(() {
        _requireApprovalForNewUsers = config.requireApprovalForNewUsers;
      });
    });
  }

  @override
  void dispose() {
    _commissionRateController.dispose();
    _minimumWithdrawalController.dispose();
    _maxRfqsPerDayController.dispose();
    super.dispose();
  }

  void _saveConfiguration() {
    if (_formKey.currentState!.validate()) {
      final newConfig = SystemConfig(
        commissionRate: double.parse(_commissionRateController.text),
        minimumWithdrawal: double.parse(_minimumWithdrawalController.text),
        maxRfqsPerDay: int.parse(_maxRfqsPerDayController.text),
        requireApprovalForNewUsers: _requireApprovalForNewUsers,
      );
      _dbService.updateSystemConfig(newConfig).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving configuration: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration'),
      ),
      body: FutureBuilder<SystemConfig>(
        future: _configFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : double.infinity,
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                  children: [
                    Card(
                      elevation: isDesktop ? 4 : 2,
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Settings',
                              style: TextStyle(
                                fontSize: isDesktop ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _commissionRateController,
                              decoration: const InputDecoration(
                                labelText: 'Commission Rate (%)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a commission rate';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _minimumWithdrawalController,
                              decoration: const InputDecoration(
                                labelText: 'Minimum Withdrawal Amount',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a minimum withdrawal amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _maxRfqsPerDayController,
                              decoration: const InputDecoration(
                                labelText: 'Max RFQs per Day',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the max RFQs per day';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Require Approval for New Users'),
                              value: _requireApprovalForNewUsers,
                              onChanged: (value) {
                                setState(() {
                                  _requireApprovalForNewUsers = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isDesktop ? 16 : 12,
                          ),
                        ),
                        onPressed: _saveConfiguration,
                        child: Text(
                          'Save Configuration',
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}