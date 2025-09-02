import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/user_service.dart';
import '../../services/office_service.dart';
import '../../services/auth_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final UserService _userService = UserService();
  final OfficeService _officeService = OfficeService();
  final AuthService _authService = AuthService();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  List<OfficeModel> _allOffices = [];
  String _searchQuery = '';
  UserRole? _selectedRole;
  UserStatus? _selectedStatus;
  String? _selectedOfficeId;
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        // If director, load all offices for selection
        if (_currentUser!.role == UserRole.director) {
          _allOffices = await _officeService.getAllOffices();
          _selectedOfficeId =
              'all_offices'; // Default to all offices for directors
        }
        await _loadUsers();
      }
    } catch (e) {
      _showMessage('Error initializing screen: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _allUsers = await _userService.getAllUsers();
      _filteredUsers = _allUsers;
    } catch (e) {
      _showMessage('Error loading users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            (user.fullName?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesRole = _selectedRole == null || user.role == _selectedRole;
        final matchesStatus =
            _selectedStatus == null || user.status == _selectedStatus;

        // Office filter for directors
        final matchesOffice =
            _selectedOfficeId == null ||
            _selectedOfficeId == 'all_offices' ||
            user.officeId == _selectedOfficeId;

        return matchesSearch && matchesRole && matchesStatus && matchesOffice;
      }).toList();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          // Office selector for directors
          if (_currentUser?.role == UserRole.director) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Text(
                        'Office:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      value: _selectedOfficeId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        // Add "All Offices" option for directors
                        const DropdownMenuItem<String>(
                          value: 'all_offices',
                          child: Row(
                            children: [
                              Icon(
                                Icons.business_center,
                                size: 16,
                                color: Colors.purple,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'All Offices',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Add individual offices
                        ..._allOffices.map((office) {
                          return DropdownMenuItem<String>(
                            value: office.id,
                            child: Row(
                              children: [
                                const Icon(Icons.business, size: 16),
                                const SizedBox(width: 8),
                                Text(office.name),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue != _selectedOfficeId) {
                          setState(() {
                            _selectedOfficeId = newValue;
                          });
                          _filterUsers();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Search and filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterUsers();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Role filter
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Role',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Roles'),
                    ),
                    ...UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name.toUpperCase()),
                      );
                    }),
                  ],
                  onChanged: (role) {
                    setState(() {
                      _selectedRole = role;
                    });
                    _filterUsers();
                  },
                ),
                const SizedBox(height: 8),
                // Status filter
                DropdownButtonFormField<UserStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Status'),
                    ),
                    ...UserStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      );
                    }),
                  ],
                  onChanged: (status) {
                    setState(() {
                      _selectedStatus = status;
                    });
                    _filterUsers();
                  },
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            (user.fullName?.isNotEmpty ?? false)
                ? user.fullName![0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.fullName ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.roleDisplayName,
              style: TextStyle(color: _getRoleColor(user.role)),
            ),
            Text(user.email, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: user.status == UserStatus.active
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.status.name.toUpperCase(),
            style: TextStyle(
              color: user.status == UserStatus.active
                  ? Colors.green
                  : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.director:
        return Colors.purple;
      case UserRole.manager:
        return Colors.indigo;
      case UserRole.lead:
        return Colors.orange;
      case UserRole.employee:
        return Colors.green;
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName ?? 'Unknown User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Role', user.roleDisplayName),
            _buildDetailRow('Email', user.email),
            if (user.phoneNumber != null)
              _buildDetailRow('Phone', user.phoneNumber!),
            _buildDetailRow('Status', user.status.name.toUpperCase()),
            if (user.isLead) _buildDetailRow('Leadership', 'Team Lead'),
            _buildDetailRow(
              'Joined',
              user.createdAt.toLocal().toString().split(' ')[0],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (user.status == UserStatus.active)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deactivateUser(user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deactivate'),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _activateUser(user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Activate'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    _showMessage('Use the Create User API endpoint to add new users');
  }

  Future<void> _deactivateUser(UserModel user) async {
    try {
      await _userService.updateUserStatus(user.id, UserStatus.inactive);
      _showMessage('User deactivated successfully');
      _loadUsers();
    } catch (e) {
      _showMessage('Error deactivating user: $e');
    }
  }

  Future<void> _activateUser(UserModel user) async {
    try {
      await _userService.updateUserStatus(user.id, UserStatus.active);
      _showMessage('User activated successfully');
      _loadUsers();
    } catch (e) {
      _showMessage('Error activating user: $e');
    }
  }
}
