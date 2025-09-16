import 'package:flutter/material.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/logger.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      _users = await _databaseService.getAllUsers();
      _filterUsers(); // Initial filtering
    } catch (e) {
      Logger.logError('Error loading users', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.displayName.toLowerCase().contains(query) ||
            (user.email?.toLowerCase().contains(query) ?? false) ||
            (user.phoneNumber?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Customers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterUsers();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('No customers found'))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return ListTile(
                            title: Text(user.displayName),
                            subtitle: Text(user.email ?? 'No email'),
                            onTap: () {
                              Navigator.pop(context, user);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
