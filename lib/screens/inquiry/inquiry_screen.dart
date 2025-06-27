import 'package:flutter/material.dart';
import 'package:jengamate/models/inquiry_model.dart';
import 'package:jengamate/screens/inquiry/new_inquiry_screen.dart';
import 'package:jengamate/services/database_service.dart';

class InquiryScreen extends StatelessWidget {
  const InquiryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inquiries'),
      ),
      body: StreamBuilder<List<Inquiry>>(
        stream: dbService.getInquiriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have not made any inquiries yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final inquiries = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: inquiries.length,
            itemBuilder: (context, index) {
              final inquiry = inquiries[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(
                    inquiry.projectName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Delivering to: ${inquiry.deliveryAddress}\nTimeline: ${inquiry.timeline}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: true,
                  onTap: () {
                    // TODO: Navigate to inquiry detail screen
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NewInquiryScreen()),
          );
        },
        label: const Text('New Inquiry'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
