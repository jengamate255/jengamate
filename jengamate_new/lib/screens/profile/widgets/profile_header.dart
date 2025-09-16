import 'package:flutter/material.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';

import '../../../models/user_model.dart';
import '../../../models/enums/user_role.dart';
import '../../../services/commission_tier_service.dart';
import '../../../services/order_service.dart';
import '../../../services/quotation_service.dart';
import '../../../models/order_model.dart';
import '../../../models/quotation_model.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserModel?>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: SizedBox(
        width: double.infinity, // Ensure the row takes full available width
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: currentUser?.photoUrl != null
                  ? NetworkImage(currentUser!.photoUrl!) as ImageProvider
                  : null, // Use null for fallback to child widget
              child: currentUser?.photoUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser?.displayName ?? 'Anonymous',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.subTextColor),
                  ),
                ],
              ),
            ),
            // Commission tier badge
            _buildCommissionBadge(currentUser),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: AppTheme.subTextColor),
              onPressed: () {
                // Navigate to settings
              },
            ),
          ],
        ),
      ),
    );
    }

  Widget _buildCommissionBadge(UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    // In a real implementation, this would fetch actual order/quotation data
    return StreamBuilder<List<OrderModel>>(
      stream: user.role == UserRole.engineer 
        ? OrderService().getBuyerOrders(user.uid) 
        : OrderService().getSupplierOrders(user.uid),
      builder: (context, orderSnapshot) {
        if (!orderSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<List<Quotation>>(
          stream: user.role == UserRole.supplier 
            ? QuotationService().getSupplierQuotations(user.uid) 
            : QuotationService().getEngineerQuotations(user.uid),
          builder: (context, quotationSnapshot) {
            if (!quotationSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            CommissionTier? tier;
            if (user.role == UserRole.engineer) {
              tier = CommissionTierService.getEngineerTier(user, orderSnapshot.data!);
            } else if (user.role == UserRole.supplier) {
              tier = CommissionTierService.getSupplierTier(user, quotationSnapshot.data!);
            }

            if (tier == null) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getBadgeColor(tier.badgeColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tier.badgeText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getBadgeColor(String tier) {
    switch (tier) {
      case 'bronze':
        return const Color(0xFFCD7F32); // Bronze color
      case 'silver':
        return const Color(0xFFC0C0C0); // Silver color
      case 'gold':
        return const Color(0xFFFFD700); // Gold color
      case 'platinum':
        return const Color(0xFFE5E4E2); // Platinum color
      default:
        return AppTheme.primaryColor;
    }
  }
}
