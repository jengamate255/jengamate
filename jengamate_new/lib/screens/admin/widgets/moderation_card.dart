import 'package:flutter/material.dart';
import 'package:jengamate/models/content_moderation_model.dart';
import 'package:jengamate/services/database_service.dart';

class ModerationCard extends StatelessWidget {
  final ModerationItem item;

  const ModerationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.contentType.toString().split('.').last.toUpperCase()}: ${item.contentId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'User: ${item.userId}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.contentType == ContentType.product)
              FutureBuilder<String?>(
                future: dbService.getProductImage(item.contentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.network(
                      snapshot.data!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            const SizedBox(height: 8),
            Text(item.content),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text('Approve'),
                  onPressed: () {
                    dbService.updateModerationStatus(item.id, 'approved');
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject'),
                  onPressed: () {
                    dbService.updateModerationStatus(item.id, 'rejected');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}