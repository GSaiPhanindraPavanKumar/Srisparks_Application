import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_service.dart';
import '../../services/office_service.dart';
import '../../services/customer_service.dart';
import '../../services/user_service.dart';
import '../../config/app_router.dart';
import 'director_sidebar.dart';

class DirectorDashboard extends StatefulWidget {
  const DirectorDashboard({super.key});

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  final AuthService _authService = AuthService();
  final WorkService _workService = WorkService();
  final OfficeService _officeService = OfficeService();
  final CustomerService _customerService = CustomerService();
  final UserService _userService = UserService();

  UserModel? _currentUser;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUserProfile();

      if (_currentUser != null) {
        // Load statistics - Directors get all-office statistics
        Map<String, dynamic> workStats;
        Map<String, dynamic> officeStats;
        Map<String, dynamic> customerStats;

        if (_currentUser!.role == UserRole.director) {
          // Directors: Get statistics across all offices
          workStats = await _getDirectorWorkStatistics();
          officeStats = await _getDirectorOfficeStatistics();
          customerStats = await _getDirectorCustomerStatistics();
        } else {
          // This shouldn't happen in director dashboard, but safety check
          final officeId = _currentUser!.officeId ?? '';
          workStats = await _workService.getWorkStatistics(officeId);
          officeStats = await _officeService.getOfficeStatistics(officeId);
          customerStats = await _customerService.getCustomerStatistics(
            officeId,
          );
        }

        setState(() {
          _stats = {
            'work': workStats,
            'office': officeStats,
            'customer': customerStats,
          };
        });
      }
    } catch (e) {
      _showMessage('Error loading dashboard: $e');
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

  // Get combined statistics across all offices for directors
  Future<Map<String, dynamic>> _getDirectorOfficeStatistics() async {
    final allOffices = await _officeService.getAllOffices();

    int totalActiveOffices = 0;

    // Count active offices
    for (final office in allOffices) {
      if (office.isActive) {
        totalActiveOffices++;
      }
    }

    // Get total users count across ALL users (including directors with NULL office_id)
    int totalUsers = 0;
    try {
      final allUsers = await _userService.getAllUsers();
      // Count only active users
      totalUsers = allUsers
          .where((user) => user.status == UserStatus.active)
          .length;
    } catch (e) {
      // If direct query fails, fall back to summing office statistics
      for (final office in allOffices) {
        if (office.isActive) {
          try {
            final officeStats = await _officeService.getOfficeStatistics(
              office.id,
            );
            totalUsers += (officeStats['total_users'] as int? ?? 0);
          } catch (e) {
            // Continue if one office fails
          }
        }
      }
    }

    return {
      'totalOffices': allOffices.length,
      'activeOffices': totalActiveOffices,
      'total_users': totalUsers, // Now includes all users including directors
    };
  }

  // Get combined work statistics across all offices for directors
  Future<Map<String, dynamic>> _getDirectorWorkStatistics() async {
    final allOffices = await _officeService.getAllOffices();

    int totalPending = 0;
    int totalInProgress = 0;
    int totalCompleted = 0;

    for (final office in allOffices) {
      try {
        final workStats = await _workService.getWorkStatistics(office.id);
        totalPending += (workStats['pending'] as int? ?? 0);
        totalInProgress += (workStats['in_progress'] as int? ?? 0);
        totalCompleted += (workStats['completed'] as int? ?? 0);
      } catch (e) {
        // Continue if one office fails
      }
    }

    return {
      'pending': totalPending,
      'in_progress': totalInProgress, // This matches the UI expectation
      'completed': totalCompleted,
      'total': totalPending + totalInProgress + totalCompleted,
    };
  }

  // Get combined customer statistics across all offices for directors
  Future<Map<String, dynamic>> _getDirectorCustomerStatistics() async {
    final allOffices = await _officeService.getAllOffices();

    int totalCustomers = 0;
    int activeCustomers = 0;
    int inactiveCustomers = 0;

    for (final office in allOffices) {
      try {
        final customerStats = await _customerService.getCustomerStatistics(
          office.id,
        );
        totalCustomers += (customerStats['total_customers'] as int? ?? 0);
        activeCustomers += (customerStats['active_customers'] as int? ?? 0);
        inactiveCustomers += (customerStats['inactive_customers'] as int? ?? 0);
      } catch (e) {
        // Continue if one office fails
      }
    }

    return {
      'total_customers': totalCustomers, // Fix: Match expected key name
      'active': activeCustomers,
      'inactive': inactiveCustomers,
    };
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Director Dashboard'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
      drawer: DirectorSidebar(
        currentUser: _currentUser,
        onLogout: _handleLogout,
      ),
    );
  }

  Widget _buildDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 600;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Welcome, ${_currentUser?.fullName ?? 'Director'}',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Role: ${_currentUser?.roleDisplayName ?? 'Director'}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Key metrics
              Text(
                'Key Metrics',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMetricsGrid(isMobile),
              const SizedBox(height: 24),

              // Quick actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(bool isMobile) {
    final officeStats = _stats?['office'] ?? {};
    final workStats = _stats?['work'] ?? {};
    final customerStats = _stats?['customer'] ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 8 : 12,
      mainAxisSpacing: isMobile ? 8 : 12,
      childAspectRatio: isMobile ? 1.3 : 1.5,
      children: [
        _buildMetricCard(
          'Total Users',
          '${officeStats['total_users'] ?? 0}',
          Icons.people,
          Colors.blue,
          isMobile,
        ),
        _buildMetricCard(
          'Active Work',
          '${workStats['in_progress'] ?? 0}',
          Icons.work,
          Colors.orange,
          isMobile,
        ),
        _buildMetricCard(
          'Total Customers',
          '${customerStats['total_customers'] ?? 0}',
          Icons.business,
          Colors.green,
          isMobile,
        ),
        _buildMetricCard(
          'Completed Work',
          '${workStats['completed'] ?? 0}',
          Icons.check_circle,
          Colors.purple,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 6 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Icon(icon, size: isMobile ? 20 : 32, color: color),
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 8 : 12,
      mainAxisSpacing: isMobile ? 8 : 12,
      childAspectRatio: isMobile ? 1.1 : 1.2,
      children: [
        _buildActionCard(
          'Assign Work',
          Icons.assignment,
          Colors.indigo,
          () => Navigator.pushNamed(context, AppRoutes.directorAssignWork),
          isMobile,
        ),
        _buildActionCard(
          'Manage Users',
          Icons.people_outline,
          Colors.blue,
          () => Navigator.pushNamed(context, '/manage-users'),
          isMobile,
        ),
        _buildActionCard(
          'Approve Users',
          Icons.approval,
          Colors.orange,
          () => Navigator.pushNamed(context, '/approve-users'),
          isMobile,
        ),
        _buildActionCard(
          'View Reports',
          Icons.analytics,
          Colors.green,
          () => Navigator.pushNamed(context, '/reports'),
          isMobile,
        ),
        _buildActionCard(
          'Manage Offices',
          Icons.location_city,
          Colors.purple,
          () => Navigator.pushNamed(context, '/manage-offices'),
          isMobile,
        ),
        _buildActionCard(
          'Verify Work',
          Icons.verified,
          Colors.teal,
          () => Navigator.pushNamed(context, '/verify-work'),
          isMobile,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 6 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Icon(icon, size: isMobile ? 20 : 32, color: color),
              ),
              SizedBox(height: isMobile ? 4 : 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
