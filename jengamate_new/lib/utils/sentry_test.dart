import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryTestWidget extends StatelessWidget {
  const SentryTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sentry Error Monitoring Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Use these buttons to test Sentry error reporting:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Test handled exception
                    try {
                      throw Exception('Test handled exception for Sentry');
                    } catch (e, stackTrace) {
                      Sentry.captureException(e, stackTrace: stackTrace);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Handled exception sent to Sentry'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Test Handled Error'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Test unhandled exception
                    throw Exception('Test unhandled exception for Sentry');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Unhandled Error'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Test custom message
                Sentry.captureMessage(
                  'Test message from JengaMate app',
                  level: SentryLevel.info,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test message sent to Sentry'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Test Message'),
            ),
          ],
        ),
      ),
    );
  }
}
