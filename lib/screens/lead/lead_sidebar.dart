import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../config/app_router.dart';

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
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.myWork);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Lead Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.lead);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Customer Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.leadUnifiedDashboard);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Assign Work'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.assignWork);
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Manage Work'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.manageWork);
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('My Team'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.myTeam);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('My Attendance'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.attendance);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt),
            title: const Text('Team Attendance'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.teamAttendance);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Stock Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.leadStockManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified),
            title: const Text('Verify Work'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.verifyWork);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Applications (Legacy)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.customerApplications);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.settings);
            },
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
