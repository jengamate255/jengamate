import 'package:flutter/material.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/screens/rfq/rfq_details_screen.dart';

class SupplierRfqListScreen extends StatelessWidget {
  const SupplierRfqListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RFQs for You'),
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
          final rfqs = snapshot.data ?? [];
          if (rfqs.isEmpty) {
            return const Center(child: Text('No RFQs found.'));
          }
          return ListView.builder(
            itemCount: rfqs.length,
            itemBuilder: (context, index) {
              final rfq = rfqs[index];
              return Card(
                child: ListTile(
                  title: Text(rfq.productName),
                  subtitle: Text('Quantity: ${rfq.quantity}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RfqDetailsScreen(rfqId: rfq.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}