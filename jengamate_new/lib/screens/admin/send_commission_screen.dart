import 'package:flutter/material.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/commission_tier_service.dart';

class SendCommissionScreen extends StatefulWidget {
  const SendCommissionScreen({super.key});

  @override
  State<SendCommissionScreen> createState() => _SendCommissionScreenState();
}

class _SendCommissionScreenState extends State<SendCommissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  final _tierService = CommissionTierService();

  final TextEditingController _userIdCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _baseAmountCtrl = TextEditingController();

  String _commissionType = 'Direct'; // Direct | Referral | Active
  UserRole _recipientRole = UserRole.engineer; // Engineer | Supplier

  bool _submitting = false;
  double? _appliedRate; // from auto-calc
  String? _appliedTierId; // from auto-calc
  bool _lockAmount = false; // prevents manual edits after auto-calc until unlocked

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _baseAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _openRecipientPicker() async {
    final selected = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final TextEditingController searchCtrl = TextEditingController();
        List<UserModel> results = [];
        bool loading = false;
        void performSearch(void Function(void Function()) setState) async {
          setState(() => loading = true);
          try {
            final list = await _db.searchUsers(
              roleName: _recipientRole.name,
              nameQuery: searchCtrl.text,
              limit: 25,
            );
            setState(() => results = list);
          } finally {
            setState(() => loading = false);
          }
        }

        return StatefulBuilder(
          builder: (context, setBSState) {
            bool bootstrapped = false;
            Future<void> bootstrap() async {
              if (bootstrapped) return;
              bootstrapped = true;
              await Future<void>.delayed(Duration.zero);
              // initial load for selected role
              try {
                setBSState(() => loading = true);
                final list = await _db.searchUsers(
                  roleName: _recipientRole.name,
                  nameQuery: null,
                  limit: 25,
                );
                setBSState(() => results = list);
              } finally {
                setBSState(() => loading = false);
              }
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trigger initial load
                    FutureBuilder(
                      future: bootstrap(),
                      builder: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Search by name or email',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => performSearch(setBSState),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => performSearch(setBSState),
                            icon: const Icon(Icons.search),
                            tooltip: 'Search',
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final u = results[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                            title: Text(u.displayName),
                            subtitle: Text(u.email ?? ''),
                            trailing: Text(u.role.name),
                            onTap: () => Navigator.of(context).pop(u),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _userIdCtrl.text = selected.uid;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final amount = double.parse(_amountCtrl.text.trim());
      final userId = _userIdCtrl.text.trim();

      // Map "type" to CommissionModel fields
      double direct = 0, referral = 0, active = 0;
      switch (_commissionType) {
        case 'Direct':
          direct = amount;
          break;
        case 'Referral':
          referral = amount;
          break;
        case 'Active':
          active = amount;
          break;
      }

      final commission = CommissionModel(
        id: '',
        userId: userId,
        total: amount,
        direct: direct,
        referral: referral,
        active: active,
        updatedAt: DateTime.now(),
        status: 'Pending',
        minPayoutThreshold: 0.0,
        metadata: {
          'source': 'admin_manual',
          'commissionType': _commissionType.toLowerCase(),
          'recipientRole': _recipientRole.name,
          if (_appliedRate != null) 'appliedRate': _appliedRate,
          if (_appliedTierId != null) 'appliedTierId': _appliedTierId,
          if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
        },
      );

      // Use validated method to ensure recipient exists and role is allowed
      await _db.addCommissionRecordValidated(commission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission sent successfully.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send commission: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserModel?>();
    if (currentUser == null || currentUser.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Send Commission')),
        body: const Center(child: Text('Admins only')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Commission'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Send commission directly to a user (supplier or engineer).',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _userIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Recipient User ID',
                      border: OutlineInputBorder(),
                      helperText: 'Enter the target userId (supplier or engineer)'
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'User ID is required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _openRecipientPicker,
                  icon: const Icon(Icons.person_search_outlined),
                  tooltip: 'Find User',
                )
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              value: _recipientRole,
              decoration: const InputDecoration(
                labelText: 'Recipient Role',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: UserRole.engineer, child: Text('Engineer')),
                DropdownMenuItem(value: UserRole.supplier, child: Text('Supplier')),
              ],
              onChanged: (val) => setState(() {
                _recipientRole = val ?? UserRole.engineer;
                // Clear selected user when role changes to enforce role-locking
                _userIdCtrl.clear();
                // Clear any previously applied tier info
                _appliedRate = null;
                _appliedTierId = null;
                _lockAmount = false;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Commission Type',
                border: OutlineInputBorder(),
              ),
              value: _commissionType,
              items: const [
                DropdownMenuItem(value: 'Direct', child: Text('Direct')),
                DropdownMenuItem(value: 'Referral', child: Text('Referral')),
                DropdownMenuItem(value: 'Active', child: Text('Active')),
              ],
              onChanged: (val) => setState(() => _commissionType = val ?? 'Direct'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _baseAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Base Amount (Order/Quote Total)',
                      border: OutlineInputBorder(),
                      helperText: 'Used to auto-calc commission from tiers',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final base = double.tryParse(_baseAmountCtrl.text.trim());
                      if (base == null || base <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid Base Amount to auto-calc')),
                        );
                        return;
                      }
                      // Get live tiers; fallback to defaults
                      final tiers = await _tierService.getTiers(_recipientRole.name).catchError((_) => <CommissionTier>[]);
                      final used = tiers.isNotEmpty
                          ? tiers
                          : (_recipientRole == UserRole.engineer
                              ? CommissionTierService.engineerTiers
                              : CommissionTierService.supplierTiers);
                      final tier = _tierService.findTierForAmount(base, _recipientRole.name, used);
                      final rate = tier?.ratePercent ?? 0.0;
                      final calc = base * rate;
                      setState(() {
                        _amountCtrl.text = calc.toStringAsFixed(2);
                        _appliedRate = rate;
                        _appliedTierId = tier?.id; // null for defaults
                        _lockAmount = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Applied tier rate ${(rate * 100).toStringAsFixed(1)}% -> Amount ${calc.toStringAsFixed(2)}')),
                      );
                    },
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Auto-calc from Tier'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _lockAmount,
                  onChanged: (v) => setState(() => _lockAmount = v),
                ),
                const Text('Auto-calc lock'),
              ],
            ),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (TSh)',
                border: OutlineInputBorder(),
              ),
              readOnly: _lockAmount,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required';
                final d = double.tryParse(v.trim());
                if (d == null || d <= 0) return 'Enter a valid positive amount';
                return null;
              },
            ),
            if (_appliedRate != null || _appliedTierId != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Applied from tiers: ${_appliedRate != null ? ((_appliedRate! * 100).toStringAsFixed(1) + '%') : ''}'
                      '${_appliedTierId != null ? ' • Tier ID: ' + _appliedTierId! : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('Send Commission'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
