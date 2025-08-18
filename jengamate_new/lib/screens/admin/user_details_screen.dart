import 'package:flutter/material.dart';
import 'package:jengamate/models/enhanced_user.dart';

class UserDetailsScreen extends StatelessWidget {
  final EnhancedUser user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: (user.photoURL == null || user.photoURL!.isEmpty) && user.displayName.isNotEmpty
                    ? Text(user.displayName[0].toUpperCase(), style: const TextStyle(fontSize: 40))
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Name'),
                subtitle: Text(user.displayName),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(user.email),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone Number'),
                subtitle: Text(user.phoneNumber ?? 'Not provided'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Company'),
                // subtitle: Text(user.companyName ?? 'Not provided'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_user),
                title: const Text('Roles'),
                subtitle: Text(user.roles.join(', ')),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.toggle_on),
                title: const Text('Status'),
                subtitle: Text(user.isActive ? 'Active' : 'Inactive'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
