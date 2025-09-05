import 'package:jengamate/models/inquiry.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/screens/inquiry/inquiry_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/components/jm_skeleton.dart';

class InquiryListScreen extends StatelessWidget {
  const InquiryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inquiries'),
      ),
      body: StreamBuilder<List<Inquiry>>(
        stream: dbService.streamInquiriesForUser(currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AdaptivePadding(
              child: ListView.separated(
                itemCount: 6,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: JMSpacing.md),
                itemBuilder: (context, index) => const JMCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      JMSkeleton(height: 18, width: 180),
                      SizedBox(height: JMSpacing.xs),
                      JMSkeleton(height: 14, width: 240),
                    ],
                  ),
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final inquiries = snapshot.data ?? [];
          if (inquiries.isEmpty) {
            return const AdaptivePadding(
              child:
                  Center(child: Text('You have not made any inquiries yet.')),
            );
          }
          return AdaptivePadding(
            child: ListView.separated(
              itemCount: inquiries.length,
              separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.md),
              itemBuilder: (context, index) {
                final inquiry = inquiries[index];
                return JMCard(
                  child: ListTile(
                    title: Text('Inquiry #${inquiry.uid.substring(0, 8)}'),
                    subtitle: Text(
                        '${inquiry.products?.length ?? 0} products - ${inquiry.status}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              InquiryDetailsScreen(inquiry: inquiry),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
