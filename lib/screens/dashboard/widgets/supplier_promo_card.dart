import 'package:flutter/material.dart';
import 'package:jengamate/utils/theme.dart';

class SupplierPromoCard extends StatelessWidget {
  const SupplierPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.accentColor.withAlpha((255 * 0.1).round()),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AppTheme.accentColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Become a Supplier',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Start selling your products/services!',
                     style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.accentColor.withAlpha((255 * 0.8).round())),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.accentColor, size: 16),
          ],
        ),
      ),
    );
  }
}
