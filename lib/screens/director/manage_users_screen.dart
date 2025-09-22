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
  List<UserModel> _pendingUsers = [];
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
        await _loadPendingUsers();
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

  Future<void> _loadPendingUsers() async {
    if (_currentUser?.role == UserRole.director) {
      try {
        _pendingUsers = await _userService.getPendingApprovalUsers();
      } catch (e) {
        print('Error loading pending users: $e');
      }
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
          // Pending approvals badge (Directors only)
          if (_currentUser?.role == UserRole.director &&
              _pendingUsers.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.pending_actions),
                  onPressed: _showAllPendingUsers,
                  tooltip: 'Pending Approvals',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_pendingUsers.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
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
    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(
        allOffices: _allOffices,
        onUserAdded: () {
          _loadUsers();
          Navigator.pop(context);
        },
      ),
    );
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

  Widget _buildPendingUserItem(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getRoleColor(user.role),
            radius: 20,
            child: Text(
              (user.fullName?.isNotEmpty ?? false)
                  ? user.fullName![0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName ?? 'Unknown User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  user.roleDisplayName,
                  style: TextStyle(
                    color: _getRoleColor(user.role),
                    fontSize: 14,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => _approveUser(user),
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: 'Approve',
              ),
              IconButton(
                onPressed: () => _rejectUser(user),
                icon: const Icon(Icons.cancel, color: Colors.red),
                tooltip: 'Reject',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(UserModel user) async {
    try {
      await _userService.approveUser(user.id);
      _showMessage('${user.fullName} approved successfully');
      await _loadPendingUsers();
      await _loadUsers();
    } catch (e) {
      _showMessage('Error approving user: $e');
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    String? rejectionReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject ${user.fullName}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to reject this user? This action cannot be undone and the user will not be able to access the system.',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
                hintText: 'Please provide a reason for rejection...',
              ),
              maxLines: 3,
              onChanged: (value) => rejectionReason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (rejectionReason?.trim().isEmpty ?? true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && rejectionReason != null) {
      try {
        await _userService.rejectUser(user.id, rejectionReason!);
        _showMessage('${user.fullName} rejected successfully');
        await _loadPendingUsers();
        await _loadUsers();
      } catch (e) {
        _showMessage('Error rejecting user: $e');
      }
    }
  }

  void _showAllPendingUsers() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'All Pending Approvals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _pendingUsers[index];
                    return _buildPendingUserItem(user);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final List<OfficeModel> allOffices;
  final VoidCallback onUserAdded;

  const _AddUserDialog({required this.allOffices, required this.onUserAdded});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserRole _selectedRole = UserRole.employee;
  String? _selectedOfficeId;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _isLead = false;

  @override
  void initState() {
    super.initState();
    _setDefaultOffice();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _setDefaultOffice() async {
    try {
      // Get current user to set default office for non-directors
      final currentUser = await AuthService().getCurrentUserProfile();
      if (currentUser != null && currentUser.role != UserRole.director) {
        // For non-directors, default to their office
        setState(() {
          _selectedOfficeId = currentUser.officeId;
        });
      } else if (widget.allOffices.isNotEmpty) {
        // For directors, default to first office in list (excluding 'all_offices')
        final firstOffice = widget.allOffices.first;
        setState(() {
          _selectedOfficeId = firstOffice.id;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add, color: Colors.purple),
          ),
          const SizedBox(width: 12),
          const Text('Add New User'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Full name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 10) {
                        return 'Enter a valid phone number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role Selection
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                        UserRole.director,
                        UserRole.manager,
                        UserRole.employee,
                      ].map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(
                                    role,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  _getRoleIcon(role),
                                  color: _getRoleColor(role),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(role.name.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (role) {
                    setState(() {
                      _selectedRole = role!;
                      // Reset leadership when role changes
                      if (_selectedRole != UserRole.employee) {
                        _isLead = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Leadership checkbox (only for employees)
                if (_selectedRole == UserRole.employee) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.supervisor_account,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Team Lead',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'This employee will have leadership responsibilities',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isLead,
                          onChanged: (value) {
                            setState(() {
                              _isLead = value;
                            });
                          },
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Office Selection
                if (widget.allOffices.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedOfficeId,
                    decoration: const InputDecoration(
                      labelText: 'Office *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // Office is required for non-director roles
                      if (_selectedRole != UserRole.director &&
                          (value == null || value.isEmpty)) {
                        return 'Office selection is required for ${_selectedRole.displayName}s';
                      }
                      return null;
                    },
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select Office'),
                      ),
                      ...widget.allOffices.map((office) {
                        return DropdownMenuItem<String>(
                          value: office.id,
                          child: Text(office.name),
                        );
                      }),
                    ],
                    onChanged: (officeId) {
                      setState(() {
                        _selectedOfficeId = officeId;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Reporting To (Supervisor)

                // Info message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The user will receive login credentials via email',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add User'),
        ),
      ],
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

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.director:
        return Icons.business_center;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.lead:
        return Icons.engineering;
      case UserRole.employee:
        return Icons.person;
    }
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        officeId: _selectedOfficeId,
        isLead: _isLead,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User "${_fullNameController.text.trim()}" created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUserAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
