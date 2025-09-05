import 'package:flutter/material.dart';
import 'package:jengamate/models/inquiry.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/ui/design_system/components/responsive_wrapper.dart'
    hide AdaptivePadding;
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';

class InquiryScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final DatabaseService dbService = DatabaseService();
  String _searchQuery = '';
  String? _selectedStatusFilter;
  // You can add more filter options here later, e.g., date range

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Inquiries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              setState(() {
                _selectedStatusFilter =
                    _selectedStatusFilter == null ? 'Pending' : null;
              });
            },
          ),
        ],
      ),
      body: AdaptivePadding(
        child: Column(
          children: [
            const SizedBox(height: JMSpacing.md),
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search inquiries...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(JMSpacing.sm),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            Expanded(
              child: StreamBuilder<List<Inquiry>>(
                stream:
                    dbService.streamInquiriesForUser(currentUser?.uid ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No inquiries found.'));
                  }

                  final inquiries = snapshot.data!.where((inquiry) {
                    return _searchQuery.isEmpty ||
                        inquiry.subject
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(JMSpacing.sm),
                    itemCount: inquiries.length,
                    itemBuilder: (context, index) {
                      final inquiry = inquiries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: JMSpacing.sm),
                        child: JMCard(
                          child: ListTile(
                            title: Text(inquiry.subject),
                            subtitle: Text(inquiry.status),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Navigate to inquiry details
                            },
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
      floatingActionButton: (currentUser?.role == UserRole.engineer ||
              currentUser?.role == UserRole.admin)
          ? FloatingActionButton.extended(
              heroTag: "newInquiryButton",
              label: const Text('New Inquiry'),
              icon: const Icon(Icons.add),
              onPressed: () => context.go(AppRoutes.newInquiry),
            )
          : null,
    );
  }
}
