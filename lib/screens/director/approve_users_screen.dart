import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/user_service.dart';
import '../../services/office_service.dart';
import '../../services/auth_service.dart';

class ApproveUsersScreen extends StatefulWidget {
  const ApproveUsersScreen({super.key});

  @override
  State<ApproveUsersScreen> createState() => _ApproveUsersScreenState();
}

class _ApproveUsersScreenState extends State<ApproveUsersScreen> {
  final UserService _userService = UserService();
  final OfficeService _officeService = OfficeService();
  final AuthService _authService = AuthService();

  List<UserModel> _allPendingUsers = [];
  List<UserModel> _filteredPendingUsers = [];
  List<OfficeModel> _allOffices = [];
  Map<String, String> _officeNames = {}; // Map office ID to office name
  Map<String, String> _userNames = {}; // Map user ID to user name
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

  Future<void> _loadPendingUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _allPendingUsers = await _userService.getPendingUsers();

      // Fetch office names for pending users
      await _loadOfficeNames();

      // Fetch user names for "added by" users
      await _loadUserNames();

      _filterUsers();
    } catch (e) {
      _showMessage('Error loading pending users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOfficeNames() async {
    try {
      // Get unique office IDs from pending users
      final officeIds = _allPendingUsers
          .where((user) => user.officeId != null)
          .map((user) => user.officeId!)
          .toSet()
          .toList();

      if (officeIds.isNotEmpty) {
        final offices = await _officeService.getOfficesByIds(officeIds);
        _officeNames = {for (var office in offices) office.id: office.name};
      }
    } catch (e) {
      print('Error loading office names: $e');
    }
  }

  Future<void> _loadUserNames() async {
    try {
      // Get unique user IDs from "added by" field
      final userIds = _allPendingUsers
          .where((user) => user.addedBy != null)
          .map((user) => user.addedBy!)
          .toSet()
          .toList();

      if (userIds.isNotEmpty) {
        final users = await _userService.getUsersByIds(userIds);
        _userNames = {
          for (var user in users) user.id: user.fullName ?? user.email,
        };
      }
    } catch (e) {
      print('Error loading user names: $e');
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredPendingUsers = _allPendingUsers.where((user) {
        // Office filter for directors
        final matchesOffice =
            _selectedOfficeId == null ||
            _selectedOfficeId == 'all_offices' ||
            user.officeId == _selectedOfficeId;

        return matchesOffice;
      }).toList();
    });
  }

  Future<void> _approveUser(UserModel user) async {
    try {
      await _userService.approveUser(user.id);
      _showMessage('User approved successfully');
      _loadPendingUsers();
    } catch (e) {
      _showMessage('Error approving user: $e');
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject ${user.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _userService.rejectUser(user.id, reasonController.text);
        _showMessage('User rejected');
        _loadPendingUsers();
      } catch (e) {
        _showMessage('Error rejecting user: $e');
      }
    }
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
        title: const Text('Approve Users'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Office selector for directors
          if (_currentUser?.role == UserRole.director) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, color: Colors.orange),
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
                                color: Colors.orange,
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

          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPendingUsers.isEmpty
                ? const Center(
                    child: Text(
                      'No users pending approval',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPendingUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredPendingUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.role),
                  child: Text(
                    (user.fullName?.isNotEmpty == true)
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.roleDisplayName,
                        style: TextStyle(
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // User details
            if (user.phoneNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      user.phoneNumber!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Office name
            if (user.officeId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.business, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Office: ${_officeNames[user.officeId] ?? 'Unknown Office'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Added by
            if (user.addedBy != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_add, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Added by: ${_userNames[user.addedBy] ?? 'Unknown User'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Requested: ${user.createdAt.toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            if (user.isLead) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Requesting Lead Role',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejectUser(user),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approveUser(user),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
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
}
