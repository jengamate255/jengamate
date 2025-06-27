import 'package:flutter/material.dart';
import 'package:jengamate/models/stat_item.dart';
import 'package:jengamate/screens/dashboard/widgets/stat_card.dart';

class StatsGrid extends StatelessWidget {
  final String title;
  final List<StatItem> stats;

  const StatsGrid({super.key, required this.title, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            return StatCard(stat: stats[index]);
          },
        ),
      ],
    );
  }
}
