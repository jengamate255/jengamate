import 'package:flutter/material.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/user_model.dart';
// import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:provider/provider.dart';

class CommissionManagementScreen extends StatefulWidget {
  const CommissionManagementScreen({super.key});

  @override
  State<CommissionManagementScreen> createState() => _CommissionManagementScreenState();
}

class _CommissionManagementScreenState extends State<CommissionManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _commissionRateController = TextEditingController();
  final _minPayoutController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadCommissionSettings();
  }

  Future<void> _loadCommissionSettings() async {
    try {
      final commission = await _dbService.streamCommissionRules().first;
      if (commission != null) {
        _commissionRateController.text = commission.direct.toString();
        _minPayoutController.text = commission.minPayoutThreshold.toString();
      }
    } catch (e) {
      print('Error loading commission settings: $e');
    }
  }

  Future<void> _updateCommissionSettings() async {
    try {
      final rate = double.tryParse(_commissionRateController.text) ?? 0.0;
      final minPayout = double.tryParse(_minPayoutController.text) ?? 0.0;
      
      await _dbService.updateCommissionRules(
        commissionRate: rate,
        minPayoutThreshold: minPayout,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission settings updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    
    if (currentUser?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Commission Management')),
        body: const Center(
          child: Text('Access denied. Admin privileges required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCommissionReport,
            tooltip: 'Export Commission Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commission Settings Card
            JMCard(
              child: Padding(
                padding: const EdgeInsets.all(JMSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commission Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: JMSpacing.md),
                    TextField(
                      controller: _commissionRateController,
                      decoration: const InputDecoration(
                        labelText: 'Commission Rate (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: JMSpacing.md),
                    TextField(
                      controller: _minPayoutController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Payout Threshold',
                        border: OutlineInputBorder(),
                        prefixText: 'TSh ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: JMSpacing.md),
                    JMButton(
                      onPressed: _updateCommissionSettings,
                      child: const Text('Update Settings'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: JMSpacing.lg),
            
            // Commission Overview
            Text(
              'Commission Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: JMSpacing.md),
            
            // User Commissions List - Temporarily disabled
            // StreamBuilder<List<UserModel>>(
            //   stream: _dbService.streamUsers(),
            const Center(child: Text('Commission management temporarily unavailable'))
            // builder: (context, snapshot) {
            //   if (snapshot.connectionState == ConnectionState.waiting) {
            //     return const Center(child: CircularProgressIndicator());
            //   }
            //
            //   if (!snapshot.hasData || snapshot.data!.isEmpty) {
            //     return const Center(child: Text('No users found'));
            //   }
            //
            //   final users = snapshot.data!;
            //
            //   return ListView.builder(
            //     shrinkWrap: true,
            //     physics: const NeverScrollableScrollPhysics(),
            //     itemCount: users.length,
            //     itemBuilder: (context, index) {
            //       final user = users[index];
            //       return _buildUserCommissionCard(user);
            //     },
            //   );
            // },
            // ),
          ],
        ),
      ),
    );
  }

  // Widget _buildUserCommissionCard(UserModel user) {
  //   return JMCard(
  //     margin: const EdgeInsets.only(bottom: JMSpacing.md),
  //     child: Padding(
  //       padding: const EdgeInsets.all(JMSpacing.md),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               CircleAvatar(
  //                 backgroundImage: user.profileImageUrl != null
  //                     ? NetworkImage(user.profileImageUrl!)
  //                     : null,
  //                 child: user.profileImageUrl == null
  //                     ? Text(user.name[0].toUpperCase())
  //                     : null,
  //               ),
  //               const SizedBox(width: JMSpacing.md),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       user.name,
  //                       style: Theme.of(context).textTheme.titleMedium,
  //                     ),
  //                     Text(
  //                       user.email,
  //                       style: Theme.of(context).textTheme.bodySmall,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               Text(
  //                 user.role.toString().split('.').last.toUpperCase(),
  //                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
  //                   color: Theme.of(context).primaryColor,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: JMSpacing.md),
  //
  //           // Commission Details
  //           StreamBuilder<CommissionModel?>(
  //             stream: _dbService.streamUserCommission(user.uid),
  //             builder: (context, commissionSnapshot) {
  //               if (commissionSnapshot.connectionState == ConnectionState.waiting) {
  //                 return const LinearProgressIndicator();
  //               }
  //
  //               final commission = commissionSnapshot.data;
  //
  //               return Row(
  //                 children: [
  //                   Expanded(
  //                     child: _buildCommissionStat(
  //                       'Total Earned',
  //                       'TSh ${commission?.total.toStringAsFixed(2) ?? '0.00'}',
  //                     ),
  //                   ),
  //                   Expanded(
  //                     child: _buildCommissionStat(
  //                       'Active',
  //                       'TSh ${commission?.active.toStringAsFixed(2) ?? '0.00'}',
  //                     ),
  //                   ),
  //                   Expanded(
  //                     child: _buildCommissionStat(
  //                       'Referral',
  //                       'TSh ${commission?.referral.toStringAsFixed(2) ?? '0.00'}',
  //                     ),
  //                   ),
  //                 ],
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCommissionStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _exportCommissionReport() async {
    // TODO: Implement Excel export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  @override
  void dispose() {
    _commissionRateController.dispose();
    _minPayoutController.dispose();
    super.dispose();
  }
}
