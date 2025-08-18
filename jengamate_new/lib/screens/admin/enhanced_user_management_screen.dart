import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/enhanced_user.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:intl/intl.dart';

class EnhancedUserManagementScreen extends StatefulWidget {
  const EnhancedUserManagementScreen({super.key});

  @override
  State<EnhancedUserManagementScreen> createState() => _EnhancedUserManagementScreenState();
}

class _EnhancedUserManagementScreenState extends State<EnhancedUserManagementScreen> {
  late final DatabaseService dbService;
  final TextEditingController _searchController = TextEditingController();
  
  // Filter states
  String _searchQuery = '';
  UserRole? _selectedRole;
  String? _selectedStatus;
  bool? _isActive;
  bool _showSuspendedOnly = false;
  bool _showUnverifiedOnly = false;
  
  // Bulk selection
  final Set<String> _selectedUserIds = {};
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    dbService = DatabaseService();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced User Management'),
        actions: [
          if (_isSelecting)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelSelection,
            ),
          if (_isSelecting && _selectedUserIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showBulkDeleteDialog,
            ),
          IconButton(
            icon: Icon(_isSelecting ? Icons.check_circle : Icons.select_all),
            onPressed: _toggleSelectionMode,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: _buildFilterBar(),
        ),
      ),
      body: Column(
        children: [
          _buildStatsCards(),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, phone...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showAdvancedFilters,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Users', _selectedStatus == null && _selectedRole == null && !_showSuspendedOnly && !_showUnverifiedOnly, () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedRole = null;
                    _isActive = null;
                    _showSuspendedOnly = false;
                    _showUnverifiedOnly = false;
                  });
                }),
                _buildFilterChip('Engineers', _selectedRole == UserRole.engineer, () {
                  setState(() => _selectedRole = _selectedRole == UserRole.engineer ? null : UserRole.engineer);
                }),
                _buildFilterChip('Suppliers', _selectedRole == UserRole.supplier, () {
                  setState(() => _selectedRole = _selectedRole == UserRole.supplier ? null : UserRole.supplier);
                }),
                _buildFilterChip('Admins', _selectedRole == UserRole.admin, () {
                  setState(() => _selectedRole = _selectedRole == UserRole.admin ? null : UserRole.admin);
                }),
                _buildFilterChip('Pending', _selectedStatus == 'pending', () {
                  setState(() => _selectedStatus = _selectedStatus == 'pending' ? null : 'pending');
                }),
                _buildFilterChip('Suspended', _showSuspendedOnly, () {
                  setState(() => _showSuspendedOnly = !_showSuspendedOnly);
                }),
                _buildFilterChip('Unverified', _showUnverifiedOnly, () {
                  setState(() => _showUnverifiedOnly = !_showUnverifiedOnly);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onPressed(),
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<List<EnhancedUser>>(
      stream: dbService.streamEnhancedUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final users = snapshot.data!;
        final stats = _calculateStats(users);
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatCard('Total Users', users.length.toString(), Icons.people, Colors.blue),
              _buildStatCard('Active Users', stats['active'].toString(), Icons.check_circle, Colors.green),
              _buildStatCard('Suspended', stats['suspended'].toString(), Icons.block, Colors.red),
              _buildStatCard('Pending', stats['pending'].toString(), Icons.hourglass_empty, Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _calculateStats(List<EnhancedUser> users) {
    final now = DateTime.now();
    return {
      'active': users.where((u) => u.isActive).length,
      'suspended': users.where((u) => u.metadata['suspendedUntil'] != null && (u.metadata['suspendedUntil'] as Timestamp).toDate().isAfter(now)).length,
      'pending': users.where((u) => u.metadata['approvalStatus'] == 'pending').length,
    };
  }

  Widget _buildUserList() {
    return StreamBuilder<List<EnhancedUser>>(
      stream: dbService.streamEnhancedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        final users = _applyFilters(snapshot.data!);
        
        if (users.isEmpty) {
          return const Center(child: Text('No users match the current filters.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  List<EnhancedUser> _applyFilters(List<EnhancedUser> users) {
    return users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = user.displayName.toLowerCase().contains(query);
        final matchesEmail = user.email.toLowerCase().contains(query);
        final matchesPhone = user.phoneNumber?.toLowerCase().contains(query) ?? false;
        
        if (!matchesName && !matchesEmail && !matchesPhone) {
          return false;
        }
      }

      // Role filter
      if (_selectedRole != null && !user.hasRole(_selectedRole!.name)) {
        return false;
      }

      // Status filter
      if (_selectedStatus != null && user.metadata['approvalStatus'] != _selectedStatus) {
        return false;
      }

      // Active status filter
      if (_isActive != null && user.isActive != _isActive) {
        return false;
      }

      // Suspended users filter
      if (_showSuspendedOnly) {
        final now = DateTime.now();
        final suspendedUntil = user.metadata['suspendedUntil'];
        if (suspendedUntil == null || (suspendedUntil as Timestamp).toDate().isBefore(now)) {
          return false;
        }
      }

      // Unverified users filter
      if (_showUnverifiedOnly && (user.metadata['identityVerificationApproved'] ?? false)) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildUserCard(EnhancedUser user) {
    final isSelected = _selectedUserIds.contains(user.uid);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null
              ? (user.displayName.isNotEmpty
                  ? Text(user.displayName[0].toUpperCase())
                  : const Icon(Icons.person))
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildStatusBadge(user),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text('Roles: ${user.roles.join(', ').toUpperCase()}'),
            if (user.lastLoginAt != null)
              Text('Last login: ${DateFormat('MMM dd, yyyy').format(user.lastLoginAt!)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isSelecting)
              PopupMenuButton<String>(
                onSelected: (value) => _handleUserAction(value, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit User')),
                  const PopupMenuItem(value: 'suspend', child: Text('Suspend User')),
                  const PopupMenuItem(value: 'activate', child: Text('Reactivate User')),
                  const PopupMenuItem(value: 'approve', child: Text('Approve User')),
                  const PopupMenuItem(value: 'reject', child: Text('Reject User')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete User')),
                ],
              ),
            if (_isSelecting)
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedUserIds.add(user.uid);
                    } else {
                      _selectedUserIds.remove(user.uid);
                    }
                  });
                },
              ),
          ],
        ),
        onTap: () {
          if (_isSelecting) {
            setState(() {
              if (isSelected) {
                _selectedUserIds.remove(user.uid);
              } else {
                _selectedUserIds.add(user.uid);
              }
            });
          } else {
            _showUserDetailsDialog(user);
          }
        },
        onLongPress: () {
          if (!_isSelecting) {
            setState(() {
              _isSelecting = true;
              _selectedUserIds.add(user.uid);
            });
          }
        },
      ),
    );
  }

  Widget _buildStatusBadge(EnhancedUser user) {
    Color color;
    String text;
    final approvalStatus = user.metadata['approvalStatus'];
    final suspendedUntil = user.metadata['suspendedUntil'];

    if (!user.isActive) {
      color = Colors.grey;
      text = 'INACTIVE';
    } else if (suspendedUntil != null && (suspendedUntil as Timestamp).toDate().isAfter(DateTime.now())) {
      color = Colors.red;
      text = 'SUSPENDED';
    } else if (approvalStatus == 'approved') {
      color = Colors.green;
      text = 'APPROVED';
    } else if (approvalStatus == 'rejected') {
      color = Colors.red;
      text = 'REJECTED';
    } else {
      color = Colors.orange;
      text = 'PENDING';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAdvancedFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Filters'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                  Navigator.pop(context);
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['pending', 'approved', 'rejected'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  Navigator.pop(context);
                },
              ),
              SwitchListTile(
                title: const Text('Show Suspended Only'),
                value: _showSuspendedOnly,
                onChanged: (value) {
                  setState(() => _showSuspendedOnly = value);
                  Navigator.pop(context);
                },
              ),
              SwitchListTile(
                title: const Text('Show Unverified Only'),
                value: _showUnverifiedOnly,
                onChanged: (value) {
                  setState(() => _showUnverifiedOnly = value);
                  Navigator.pop(context);
                },
              ),
            ],
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

  void _showUserDetailsDialog(EnhancedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(user.email),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone'),
                subtitle: Text(user.phoneNumber ?? 'Not provided'),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Roles'),
                subtitle: Text(user.roles.join(', ').toUpperCase()),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Joined'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(user.createdAt)),
              ),
              if (user.lastLoginAt != null)
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Last Login'),
                  subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(user.lastLoginAt!)),
                ),
              if (user.metadata['suspendedUntil'] != null)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Suspended Until'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format((user.metadata['suspendedUntil'] as Timestamp).toDate())),
                ),
              if (user.metadata['suspensionReason'] != null)
                ListTile(
                  leading: const Icon(Icons.warning),
                  title: const Text('Suspension Reason'),
                  subtitle: Text(user.metadata['suspensionReason']),
                ),
            ],
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

  void _showDocumentViewer(String documentUrl, String userName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              AppBar(
                title: Text('$userName - Identity Document'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    documentUrl,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 50, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Failed to load document'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUserAction(String action, EnhancedUser user) {
    switch (action) {
      case 'view':
        _showUserDetailsDialog(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'suspend':
        _showSuspendUserDialog(user);
        break;
      case 'activate':
        _activateUser(user);
        break;
      case 'approve':
        _approveUser(user);
        break;
      case 'reject':
        _rejectUser(user);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
    }
  }

  void _showEditUserDialog(EnhancedUser user) {
    final nameController = TextEditingController(text: user.displayName);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber);
    final notesController = TextEditingController(text: user.metadata['notes']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Admin Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updatedUser = user.copyWith(
                  displayName: nameController.text,
                  email: emailController.text,
                  phoneNumber: phoneController.text,
                  metadata: {
                    ...user.metadata,
                    'notes': notesController.text,
                  },
                );
                
                await dbService.updateEnhancedUser(updatedUser);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating user: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSuspendUserDialog(EnhancedUser user) {
    final reasonController = TextEditingController();
    int suspensionDays = 7;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Suspend ${user.displayName}?'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: suspensionDays,
                decoration: const InputDecoration(labelText: 'Suspension Duration'),
                items: [
                  const DropdownMenuItem(value: 1, child: Text('1 day')),
                  const DropdownMenuItem(value: 3, child: Text('3 days')),
                  const DropdownMenuItem(value: 7, child: Text('1 week')),
                  const DropdownMenuItem(value: 30, child: Text('1 month')),
                  const DropdownMenuItem(value: 365, child: Text('1 year')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    suspensionDays = value;
                  }
                },
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Suspension Reason',
                  hintText: 'Enter reason for suspension',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final suspendedUntil = DateTime.now().add(Duration(days: suspensionDays));
                final updatedUser = user.copyWith(
                  isActive: false,
                  metadata: {
                    ...user.metadata,
                    'suspendedUntil': suspendedUntil,
                    'suspensionReason': reasonController.text,
                  },
                );
                
                await dbService.updateEnhancedUser(updatedUser);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User suspended for $suspensionDays days')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error suspending user: $e')),
                );
              }
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _activateUser(EnhancedUser user) async {
    try {
      final updatedUser = user.copyWith(
        isActive: true,
        metadata: {
          ...user.metadata,
          'suspendedUntil': null,
          'suspensionReason': null,
        },
      );
      await dbService.updateEnhancedUser(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User reactivated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reactivating user: $e')),
      );
    }
  }

  void _approveUser(EnhancedUser user) async {
    try {
      final updatedUser = user.copyWith(
        metadata: {
          ...user.metadata,
          'approvalStatus': 'approved',
        },
      );
      await dbService.updateEnhancedUser(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving user: $e')),
      );
    }
  }

  void _rejectUser(EnhancedUser user) async {
    try {
      final updatedUser = user.copyWith(
        metadata: {
          ...user.metadata,
          'approvalStatus': 'rejected',
        },
      );
      await dbService.updateEnhancedUser(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting user: $e')),
      );
    }
  }

  void _showDeleteUserDialog(EnhancedUser user) {
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
          TextButton(
            onPressed: () async {
              try {
                await dbService.deleteUser(user.uid);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting user: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) {
        _selectedUserIds.clear();
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelecting = false;
      _selectedUserIds.clear();
    });
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Delete Users'),
        content: Text('Are you sure you want to delete ${_selectedUserIds.length} users? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                for (final userId in _selectedUserIds) {
                  await dbService.deleteUser(userId);
                }
                Navigator.pop(context);
                setState(() {
                  _isSelecting = false;
                  _selectedUserIds.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted ${_selectedUserIds.length} users')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting users: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}