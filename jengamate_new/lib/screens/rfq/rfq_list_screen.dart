import 'package:jengamate/config/app_route_builders.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';

class RFQListScreen extends StatelessWidget {
  const RFQListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final user = userState.currentUser;
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My RFQs'),
      ),
      body: user == null
          ? const Center(child: Text('Please log in to see your RFQs.'))
          : StreamBuilder<List<RFQModel>>(
              stream: dbService.streamUserRFQs(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('You have not submitted any RFQs.'));
                }

                final rfqs = snapshot.data!;

                return ListView.builder(
                  itemCount: rfqs.length,
                  itemBuilder: (context, index) {
                    final rfq = rfqs[index];
                    return ListTile(
                      title: Text(rfq.productName),
                      subtitle: Text('Status: ${rfq.status}'),
                      trailing: Text('Qty: ${rfq.quantity}'),
                      onTap: () {
                        // Navigate to RFQ details screen
                        final path = AppRouteBuilders.rfqDetailsPath(rfq.id);
                        context.go(path);
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
