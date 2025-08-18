import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';

class RFQManagementScreen extends StatelessWidget {
  const RFQManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RFQ Management'),
      ),
      body: StreamBuilder<List<RFQModel>>(
        stream: dbService.streamAllRFQs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No RFQs have been submitted.'));
          }

          final rfqs = snapshot.data!;

          return ListView.builder(
            itemCount: rfqs.length,
            itemBuilder: (context, index) {
              final rfq = rfqs[index];
              return ListTile(
                title: Text(rfq.productName),
                subtitle: Text('From: ${rfq.customerName}'),
                trailing: Text('Status: ${rfq.status}'),
                onTap: () {
                  context.go('/rfqs/${rfq.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
