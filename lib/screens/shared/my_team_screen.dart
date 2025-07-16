import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  List<UserModel> _teamMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await _authService.getCurrentUserProfile();
      if (currentUser != null) {
        _teamMembers = await _userService.getTeamMembers(currentUser.id);
      }
    } catch (e) {
      _showMessage('Error loading team members: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
}
