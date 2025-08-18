import 'package:flutter/material.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class RFQManagementScreen extends StatefulWidget {
  const RFQManagementScreen({super.key});

  @override
  State<RFQManagementScreen> createState() => _RfqManagementScreenState();
}

class _RfqManagementScreenState extends State<RFQManagementScreen> {
  final _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFQ Management'),
      ),
      body: StreamBuilder<List<RFQModel>>(
        stream: _dbService.streamAllRFQs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final rfqs = snapshot.data ?? [];
          if (rfqs.isEmpty) {
            return const Center(child: Text('No RFQs found.'));
          }
          return ListView.builder(
            itemCount: rfqs.length,
            itemBuilder: (context, index) {
              final rfq = rfqs[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('RFQ ID: ${rfq.id}'),
                  subtitle: Text(
                      'User: ${rfq.userId} - ${DateFormat.yMd().add_jm().format(rfq.createdAt)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}