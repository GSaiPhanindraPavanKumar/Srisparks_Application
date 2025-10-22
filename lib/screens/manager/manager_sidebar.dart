import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../config/app_router.dart';

class ManagerSidebar extends StatelessWidget {
  final UserModel? currentUser;
  final VoidCallback onLogout;

  const ManagerSidebar({
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
            decoration: const BoxDecoration(color: Colors.indigo),
            accountName: Text(currentUser?.fullName ?? 'Manager'),
            accountEmail: Text(currentUser?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.indigo),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.manager),
          ),
          ListTile(
            leading: const Icon(Icons.business_center),
            title: const Text('Customer Management'),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.managerUnifiedDashboard),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Assign Work'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.assignWork),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Manage Work'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.manageWork),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('My Team'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.myTeam),
          ),
          ListTile(
            leading: const Icon(Icons.verified),
            title: const Text('Verify Work'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.verifyWork),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Applications (Legacy)'),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.customerApplications),
          ),
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Amount Phase (Legacy)'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.amountPhase),
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Stock Management'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.stockInventory),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('My Attendance'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt),
            title: const Text('Team Attendance'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.teamAttendance),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Reports'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
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
