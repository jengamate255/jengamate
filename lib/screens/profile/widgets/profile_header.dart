import 'package:flutter/material.dart';
import 'package:jengamate/utils/theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'jack master',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '@username',
                  style: TextStyle(fontSize: 14, color: AppTheme.subTextColor),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.subTextColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
