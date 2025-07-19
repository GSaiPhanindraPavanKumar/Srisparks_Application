import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class LeadSidebar extends StatelessWidget {
  final UserModel? currentUser;
  final VoidCallback onLogout;

  const LeadSidebar({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.teal),
            accountName: Text(currentUser?.fullName ?? 'Lead'),
            accountEmail: Text(currentUser?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.teal),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: const Text('My Work'),
            onTap: () => Navigator.pushNamed(context, '/my-work'),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Assign Work'),
            onTap: () => Navigator.pushNamed(context, '/assign-work'),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Manage Work'),
            onTap: () => Navigator.pushNamed(context, '/manage-work'),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('My Team'),
            onTap: () => Navigator.pushNamed(context, '/my-team'),
          ),
          ListTile(
            leading: const Icon(Icons.verified),
            title: const Text('Verify Work'),
            onTap: () => Navigator.pushNamed(context, '/verify-work'),
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Customers'),
            onTap: () => Navigator.pushNamed(context, '/customers'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
