import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../config/app_router.dart';

class DirectorSidebar extends StatelessWidget {
  final UserModel? currentUser;
  final VoidCallback onLogout;

  const DirectorSidebar({
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
            decoration: const BoxDecoration(color: Colors.purple),
            accountName: Text(currentUser?.fullName ?? 'Director'),
            accountEmail: Text(currentUser?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.purple),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.director),
          ),
          ListTile(
            leading: const Icon(Icons.business_center),
            title: const Text('Customer Management'),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.directorUnifiedDashboard,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.manageUsers),
          ),
          ListTile(
            leading: const Icon(Icons.approval),
            title: const Text('Approve Users'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.approveUsers),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Assign Work'),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.directorAssignWork),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Manage Work'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.manageWork),
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
            leading: const Icon(Icons.bug_report),
            title: const Text('Debug Amount Phase'),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.debugAmountPhase),
          ),
          ListTile(
            leading: const Icon(Icons.location_city),
            title: const Text('Offices'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.manageOffices),
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Stock Management'),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.directorStockManagement),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Attendance Management'),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.directorAttendanceManagement,
            ),
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
