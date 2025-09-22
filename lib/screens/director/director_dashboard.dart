import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/customer_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_service.dart';
import '../../services/office_service.dart';
import '../../services/customer_service.dart';
import '../../services/user_service.dart';
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
  List<CustomerModel> _recentCustomers = [];
  List<UserModel> _recentUsers = [];
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

          // Load recent data
          _recentCustomers = await _getRecentCustomers();
          _recentUsers = await _getRecentUsers();
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

  // Get recent customers across all offices
  Future<List<CustomerModel>> _getRecentCustomers() async {
    try {
      final allOffices = await _officeService.getAllOffices();
      List<CustomerModel> allCustomers = [];

      for (final office in allOffices) {
        try {
          final officeCustomers = await _customerService.getCustomersByOffice(
            office.id,
          );
          allCustomers.addAll(officeCustomers);
        } catch (e) {
          // Continue if one office fails
        }
      }

      // Sort by creation date and get the most recent 10
      allCustomers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allCustomers.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  // Get recent users across all offices
  Future<List<UserModel>> _getRecentUsers() async {
    try {
      final allUsers = await _userService.getAllUsers();
      // Sort by creation date and get the most recent 10
      allUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allUsers.take(10).toList();
    } catch (e) {
      return [];
    }
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
              _showMessage('Notifications feature coming soon');
            },
            tooltip: 'Notifications',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showMessage('Profile feature coming soon');
                  break;
                case 'settings':
                  _showMessage('Settings feature coming soon');
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
          ),
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
        final isTablet =
            constraints.maxWidth > 600 && constraints.maxWidth <= 1200;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.purple.shade50, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Welcome & Date/Time
                _buildHeaderSection(isMobile),
                const SizedBox(height: 20),

                // Key Performance Metrics
                _buildMetricsSection(isMobile, isTablet),
                const SizedBox(height: 24),

                // Charts & Analytics Row
                if (!isMobile) ...[
                  _buildAnalyticsSection(isMobile, isTablet),
                  const SizedBox(height: 24),
                ],

                // Recent Activity & Quick Actions
                if (isMobile)
                  Column(
                    children: [
                      _buildRecentActivitySection(isMobile),
                      const SizedBox(height: 20),
                      _buildQuickActionsSection(isMobile),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildRecentActivitySection(isMobile),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildQuickActionsSection(isMobile),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200,
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 24 : 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  size: isMobile ? 24 : 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      _currentUser?.fullName ?? 'Director',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Director • ${_currentUser?.roleDisplayName ?? 'Director'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(bool isMobile, bool isTablet) {
    final officeStats = _stats?['office'] ?? {};
    final workStats = _stats?['work'] ?? {};
    final customerStats = _stats?['customer'] ?? {};

    final metrics = [
      {
        'title': 'Total Offices',
        'value': '${officeStats['totalOffices'] ?? 0}',
        'subtitle': '${officeStats['activeOffices'] ?? 0} Active',
        'icon': Icons.business,
        'color': Colors.blue,
        'trend': '+2.5%',
      },
      {
        'title': 'Total Users',
        'value': '${officeStats['total_users'] ?? 0}',
        'subtitle': 'All Roles',
        'icon': Icons.people,
        'color': Colors.green,
        'trend': '+5.1%',
      },
      {
        'title': 'Active Projects',
        'value': '${workStats['in_progress'] ?? 0}',
        'subtitle': 'In Progress',
        'icon': Icons.work,
        'color': Colors.orange,
        'trend': '+8.2%',
      },
      {
        'title': 'Total Customers',
        'value': '${customerStats['total_customers'] ?? 0}',
        'subtitle': '${customerStats['active'] ?? 0} Active',
        'icon': Icons.groups,
        'color': Colors.purple,
        'trend': '+12.3%',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Performance Indicators',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
            childAspectRatio: isMobile ? 1.1 : 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _buildEnhancedMetricCard(
              metric['title'] as String,
              metric['value'] as String,
              metric['subtitle'] as String,
              metric['icon'] as IconData,
              metric['color'] as Color,
              metric['trend'] as String,
              isMobile,
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String trend,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isMobile ? 20 : 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Overview',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: isMobile ? 200 : 250,
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Trends',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics,
                        size: isMobile ? 40 : 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chart View Coming Soon',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Analytics data will be displayed here',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              // Recent Customers
              _buildActivitySection(
                'Recent Customers',
                Icons.person_add,
                Colors.blue,
                _recentCustomers
                    .take(3)
                    .map(
                      (customer) => {
                        'title': customer.name,
                        'subtitle': 'Added ${_getTimeAgo(customer.createdAt)}',
                        'icon': Icons.person,
                      },
                    )
                    .toList(),
                isMobile,
              ),
              if (_recentCustomers.isNotEmpty && _recentUsers.isNotEmpty)
                Divider(color: Colors.grey.shade200, height: 24),
              // Recent Users
              _buildActivitySection(
                'Recent Users',
                Icons.group_add,
                Colors.green,
                _recentUsers
                    .take(3)
                    .map(
                      (user) => {
                        'title': user.fullName,
                        'subtitle':
                            '${user.roleDisplayName} • Added ${_getTimeAgo(user.createdAt)}',
                        'icon': Icons.account_circle,
                      },
                    )
                    .toList(),
                isMobile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(
    String title,
    IconData headerIcon,
    Color color,
    List<Map<String, dynamic>> items,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(headerIcon, color: color, size: isMobile ? 18 : 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No recent activity',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          )
        else
          ...items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: isMobile ? 16 : 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
      ],
    );
  }

  Widget _buildQuickActionsSection(bool isMobile) {
    final quickActions = [
      {
        'title': 'Add New Office',
        'icon': Icons.business,
        'color': Colors.blue,
        'action': () => _showAddOfficeDialog(),
      },
      {
        'title': 'View Reports',
        'icon': Icons.assessment,
        'color': Colors.green,
        'action': () => _navigateToReports(),
      },
      {
        'title': 'Manage Users',
        'icon': Icons.people,
        'color': Colors.orange,
        'action': () => _navigateToUserManagement(),
      },
      {
        'title': 'System Settings',
        'icon': Icons.settings,
        'color': Colors.purple,
        'action': () => _navigateToSettings(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: quickActions
                .map(
                  (action) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: action['action'] as VoidCallback,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (action['color'] as Color).withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  action['icon'] as IconData,
                                  color: action['color'] as Color,
                                  size: isMobile ? 18 : 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  action['title'] as String,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: isMobile ? 14 : 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  void _showAddOfficeDialog() {
    // Navigate to add office screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Office feature coming soon')),
    );
  }

  void _navigateToReports() {
    // Navigate to reports screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports feature coming soon')),
    );
  }

  void _navigateToUserManagement() {
    // Navigate to user management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User Management feature coming soon')),
    );
  }

  void _navigateToSettings() {
    // Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings feature coming soon')),
    );
  }
}
