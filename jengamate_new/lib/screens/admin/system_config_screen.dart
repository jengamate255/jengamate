import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({Key? key}) : super(key: key);

  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends State<SystemConfigScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic> _config = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final doc =
          await _firestore.collection('system_config').doc('settings').get();
      if (doc.exists) {
        setState(() {
          _config = doc.data() ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _config = {
            'siteName': 'JengaMate',
            'siteDescription': 'Your trusted construction marketplace',
            'maxFileSize': 10,
            'allowedFileTypes': ['jpg', 'jpeg', 'png', 'pdf'],
            'maintenanceMode': false,
            'contactEmail': 'support@jengamate.com',
            'contactPhone': '+254700000000',
            'defaultCurrency': 'KES',
            'commissionEnabled': true,
            'withdrawalEnabled': true,
            'minWithdrawalAmount': 1000,
            'maxWithdrawalAmount': 100000,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading config: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('system_config').doc('settings').set(_config);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving config: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildConfigField(String key, String label,
      {String? hint, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: _config[key]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onChanged: (value) {
          setState(() {
            _config[key] = isNumber ? double.tryParse(value) ?? 0 : value;
          });
        },
      ),
    );
  }

  Widget _buildSwitchField(String key, String label) {
    return SwitchListTile(
      title: Text(label),
      value: _config[key] ?? false,
      onChanged: (value) {
        setState(() {
          _config[key] = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveConfig,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'General Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildConfigField('siteName', 'Site Name'),
            _buildConfigField('siteDescription', 'Site Description'),
            _buildConfigField('contactEmail', 'Contact Email',
                hint: 'support@example.com'),
            _buildConfigField('contactPhone', 'Contact Phone',
                hint: '+254700000000'),
            _buildConfigField('defaultCurrency', 'Default Currency',
                hint: 'KES'),
            const SizedBox(height: 20),
            const Text(
              'File Upload Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildConfigField('maxFileSize', 'Max File Size (MB)',
                isNumber: true),
            _buildConfigField('allowedFileTypes', 'Allowed File Types',
                hint: 'jpg,jpeg,png,pdf'),
            const SizedBox(height: 20),
            const Text(
              'Feature Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildSwitchField('commissionEnabled', 'Enable Commission System'),
            _buildSwitchField('withdrawalEnabled', 'Enable Withdrawals'),
            _buildConfigField(
                'minWithdrawalAmount', 'Minimum Withdrawal Amount',
                isNumber: true),
            _buildConfigField(
                'maxWithdrawalAmount', 'Maximum Withdrawal Amount',
                isNumber: true),
            _buildSwitchField('maintenanceMode', 'Maintenance Mode'),
          ],
        ),
      ),
    );
  }
}
