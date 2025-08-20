import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jengamate/models/system_config_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Form controllers
  final _commissionRateController = TextEditingController();
  final _minimumWithdrawalController = TextEditingController();
  final _maxRfqsPerDayController = TextEditingController();
  bool _requireApprovalForNewUsers = true;
  
  // Additional settings
  final _referralBonusController = TextEditingController();
  final _maxOrderValueController = TextEditingController();
  final _systemMaintenanceController = TextEditingController();
  bool _enableReferralProgram = true;
  bool _enableNotifications = true;
  bool _enableAutoApproval = false;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _loadSystemConfig();
  }

  Future<void> _loadSystemConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await _databaseService.getSystemConfig();
      
      _commissionRateController.text = (config.commissionRate * 100).toStringAsFixed(1);
      _minimumWithdrawalController.text = config.minimumWithdrawal.toStringAsFixed(2);
      _maxRfqsPerDayController.text = config.maxRfqsPerDay.toString();
      _requireApprovalForNewUsers = config.requireApprovalForNewUsers;

      // Load additional settings from database or use sensible defaults
      _referralBonusController.text = config.referralBonus?.toStringAsFixed(2) ?? '25.00';
      _maxOrderValueController.text = config.maxOrderValue?.toStringAsFixed(2) ?? '10000.00';
      _systemMaintenanceController.text = config.maintenanceMessage ?? 'System maintenance in progress. Please check back later.';
      _enableReferralProgram = config.enableReferralProgram ?? true;
      _enableNotifications = config.enableNotifications ?? true;
      _enableAutoApproval = config.enableAutoApproval ?? false;
      _maintenanceMode = config.maintenanceMode ?? false;
      
      Logger.log('System configuration loaded successfully');
    } catch (e) {
      Logger.logError('Error loading system config', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading system configuration: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSystemConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final config = SystemConfig(
        commissionRate: double.parse(_commissionRateController.text) / 100,
        minimumWithdrawal: double.parse(_minimumWithdrawalController.text),
        maxRfqsPerDay: int.parse(_maxRfqsPerDayController.text),
        requireApprovalForNewUsers: _requireApprovalForNewUsers,
      );
      
      await _databaseService.updateSystemConfig(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('System configuration saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      Logger.log('System configuration saved successfully');
    } catch (e) {
      Logger.logError('Error saving system config', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving configuration: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      'Financial Settings',
                      Icons.account_balance,
                      [
                        _buildNumberField(
                          controller: _commissionRateController,
                          label: 'Commission Rate (%)',
                          hint: 'Enter commission rate (e.g., 10.0 for 10%)',
                          suffix: '%',
                          validator: (value) => _validatePercentage(value),
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          controller: _minimumWithdrawalController,
                          label: 'Minimum Withdrawal Amount',
                          hint: 'Enter minimum withdrawal amount',
                          prefix: 'TSh ',
                          validator: (value) => _validateAmount(value),
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          controller: _referralBonusController,
                          label: 'Referral Bonus Amount',
                          hint: 'Enter referral bonus amount',
                          prefix: 'TSh ',
                          validator: (value) => _validateAmount(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      'Business Rules',
                      Icons.business,
                      [
                        _buildNumberField(
                          controller: _maxRfqsPerDayController,
                          label: 'Maximum RFQs per Day',
                          hint: 'Enter maximum RFQs per user per day',
                          validator: (value) => _validateInteger(value),
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          controller: _maxOrderValueController,
                          label: 'Maximum Order Value',
                          hint: 'Enter maximum order value',
                          prefix: 'TSh ',
                          validator: (value) => _validateAmount(value),
                        ),
                        const SizedBox(height: 16),
                        _buildSwitchTile(
                          title: 'Require Approval for New Users',
                          subtitle: 'New users must be approved before they can place orders',
                          value: _requireApprovalForNewUsers,
                          onChanged: (value) => setState(() => _requireApprovalForNewUsers = value),
                        ),
                        _buildSwitchTile(
                          title: 'Enable Auto-Approval',
                          subtitle: 'Automatically approve users after identity verification',
                          value: _enableAutoApproval,
                          onChanged: (value) => setState(() => _enableAutoApproval = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      'Feature Settings',
                      Icons.settings,
                      [
                        _buildSwitchTile(
                          title: 'Enable Referral Program',
                          subtitle: 'Allow users to refer friends and earn bonuses',
                          value: _enableReferralProgram,
                          onChanged: (value) => setState(() => _enableReferralProgram = value),
                        ),
                        _buildSwitchTile(
                          title: 'Enable Push Notifications',
                          subtitle: 'Send push notifications to users',
                          value: _enableNotifications,
                          onChanged: (value) => setState(() => _enableNotifications = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      'System Maintenance',
                      Icons.build,
                      [
                        _buildSwitchTile(
                          title: 'Maintenance Mode',
                          subtitle: 'Enable maintenance mode to restrict access',
                          value: _maintenanceMode,
                          onChanged: (value) => setState(() => _maintenanceMode = value),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _systemMaintenanceController,
                          decoration: const InputDecoration(
                            labelText: 'Maintenance Message',
                            hintText: 'Enter message to display during maintenance',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: validator,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionButtons() {
    final buttonHeight = Responsive.getResponsiveButtonHeight(context);
    final spacing = Responsive.getResponsiveSpacing(context);

    return Responsive.isMobile(context)
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSystemConfig,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Configuration'),
                ),
              ),
              SizedBox(height: spacing),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to Defaults'),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSystemConfig,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Configuration'),
                  ),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Defaults'),
                  ),
                ),
              ),
            ],
          );
  }

  String? _validatePercentage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a percentage';
    }
    final percentage = double.tryParse(value);
    if (percentage == null) {
      return 'Please enter a valid number';
    }
    if (percentage < 0 || percentage > 100) {
      return 'Percentage must be between 0 and 100';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount < 0) {
      return 'Amount must be positive';
    }
    return null;
  }

  String? _validateInteger(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a number';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid integer';
    }
    if (number < 0) {
      return 'Number must be positive';
    }
    return null;
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all settings to their default values? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _setDefaultValues();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _setDefaultValues() {
    setState(() {
      // Set reasonable default values for a construction marketplace
      _commissionRateController.text = '5.0';  // 5% commission rate
      _minimumWithdrawalController.text = '100.00';  // TSh 100 minimum withdrawal
      _maxRfqsPerDayController.text = '10';  // 10 RFQs per day limit
      _referralBonusController.text = '50.00';  // TSh 50 referral bonus
      _maxOrderValueController.text = '50000.00';  // TSh 50,000 max order value
      _requireApprovalForNewUsers = true;
      _enableReferralProgram = true;
      _enableNotifications = true;
      _enableAutoApproval = false;
      _maintenanceMode = false;
      _systemMaintenanceController.text = 'System maintenance in progress. Please check back later.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings reset to recommended default values')),
    );
  }

  @override
  void dispose() {
    _commissionRateController.dispose();
    _minimumWithdrawalController.dispose();
    _maxRfqsPerDayController.dispose();
    _referralBonusController.dispose();
    _maxOrderValueController.dispose();
    _systemMaintenanceController.dispose();
    super.dispose();
  }
}
