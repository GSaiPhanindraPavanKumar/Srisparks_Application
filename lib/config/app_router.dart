import 'package:flutter/material.dart';
import '../auth/auth_screen.dart';
import '../screens/password_reset_screen.dart';
import '../screens/director/director_dashboard.dart' as director_screen;
import '../screens/manager/manager_dashboard.dart';
import '../screens/lead/lead_dashboard.dart';
import '../screens/employee/employee_dashboard.dart';
import '../screens/manager/assign_work_screen.dart';
import '../screens/director/assign_work_screen.dart' as director_assign;
import '../screens/shared/verify_work_screen.dart';
import '../screens/shared/customers_screen.dart';
import '../screens/shared/reports_screen.dart';
import '../screens/shared/my_team_screen.dart';
import '../screens/director/manage_users_screen.dart';
import '../screens/director/approve_users_screen.dart';
import '../screens/director/manage_offices_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/shared/settings_screen.dart';
import '../screens/shared/time_tracking_screen.dart';
import '../screens/shared/my_work_screen.dart';
import '../screens/manager/manage_work_screen.dart';
import '../screens/manager/stock_inventory_screen.dart';
import '../screens/director/director_stock_management_screen.dart';
import '../screens/lead/lead_stock_management_screen.dart';
import '../screens/director/director_attendance_management_screen.dart';
import '../screens/shared/attendance_screen.dart';
import '../screens/lead/team_attendance_screen.dart';
import '../screens/shared/customer_applications_screen.dart';
import '../screens/shared/create_customer_application_screen.dart';
import '../screens/shared/amount_phase_screen.dart';
import '../screens/shared/unified_customer_dashboard.dart';
import '../screens/director/director_unified_dashboard.dart';
import '../screens/manager/manager_unified_dashboard.dart';
import '../screens/lead/lead_unified_dashboard.dart';
import '../screens/employee/employee_unified_dashboard.dart';
import '../screens/employee/employee_customer_dashboard.dart';
import '../debug_amount_phase.dart';
import '../screens/shared/help_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AppRoutes {
  static const String auth = '/';
  static const String passwordReset = '/password-reset';
  static const String director = '/director';
  static const String directorOffices = '/director/offices';
  static const String directorUsers = '/director/users';
  static const String directorReports = '/director/reports';
  static const String manager = '/manager';
  static const String lead = '/lead';
  static const String employee = '/employee';
  static const String assignWork = '/assign-work';
  static const String directorAssignWork = '/director/assign-work';
  static const String verifyWork = '/verify-work';
  static const String customers = '/customers';
  static const String reports = '/reports';
  static const String myTeam = '/my-team';
  static const String manageUsers = '/manage-users';
  static const String approveUsers = '/approve-users';
  static const String manageOffices = '/manage-offices';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String timeTracking = '/time-tracking';
  static const String myWork = '/my-work';
  static const String manageWork = '/manage-work';
  static const String stockInventory = '/stock-inventory';
  static const String directorStockManagement = '/director/stock-management';
  static const String leadStockManagement = '/lead-stock-management';
  static const String directorAttendanceManagement =
      '/director/attendance-management';
  static const String attendance = '/attendance';
  static const String teamAttendance = '/team-attendance';
  static const String customerApplications = '/customer-applications';
  static const String createCustomerApplication =
      '/create-customer-application';
  static const String amountPhase = '/amount-phase';
  static const String unifiedCustomers = '/unified-customers';
  static const String directorUnifiedDashboard = '/director-unified-dashboard';
  static const String managerUnifiedDashboard = '/manager-unified-dashboard';
  static const String leadUnifiedDashboard = '/lead-unified-dashboard';
  static const String employeeUnifiedDashboard = '/employee-unified-dashboard';
  static const String employeeCustomerDashboard =
      '/employee-customer-dashboard';
  static const String debugAmountPhase = '/debug-amount-phase';
  static const String help = '/help';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.auth:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
          settings: settings,
        );

      case AppRoutes.passwordReset:
        return MaterialPageRoute(
          builder: (_) => const PasswordResetScreen(),
          settings: settings,
        );

      case AppRoutes.director:
        return MaterialPageRoute(
          builder: (_) => RouteGuard(
            child: director_screen.DirectorDashboard(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.directorOffices:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: ManageOfficesScreen(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.directorUsers:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: ManageUsersScreen(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.directorReports:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: ReportsScreen(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.manager:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: ManagerDashboard(),
            requiredRole: UserRole.manager,
          ),
          settings: settings,
        );

      case AppRoutes.lead:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: LeadDashboard(),
            requiredRole: UserRole.employee,
            requiresLead: true,
          ),
          settings: settings,
        );

      case AppRoutes.employee:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: EmployeeDashboard(),
            requiredRole: UserRole.employee,
          ),
          settings: settings,
        );

      case AppRoutes.assignWork:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: AssignWorkScreen(),
            requiresManagementRole: true,
          ),
          settings: settings,
        );

      case AppRoutes.directorAssignWork:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: director_assign.DirectorAssignWorkScreen(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.verifyWork:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: VerifyWorkScreen()),
          settings: settings,
        );

      case AppRoutes.customers:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: CustomersScreen()),
          settings: settings,
        );

      case AppRoutes.reports:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: ReportsScreen()),
          settings: settings,
        );

      case AppRoutes.myTeam:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: MyTeamScreen()),
          settings: settings,
        );

      case AppRoutes.manageUsers:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: ManageUsersScreen(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.approveUsers:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: ApproveUsersScreen(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.manageOffices:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: ManageOfficesScreen(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: ProfileScreen()),
          settings: settings,
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: SettingsScreen()),
          settings: settings,
        );

      case AppRoutes.timeTracking:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: TimeTrackingScreen()),
          settings: settings,
        );

      case AppRoutes.myWork:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: MyWorkScreen()),
          settings: settings,
        );

      case AppRoutes.manageWork:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: ManageWorkScreen(),
            requiresManagementRole: true,
          ),
          settings: settings,
        );

      case AppRoutes.stockInventory:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: StockInventoryScreen(),
            requiredRole: UserRole.manager,
          ),
          settings: settings,
        );

      case AppRoutes.directorStockManagement:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: DirectorStockManagementScreen(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.leadStockManagement:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: LeadStockManagementScreen(),
            requiredRole: UserRole.employee,
            requiresLead: true,
          ),
          settings: settings,
        );

      case AppRoutes.directorAttendanceManagement:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: DirectorAttendanceManagementScreen(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.attendance:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: AttendanceScreen(),
            // Allow all authenticated users to access attendance
          ),
          settings: settings,
        );

      case AppRoutes.teamAttendance:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: TeamAttendanceScreen(),
            requiresManagementRole:
                true, // Leads and Managers can view team attendance
          ),
          settings: settings,
        );

      case AppRoutes.customerApplications:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: CustomerApplicationsScreen()),
          settings: settings,
        );

      case AppRoutes.createCustomerApplication:
        return MaterialPageRoute(
          builder: (_) =>
              const RouteGuard(child: CreateCustomerApplicationScreen()),
          settings: settings,
        );

      case AppRoutes.amountPhase:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: AmountPhaseScreen(),
            requiresManagementRole: true, // Only directors and managers
          ),
          settings: settings,
        );

      case AppRoutes.unifiedCustomers:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: UnifiedCustomerDashboard()),
          settings: settings,
        );

      case AppRoutes.directorUnifiedDashboard:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: DirectorUnifiedDashboard(),
            requiredRole: UserRole.director,
          ),
          settings: settings,
        );

      case AppRoutes.managerUnifiedDashboard:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: ManagerUnifiedDashboard(),
            requiredRole: UserRole.manager,
          ),
          settings: settings,
        );

      case AppRoutes.leadUnifiedDashboard:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: LeadUnifiedDashboard(),
            requiredRole: UserRole.employee,
            requiresLead: true,
          ),
          settings: settings,
        );

      case AppRoutes.employeeUnifiedDashboard:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: EmployeeUnifiedDashboard(),
            requiredRole: UserRole.employee,
          ),
          settings: settings,
        );

      case AppRoutes.employeeCustomerDashboard:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: EmployeeCustomerDashboard(),
            requiredRole: UserRole.employee,
          ),
          settings: settings,
        );

      case AppRoutes.debugAmountPhase:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(
            child: DebugAmountPhase(),
            requiresManagementRole: true, // Only directors and managers
          ),
          settings: settings,
        );

      case AppRoutes.help:
        return MaterialPageRoute(
          builder: (_) => const RouteGuard(child: HelpScreen()),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
          settings: settings,
        );
    }
  }
}

// Route guard to check authentication and role
class RouteGuard extends StatelessWidget {
  final Widget child;
  final UserRole? requiredRole;
  final bool requiresLead;
  final bool requiresManagementRole;

  const RouteGuard({
    super.key,
    required this.child,
    this.requiredRole,
    this.requiresLead = false,
    this.requiresManagementRole = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AuthService().getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // User not authenticated, redirect to auth screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.auth);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user has required role
        if (requiredRole != null && user.role != requiredRole) {
          // User doesn't have required role, redirect to their dashboard
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final route = _getRedirectRoute(user);
            Navigator.pushReplacementNamed(context, route);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if route requires lead status
        if (requiresLead && !user.isLead) {
          // User is not a lead, redirect to their dashboard
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final route = _getRedirectRoute(user);
            Navigator.pushReplacementNamed(context, route);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if route requires management role (director, manager, or lead)
        if (requiresManagementRole) {
          final canManage =
              user.role == UserRole.director ||
              user.role == UserRole.manager ||
              (user.role == UserRole.employee && user.isLead);
          if (!canManage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final route = _getRedirectRoute(user);
              Navigator.pushReplacementNamed(context, route);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        }

        return child;
      },
    );
  }

  String _getRedirectRoute(UserModel user) {
    switch (user.role) {
      case UserRole.director:
        return AppRoutes.director;
      case UserRole.manager:
        return AppRoutes.manager;
      case UserRole.lead:
        return AppRoutes.lead;
      case UserRole.employee:
        return user.isLead ? AppRoutes.lead : AppRoutes.employee;
    }
  }
}

// 404 Not Found Screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            const Text(
              'The page you are looking for does not exist.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.auth);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
