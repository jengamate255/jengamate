import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jengamate/widgets/tier_chip.dart';
import 'package:jengamate/services/commission_tier_service.dart';

class CommissionTiersScreen extends StatelessWidget {
  const CommissionTiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CommissionTierService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Tiers'),
        actions: [
          IconButton(
            tooltip: 'Seed Defaults',
            icon: const Icon(Icons.cloud_download),
            onPressed: () async {
              await service.seedDefaultsIfEmpty();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Defaults seeded (if empty).')),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, service),
        icon: const Icon(Icons.add),
        label: const Text('Add Tier'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Engineer Tiers'),
            const SizedBox(height: 8),
            StreamBuilder<List<CommissionTier>>(
              stream: service.streamTiers('engineer'),
              builder: (context, snapshot) {
                final tiers = snapshot.data ?? CommissionTierService.engineerTiers;
                return _TierList(
                  tiers: tiers,
                  onEdit: (t) => _showAddEditDialog(context, service, existing: t),
                  onDelete: (t) => _confirmDelete(context, service, t),
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Supplier Tiers'),
            const SizedBox(height: 8),
            StreamBuilder<List<CommissionTier>>(
              stream: service.streamTiers('supplier'),
              builder: (context, snapshot) {
                final tiers = snapshot.data ?? CommissionTierService.supplierTiers;
                return _TierList(
                  tiers: tiers,
                  onEdit: (t) => _showAddEditDialog(context, service, existing: t),
                  onDelete: (t) => _confirmDelete(context, service, t),
                );
              },
            ),
            const SizedBox(height: 24),
            _PreviewCalculator(service: service),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CommissionTierService service, CommissionTier t) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Tier'),
            content: Text('Delete ${t.badgeText}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    if (t.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete default (not persisted) tier.')),
      );
      return;
    }
    await service.deleteTier(t.id!);
  }

  Future<void> _showAddEditDialog(BuildContext context, CommissionTierService service, {CommissionTier? existing}) async {
    final formKey = GlobalKey<FormState>();
    final role = ValueNotifier<String>(existing?.role ?? 'engineer');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final badgeTextCtrl = TextEditingController(text: existing?.badgeText ?? '');
    final badgeColorCtrl = TextEditingController(text: existing?.badgeColor ?? 'bronze');
    final minProductsCtrl = TextEditingController(text: (existing?.minProducts ?? 0).toString());
    final minTotalValueCtrl = TextEditingController(text: (existing?.minTotalValue ?? 0).toString());
    final ratePercentCtrl = TextEditingController(text: (existing?.ratePercent ?? 0.02).toString());
    final orderCtrl = TextEditingController(text: (existing?.order ?? 0).toString());

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Tier' : 'Edit Tier'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: role,
                  builder: (_, value, __) => Row(
                    children: [
                      const Text('Role:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: value,
                        items: const [
                          DropdownMenuItem(value: 'engineer', child: Text('Engineer')),
                          DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
                        ],
                        onChanged: (v) => role.value = v ?? 'engineer',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _LabeledField(label: 'Name (key)', controller: nameCtrl, validator: _req),
                const SizedBox(height: 8),
                _LabeledField(label: 'Badge Text', controller: badgeTextCtrl, validator: _req),
                const SizedBox(height: 8),
                _LabeledField(label: 'Badge Color (bronze/silver/gold/platinum)', controller: badgeColorCtrl, validator: _req),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Min Products',
                  controller: minProductsCtrl,
                  validator: _intReq,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                ),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Min Total Value',
                  controller: minTotalValueCtrl,
                  validator: _doubleReq,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                ),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Rate Percent (e.g. 0.04)',
                  controller: ratePercentCtrl,
                  validator: _doubleReq,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Order',
                  controller: orderCtrl,
                  validator: _intReq,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final tier = CommissionTier(
                id: existing?.id,
                role: role.value,
                name: nameCtrl.text.trim(),
                badgeText: badgeTextCtrl.text.trim(),
                badgeColor: badgeColorCtrl.text.trim(),
                minProducts: int.parse(minProductsCtrl.text.trim()),
                minTotalValue: double.parse(minTotalValueCtrl.text.trim()),
                ratePercent: double.parse(ratePercentCtrl.text.trim()),
                order: int.parse(orderCtrl.text.trim()),
              );
              // Client-side validation mirroring server rules
              if (tier.name.isEmpty || tier.badgeText.isEmpty || tier.badgeColor.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in Name, Badge Text, and Badge Color.')),
                );
                return;
              }
              if (tier.minProducts < 0 || tier.minTotalValue < 0 || tier.order < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Min Products, Min Total Value, and Order must be non-negative.')),
                );
                return;
              }
              if (tier.ratePercent < 0 || tier.ratePercent > 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rate Percent must be between 0 and 1 (e.g., 0.05 for 5%).')),
                );
                return;
              }
              // Validation: prevent duplicate thresholds or order within role
              final current = await service.getTiers(tier.role).catchError((_) => <CommissionTier>[]);
              final conflict = current.any((t) =>
                  (existing == null || t.id != existing.id) &&
                  (t.minTotalValue == tier.minTotalValue || t.order == tier.order));
              if (conflict) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conflict: Another tier in this role has the same Min Total Value or Order.')),
                );
                return;
              }
              if (existing == null) {
                await service.createTier(tier);
              } else {
                await service.updateTier(tier);
              }
              Navigator.of(context).pop();
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _intReq(String? v) => (int.tryParse((v ?? '').trim()) == null) ? 'Enter an integer' : null;
  String? _doubleReq(String? v) => (double.tryParse((v ?? '').trim()) == null) ? 'Enter a number' : null;
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.4))),
      ],
    );
  }
}

class _TierList extends StatelessWidget {
  final List<CommissionTier> tiers;
  final void Function(CommissionTier tier)? onEdit;
  final void Function(CommissionTier tier)? onDelete;
  const _TierList({required this.tiers, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Sort by order then threshold for consistent display
    final sorted = [...tiers]..sort((a, b) {
      final oc = a.order.compareTo(b.order);
      if (oc != 0) return oc;
      return a.minTotalValue.compareTo(b.minTotalValue);
    });
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final t = sorted[index];
          // Conflict detection within this role list
          final hasDupThreshold = sorted.any((o) => !identical(o, t) && o.minTotalValue == t.minTotalValue);
          final hasDupOrder = sorted.any((o) => !identical(o, t) && o.order == t.order);
          return ListTile(
            title: Text(_titleCase(t.badgeText)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Min products: ${t.minProducts} • Min value: ${t.minTotalValue.toStringAsFixed(2)} • Rate: ${(t.ratePercent * 100).toStringAsFixed(1)}%'),
                if (hasDupThreshold || hasDupOrder)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Conflict: duplicate ${hasDupThreshold && hasDupOrder ? 'threshold & order' : hasDupThreshold ? 'threshold' : 'order'}',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                  ),
                  child: Text('Order: ${t.order}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                TierChip(text: _titleCase(t.name), color: _badgeColor(t.badgeColor)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: onEdit == null ? null : () => onEdit!(t),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.redAccent,
                  tooltip: 'Delete',
                  onPressed: (t.id == null || onDelete == null) ? null : () => onDelete!(t),
                ),
              ],
            ),
            onTap: onEdit == null ? null : () => onEdit!(t),
          );
        },
      ),
    );
  }
}

Color _badgeColor(String name) {
  switch (name.toLowerCase()) {
    case 'bronze':
      return const Color(0xFFCD7F32);
    case 'silver':
      return const Color(0xFFC0C0C0);
    case 'gold':
      return const Color(0xFFFFD700);
    case 'platinum':
      return const Color(0xFFE5E4E2);
    default:
      return Colors.blueGrey;
  }
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _PreviewCalculator extends StatefulWidget {
  final CommissionTierService service;
  const _PreviewCalculator({required this.service});

  @override
  State<_PreviewCalculator> createState() => _PreviewCalculatorState();
}

class _PreviewCalculatorState extends State<_PreviewCalculator> {
  final _amountCtrl = TextEditingController();
  double? _amount;
  String _role = 'engineer';

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preview Calculator', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Order/Quote Total Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => setState(() {
                      _amount = double.tryParse(v.replaceAll(',', ''));
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: 'engineer', child: Text('Engineer')),
                    DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'engineer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_amount != null)
              StreamBuilder<List<CommissionTier>>(
                stream: widget.service.streamTiers(_role),
                builder: (context, snapshot) {
                  final tiers = snapshot.data ?? (_role == 'engineer' ? CommissionTierService.engineerTiers : CommissionTierService.supplierTiers);
                  return _ResultBox(amount: _amount!, role: _role, tiers: tiers, service: widget.service);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final double amount;
  final String role;
  final List<CommissionTier> tiers;
  final CommissionTierService service;
  const _ResultBox({required this.amount, required this.role, required this.tiers, required this.service});

  @override
  Widget build(BuildContext context) {
    // Use live tiers when available; fall back to defaults. Use service to derive rate.
    final tier = service.findTierForAmount(amount, role, tiers);
    final percent = tier?.ratePercent ?? service.rateForAmount(amount, role, tiers);
    final commission = amount * percent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimated Commission: ${commission.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          Text('Applied rate: ${(percent * 100).toStringAsFixed(1)}%'),
          if (tier != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                TierChip(text: _titleCase(tier.badgeText), color: _badgeColor(tier.badgeColor)),
                const SizedBox(width: 8),
                Text('Tier: ${_titleCase(tier.name)}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
