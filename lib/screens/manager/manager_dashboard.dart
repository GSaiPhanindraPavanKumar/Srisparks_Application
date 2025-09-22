import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/customer_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_service.dart';
import '../../services/customer_service.dart';
import '../../services/user_service.dart';
import '../../widgets/loading_widget.dart';
import 'manager_sidebar.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final AuthService _authService = AuthService();
  final WorkService _workService = WorkService();
  final CustomerService _customerService = CustomerService();
  final UserService _userService = UserService();

  UserModel? _currentUser;
  Map<String, dynamic>? _stats;
  List<CustomerModel> _recentCustomers = [];
  List<UserModel> _recentTeamMembers = [];
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
        // Load work statistics for the office
        final workStats = await _workService.getWorkStatistics(
          _currentUser!.officeId!,
        );
        final customerStats = await _customerService.getCustomerStatistics(
          _currentUser!.officeId!,
        );

        // Load recent data
        await _getRecentCustomers();
        await _getRecentTeamMembers();

        setState(() {
          _stats = {'work': workStats, 'customer': customerStats};
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

  Future<void> _getRecentCustomers() async {
    try {
      // For now, initialize with empty list - will be populated when CustomerService has getCustomers method
      setState(() {
        _recentCustomers = [];
      });
    } catch (e) {
      print('Error loading recent customers: $e');
    }
  }

  Future<void> _getRecentTeamMembers() async {
    try {
      final users = await _userService.getUsersByOffice(
        _currentUser!.officeId!,
      );
      setState(() {
        _recentTeamMembers = users
            .where(
              (user) => user.id != _currentUser!.id && user.role != 'director',
            )
            .take(5)
            .toList();
      });
    } catch (e) {
      print('Error loading recent team members: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.business_center, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Manager Dashboard',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications feature coming soon'),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile feature coming soon'),
                    ),
                  );
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings feature coming soon'),
                    ),
                  );
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person, size: 20),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings, size: 20),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, size: 20, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PullToRefreshWrapper(
        onRefresh: _loadDashboard,
        child: _isLoading
            ? const LoadingWidget(message: 'Loading dashboard...')
            : _buildDashboard(),
      ),
      drawer: ManagerSidebar(
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
              colors: [Colors.indigo.shade50, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(isMobile),
                const SizedBox(height: 24),

                // Metrics Section
                _buildMetricsSection(isMobile, isTablet),
                const SizedBox(height: 24),

                // Analytics Section (Desktop and Tablet)
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
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade200,
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
                  Icons.business_center,
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
                      _currentUser?.fullName ?? 'Manager',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Manager • ${_currentUser?.roleDisplayName ?? 'Manager'}',
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
    final workStats = _stats?['work'] ?? {};
    final customerStats = _stats?['customer'] ?? {};

    final metrics = [
      {
        'title': 'Pending Work',
        'value': '${workStats['pending'] ?? 0}',
        'subtitle': 'Awaiting Assignment',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
        'trend': '+3.2%',
      },
      {
        'title': 'In Progress',
        'value': '${workStats['in_progress'] ?? 0}',
        'subtitle': 'Active Tasks',
        'icon': Icons.work_outline,
        'color': Colors.blue,
        'trend': '+7.1%',
      },
      {
        'title': 'Completed',
        'value': '${workStats['completed'] ?? 0}',
        'subtitle': 'This Month',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
        'trend': '+15.3%',
      },
      {
        'title': 'Total Customers',
        'value': '${customerStats['total_customers'] ?? 0}',
        'subtitle': 'Under Management',
        'icon': Icons.groups_outlined,
        'color': Colors.purple,
        'trend': '+6.8%',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Office Performance Metrics',
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
          'Team Performance Analytics',
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
                'Work Distribution & Progress',
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
                        Icons.bar_chart,
                        size: isMobile ? 40 : 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Analytics Dashboard Coming Soon',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Team performance metrics will be displayed here',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade400,
                        ),
                        textAlign: TextAlign.center,
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
          'Recent Team Activity',
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
                Icons.person_add_outlined,
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
              if (_recentCustomers.isNotEmpty && _recentTeamMembers.isNotEmpty)
                Divider(color: Colors.grey.shade200, height: 24),
              // Recent Team Members
              _buildActivitySection(
                'Team Members',
                Icons.group_add_outlined,
                Colors.green,
                _recentTeamMembers
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
        'title': 'Assign Work',
        'icon': Icons.assignment_outlined,
        'color': Colors.blue,
        'action': () => Navigator.pushNamed(context, '/assign-work'),
      },
      {
        'title': 'My Team',
        'icon': Icons.group_outlined,
        'color': Colors.green,
        'action': () => Navigator.pushNamed(context, '/my-team'),
      },
      {
        'title': 'Verify Work',
        'icon': Icons.verified_outlined,
        'color': Colors.orange,
        'action': () => Navigator.pushNamed(context, '/verify-work'),
      },
      {
        'title': 'Reports',
        'icon': Icons.analytics_outlined,
        'color': Colors.purple,
        'action': () => Navigator.pushNamed(context, '/reports'),
      },
      {
        'title': 'Team Performance',
        'icon': Icons.trending_up_outlined,
        'color': Colors.indigo,
        'action': () => _showTeamPerformance(),
      },
      {
        'title': 'Settings',
        'icon': Icons.settings_outlined,
        'color': Colors.grey,
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

  void _showTeamPerformance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Team Performance feature coming soon')),
    );
  }

  void _navigateToSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings feature coming soon')),
    );
  }
}
