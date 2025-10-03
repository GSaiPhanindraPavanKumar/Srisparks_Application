import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/user_service.dart';
import '../../services/office_service.dart';
import '../../services/auth_service.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  final UserService _userService = UserService();
  final OfficeService _officeService = OfficeService();
  final AuthService _authService = AuthService();

  List<UserModel> _teamMembers = [];
  List<OfficeModel> _allOffices = [];
  UserModel? _currentUser;
  bool _isLoading = true;

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
        // Load offices if user can manage users
        if (_canManageUsers) {
          _allOffices = await _officeService.getAllOffices();
        }
        await _loadTeamMembers();
      }
    } catch (e) {
      _showMessage('Error initializing screen: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamMembers() async {
    try {
      if (_currentUser != null) {
        _teamMembers = await _userService.getTeamMembers(_currentUser!.id);
      }
    } catch (e) {
      _showMessage('Error loading team members: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _canManageUsers {
    if (_currentUser == null) return false;
    return _currentUser!.role == UserRole.manager ||
        (_currentUser!.role == UserRole.employee && _currentUser!.isLead);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeamMembers,
          ),
        ],
      ),
      floatingActionButton: _canManageUsers
          ? FloatingActionButton(
              onPressed: _showAddUserDialog,
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teamMembers.isEmpty
          ? const Center(
              child: Text(
                'No team members found',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _teamMembers.length,
              itemBuilder: (context, index) {
                final member = _teamMembers[index];
                return _buildTeamMemberCard(member);
              },
            ),
    );
  }

  Widget _buildTeamMemberCard(UserModel member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(member.role),
          child: Text(
            (member.fullName?.isNotEmpty == true)
                ? member.fullName![0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          member.fullName ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDisplayRole(member),
              style: TextStyle(color: _getRoleColor(member.role)),
            ),
            Text(member.email, style: const TextStyle(color: Colors.grey)),
            if (member.phoneNumber != null)
              Text(
                member.phoneNumber!,
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: member.status == UserStatus.active
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            member.status.name.toUpperCase(),
            style: TextStyle(
              color: member.status == UserStatus.active
                  ? Colors.green
                  : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _showMemberDetails(member),
      ),
    );
  }

  String _getDisplayRole(UserModel member) {
    if (member.role == UserRole.employee && member.isLead) {
      return 'Employee - Lead';
    }
    return member.roleDisplayName;
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

  void _showMemberDetails(UserModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.fullName ?? 'Unknown User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Role', _getDisplayRole(member)),
            _buildDetailRow('Email', member.email),
            if (member.phoneNumber != null)
              _buildDetailRow('Phone', member.phoneNumber!),
            _buildDetailRow('Status', member.status.name.toUpperCase()),
            _buildDetailRow(
              'Joined',
              member.createdAt.toLocal().toString().split(' ')[0],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Member management features coming soon');
            },
            child: const Text('Manage'),
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
    if (_currentUser == null) {
      _showMessage('User information not available');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(
        currentUser: _currentUser!,
        allOffices: _allOffices,
        onUserAdded: () {
          _initializeScreen(); // Refresh the screen data
        },
      ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final UserModel currentUser;
  final List<OfficeModel> allOffices;
  final VoidCallback onUserAdded;

  const _AddUserDialog({
    required this.currentUser,
    required this.allOffices,
    required this.onUserAdded,
  });

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

  List<UserRole> _allowedRoles = [];

  @override
  void initState() {
    super.initState();
    _setAllowedRoles();
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

  void _setAllowedRoles() {
    // Managers can create employees only
    // Leads (employees with isLead=true) can create employees only
    if (widget.currentUser.role == UserRole.manager ||
        (widget.currentUser.role == UserRole.employee &&
            widget.currentUser.isLead)) {
      _allowedRoles = [UserRole.employee];
      _selectedRole = UserRole.employee;
    } else {
      // This shouldn't happen as we check _canManageUsers before showing dialog
      _allowedRoles = [UserRole.employee];
      _selectedRole = UserRole.employee;
    }
  }

  Future<void> _setDefaultOffice() async {
    // For managers and leads, default to their office
    if (widget.currentUser.officeId != null) {
      setState(() {
        _selectedOfficeId = widget.currentUser.officeId;
      });
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
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          const Text('Add Team Member'),
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

                // Role Selection (restricted for managers/leads)
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                  ),
                  items: _allowedRoles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(role).withValues(alpha: 0.1),
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

                // Leadership option removed - _isLead remains false

                // Office Selection (fixed for managers/leads)
                if (widget.allOffices.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedOfficeId,
                    decoration: const InputDecoration(
                      labelText: 'Office *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Office selection is required';
                      }
                      return null;
                    },
                    items: widget.allOffices
                        .where(
                          (office) => office.id == widget.currentUser.officeId,
                        )
                        .map((office) {
                          return DropdownMenuItem<String>(
                            value: office.id,
                            child: Text(office.name),
                          );
                        })
                        .toList(),
                    onChanged:
                        null, // Disabled - fixed to current user's office
                  ),
                  const SizedBox(height: 16),
                ],

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
                          'The user will receive login credentials via email and be added to your office.',
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
            backgroundColor: Colors.indigo,
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
              : const Text('Add Team Member'),
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
              'Team member "${_fullNameController.text.trim()}" created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onUserAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating team member: $e'),
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
