import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';
import '../../services/role_service.dart';
import '../../models/enhanced_user.dart';
import '../../services/audit_log_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../models/enums/user_role.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final RoleService _roleService = RoleService();
  final AuditLogService _auditLogService = AuditLogService();
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
            tooltip: 'Add New User',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: StreamBuilder<List<EnhancedUser>>(
              stream: _roleService.streamAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = _filterUsers(snapshot.data!);
                
                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(users[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedRoleFilter,
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('All Roles'),
              ),
              ..._roleService.getAvailableRoles().map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRoleFilter = value ?? 'all';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(EnhancedUser user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () => context.go(AppRoutes.userDetails, extra: user),
        leading: CircleAvatar(
          backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
              ? NetworkImage(user.photoURL!)
              : null,
          child: (user.photoURL == null || user.photoURL!.isEmpty) &&
                  user.displayName.isNotEmpty
              ? Text(user.displayName[0].toUpperCase())
              : null,
        ),
        title: Text(user.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: user.roles.map((role) {
                return Chip(
                  label: Text(role),
                  backgroundColor: _getRoleColor(role),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(user, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit User'),
            ),
            const PopupMenuItem(
              value: 'roles',
              child: Text('Manage Roles'),
            ),
            const PopupMenuItem(
              value: 'permissions',
              child: Text('View Permissions'),
            ),
            const PopupMenuItem(
              value: 'audit',
              child: Text('Audit Log'),
            ),
            const PopupMenuItem(
              value: 'deactivate',
              child: Text('Deactivate User'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete User'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'moderator':
        return Colors.blue;
      case 'user':
        return Colors.green;
      case 'guest':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  List<EnhancedUser> _filterUsers(List<EnhancedUser> users) {
    return users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRole = _selectedRoleFilter == 'all' ||
          user.roles.contains(_selectedRoleFilter);

      return matchesSearch && matchesRole;
    }).toList();
  }

  void _handleUserAction(EnhancedUser user, String action) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'roles':
        _showRoleManagementDialog(user);
        break;
      case 'permissions':
        _showPermissionsDialog(user);
        break;
      case 'audit':
        _showAuditLogDialog(user);
        break;
      case 'deactivate':
        _deactivateUser(user);
        break;
      case 'delete':
        _deleteUser(user);
        break;

    }
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    List<String> selectedRoles = ['user'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isSubmitting = false;

          Future<void> submit() async {
            if (isSubmitting) return;
            if (!formKey.currentState!.validate()) return;
            setState(() => isSubmitting = true);
            try {
              // 1) Create auth user
              final cred = await _authService.registerWithEmailAndPassword(
                emailCtrl.text.trim(),
                passwordCtrl.text,
              );
              final uid = cred.user?.uid;
              if (uid == null) {
                throw Exception('Failed to obtain new user UID');
              }

              // 2) Create Firestore user document
              final model = UserModel(
                uid: uid,
                firstName: firstNameCtrl.text.trim(),
                lastName: lastNameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                companyName: companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
                role: _inferPrimaryRole(selectedRoles),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await _dbService.createUser(model);

              // 3) Assign roles array and claims via RoleService
              await _roleService.setUserRoles(uid, selectedRoles);

              // 4) Audit log
              final actor = _authService.currentUser;
              if (actor != null) {
                await _auditLogService.logAction(
                  actorId: actor.uid,
                  actorName: actor.displayName ?? 'Unknown Admin',
                  targetUserId: uid,
                  targetUserName: '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}',
                  action: 'created user',
                  details: {
                    'email': emailCtrl.text.trim(),
                    'roles': selectedRoles,
                  },
                );
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User created successfully')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create user: $e')),
                );
              }
            } finally {
              if (context.mounted) setState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            title: const Text('Add New User'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: lastNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final email = v.trim();
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Temporary Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: companyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Company (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _roleService.getAvailableRoles().map((role) {
                          return FilterChip(
                            label: Text(role),
                            selected: selectedRoles.contains(role),
                            onSelected: (sel) {
                              setState(() {
                                if (sel) {
                                  if (!selectedRoles.contains(role)) selectedRoles.add(role);
                                } else {
                                  selectedRoles.remove(role);
                                }
                                if (selectedRoles.isEmpty) selectedRoles = ['user'];
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : submit,
                child: isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create User'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditUserDialog(EnhancedUser user) {
    final nameController = TextEditingController(text: user.displayName);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final actor = _authService.currentUser;
              if (actor != null) {
                await _auditLogService.logAction(
                  actorId: actor.uid,
                  actorName: actor.displayName ?? 'Unknown Admin',
                  targetUserId: user.uid,
                  targetUserName: user.displayName,
                  action: 'edited user details',
                  details: {
                    'oldName': user.displayName,
                    'newName': nameController.text,
                    'oldEmail': user.email,
                    'newEmail': emailController.text,
                  },
                );
              }
              // Update user logic
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRoleManagementDialog(EnhancedUser user) {
    final availableRoles = _roleService.getAvailableRoles();
    final selectedRoles = List<String>.from(user.roles);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manage Roles'),
          content: SingleChildScrollView(
            child: Column(
              children: availableRoles.map((role) {
                return CheckboxListTile(
                  title: Text(role),
                  value: selectedRoles.contains(role),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedRoles.add(role);
                      } else {
                        selectedRoles.remove(role);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final actor = _authService.currentUser;
                if (actor != null) {
                  await _auditLogService.logAction(
                    actorId: actor.uid,
                    actorName: actor.displayName ?? 'Unknown Admin',
                    targetUserId: user.uid,
                    targetUserName: user.displayName,
                    action: 'changed roles',
                    details: {
                      'oldRoles': user.roles,
                      'newRoles': selectedRoles,
                    },
                  );
                }
                await _roleService.setUserRoles(user.uid, selectedRoles);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionsDialog(EnhancedUser user) {
    final permissions = _roleService.getUserPermissions(user.roles);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Permissions'),
        content: SingleChildScrollView(
          child: Column(
            children: permissions.entries.map((entry) {
              return ListTile(
                leading: Icon(
                  entry.value ? Icons.check_circle : Icons.cancel,
                  color: entry.value ? Colors.green : Colors.red,
                ),
                title: Text(entry.key),
                subtitle: Text(entry.value ? 'Granted' : 'Denied'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAuditLogDialog(EnhancedUser user) {
    context.go(
      AppRoutes.auditLog,
      extra: {'userId': user.uid, 'userName': user.displayName},
    );
  }

  void _deactivateUser(EnhancedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Are you sure you want to deactivate ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final actor = _authService.currentUser;
              if (actor != null) {
                await _auditLogService.logAction(
                  actorId: actor.uid,
                  actorName: actor.displayName ?? 'Unknown Admin',
                  targetUserId: user.uid,
                  targetUserName: user.displayName,
                  action: 'deactivated',
                );
              }
              // Deactivate user logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(EnhancedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final actor = _authService.currentUser;
              if (actor != null) {
                await _auditLogService.logAction(
                  actorId: actor.uid,
                  actorName: actor.displayName ?? 'Unknown Admin',
                  targetUserId: user.uid,
                  targetUserName: user.displayName,
                  action: 'deleted',
                );
              }
              // Delete user logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Helper to infer a primary role enum from selected roles array
UserRole _inferPrimaryRole(List<String> roles) {
  // Prefer admin > supplier > engineer > user > guest
  if (roles.contains('super_admin') || roles.contains('admin')) return UserRole.admin;
  if (roles.contains('supplier')) return UserRole.supplier;
  return UserRole.engineer;
}
