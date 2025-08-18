import 'package:flutter/material.dart';
import 'package:jengamate/screens/chat/chat_screen.dart';

class InquiryDetailScreen extends StatelessWidget {
  final String inquiryId;
  final String currentUserId; // Placeholder for current user ID
  final String otherUserId; // Placeholder for the other user in the chat (supplier/engineer)

  const InquiryDetailScreen({
    Key? key,
    required this.inquiryId,
    required this.currentUserId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In a real application, you would fetch inquiry details here
    // and determine if the current user is a relevant participant (engineer or supplier)
    // to show the chat button. For this example, we'll assume visibility.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inquiry Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inquiry ID: $inquiryId', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text('Details about the inquiry would go here...'),
            // Add more inquiry details as needed

            const Spacer(), // Pushes the button to the bottom

            // Chat Button Integration
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        inquiryId: inquiryId,
                        currentUserId: currentUserId,
                        // In a real app, 'other_user_id' would be dynamically determined
                        // based on the inquiry participants (e.g., supplierId or engineerId)
                        // For now, using a placeholder.
                        // The ChatScreen needs to be updated to accept a receiverId or handle it internally.
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Open Inquiry Chat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}