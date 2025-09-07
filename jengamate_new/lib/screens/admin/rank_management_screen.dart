import 'package:flutter/material.dart';
import 'package:jengamate/models/rank_model.dart';
import 'package:jengamate/services/database_service.dart';

class RankManagementScreen extends StatefulWidget {
  const RankManagementScreen({super.key});

  @override
  State<RankManagementScreen> createState() => _RankManagementScreenState();
}

class _RankManagementScreenState extends State<RankManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minReferralsController = TextEditingController();
  final TextEditingController _commissionRateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  RankModel? _editingRank;

  @override
  void dispose() {
    _nameController.dispose();
    _minReferralsController.dispose();
    _commissionRateController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _minReferralsController.clear();
    _commissionRateController.clear();
    setState(() {
      _editingRank = null;
    });
  }

  void _editRank(RankModel rank) {
    setState(() {
      _editingRank = rank;
      _nameController.text = rank.name;
      _minReferralsController.text = rank.minimumReferrals.toString();
      _commissionRateController.text = rank.commissionRate.toString();
    });
  }

  Future<void> _saveRank() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newRank = RankModel(
          id: _editingRank?.id ?? '',
          name: _nameController.text,
          minimumReferrals: int.parse(_minReferralsController.text),
          commissionRate: double.parse(_commissionRateController.text),
        );

        if (_editingRank == null) {
          await _databaseService.addRank(newRank);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rank added successfully!')),
          );
        } else {
          await _databaseService.updateRank(newRank);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rank updated successfully!')),
          );
        }
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save rank: $e')),
        );
      }
    }
  }

  Future<void> _deleteRank(String rankId) async {
    try {
      await _databaseService.deleteRank(rankId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rank deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete rank: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rank Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingRank == null ? 'Create New Rank' : 'Edit Rank',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Rank Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a rank name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minReferralsController,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Referrals',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter minimum referrals';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_editingRank != null)
                            TextButton(
                              onPressed: _clearForm,
                              child: const Text('Cancel Edit'),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _saveRank,
                            child: Text(_editingRank == null ? 'Add Rank' : 'Update Rank'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<RankModel>>(
                stream: _databaseService.streamRanks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final ranks = snapshot.data ?? [];
                  if (ranks.isEmpty) {
                    return const Center(child: Text('No ranks found.'));
                  }
                  return ListView.builder(
                    itemCount: ranks.length,
                    itemBuilder: (context, index) {
                      final rank = ranks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(rank.name),
                          subtitle: Text(
                              'Min Referrals: ${rank.minimumReferrals} | Commission: ${rank.commissionRate}%'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editRank(rank),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteRank(rank.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}