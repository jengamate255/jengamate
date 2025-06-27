import 'package:flutter/material.dart';
import 'package:jengamate/models/stat_item.dart';
import 'package:jengamate/utils/theme.dart';

class StatCard extends StatelessWidget {
  final StatItem stat;

  const StatCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stat.color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: stat.color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
