import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/customer_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_service.dart';
import '../../services/customer_service.dart';
import '../../services/user_service.dart';
import '../../widgets/loading_widget.dart';
import 'lead_sidebar.dart';

class LeadDashboard extends StatefulWidget {
  const LeadDashboard({super.key});

  @override
  State<LeadDashboard> createState() => _LeadDashboardState();
}

class _LeadDashboardState extends State<LeadDashboard> {
  final AuthService _authService = AuthService();
  final WorkService _workService = WorkService();
  final CustomerService _customerService = CustomerService();
  final UserService _userService = UserService();

  UserModel? _currentUser;
  Map<String, dynamic>? _stats;
  List<CustomerModel> _recentCustomers = [];
  List<UserModel> _teamMembers = [];
  List<Map<String, dynamic>> _recentWork = [];
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
        // Load work performance metrics
        final workStats = await _workService.getWorkPerformanceMetrics(
          _currentUser!.id,
        );

        // Load additional data for enhanced dashboard
        await _getRecentCustomers();
        await _getTeamMembers();
        await _getRecentWork();

        setState(() {
          _stats = workStats;
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
      // For now, initialize with empty list - will be populated when CustomerService has appropriate method
      setState(() {
        _recentCustomers = [];
      });
    } catch (e) {
      print('Error loading recent customers: $e');
    }
  }

  Future<void> _getTeamMembers() async {
    try {
      if (_currentUser?.officeId != null) {
        final users = await _userService.getUsersByOffice(
          _currentUser!.officeId!,
        );
        setState(() {
          _teamMembers = users
              .where(
                (user) =>
                    user.id != _currentUser!.id &&
                    (user.role == 'technician' ||
                        user.role == 'junior_technician'),
              )
              .take(5)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading team members: $e');
    }
  }

  Future<void> _getRecentWork() async {
    try {
      // For now, initialize with empty list - will be populated with actual work data
      setState(() {
        _recentWork = [];
      });
    } catch (e) {
      print('Error loading recent work: $e');
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
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.engineering, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Lead Dashboard',
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
      drawer: LeadSidebar(currentUser: _currentUser, onLogout: _handleLogout),
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
              colors: [Colors.teal.shade50, Colors.white],
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

                // Performance Metrics Section
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
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade200,
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
                  Icons.engineering,
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
                      _currentUser?.fullName ?? 'Lead',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Lead • ${_currentUser?.roleDisplayName ?? 'Team Lead'}',
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
    final stats = _stats ?? {};

    final metrics = [
      {
        'title': 'Total Work',
        'value': '${stats['total_work'] ?? 0}',
        'subtitle': 'All Assigned Tasks',
        'icon': Icons.work_outline,
        'color': Colors.blue,
        'trend': '+4.2%',
      },
      {
        'title': 'Completed',
        'value': '${stats['completed_work'] ?? 0}',
        'subtitle': 'This Month',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
        'trend': '+12.8%',
      },
      {
        'title': 'Completion Rate',
        'value': '${stats['completion_rate'] ?? 0}%',
        'subtitle': 'Performance',
        'icon': Icons.trending_up_outlined,
        'color': Colors.orange,
        'trend': '+2.3%',
      },
      {
        'title': 'Overdue',
        'value': '${stats['overdue_work'] ?? 0}',
        'subtitle': 'Needs Attention',
        'icon': Icons.warning_amber_outlined,
        'color': Colors.red,
        'trend': '-1.5%',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Performance Metrics',
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
    final isNegativeTrend = trend.startsWith('-');
    final trendColor = isNegativeTrend ? Colors.red : Colors.green;

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
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: trendColor,
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
          'Work Progress Analytics',
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
                'Task Distribution & Timeline',
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
                        Icons.timeline,
                        size: isMobile ? 40 : 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Work Analytics Coming Soon',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Task progress and timeline analysis will appear here',
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
          'Recent Activity & Team',
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
              // Recent Work
              _buildActivitySection(
                'Recent Work',
                Icons.work_outline,
                Colors.blue,
                _recentWork
                    .take(3)
                    .map(
                      (work) => {
                        'title': work['title'] ?? 'Work Item',
                        'subtitle': work['status'] ?? 'In Progress',
                        'icon': Icons.assignment,
                      },
                    )
                    .toList(),
                isMobile,
              ),
              if (_recentWork.isNotEmpty && _teamMembers.isNotEmpty)
                Divider(color: Colors.grey.shade200, height: 24),
              // Team Members
              _buildActivitySection(
                'My Team',
                Icons.group_outlined,
                Colors.green,
                _teamMembers
                    .take(3)
                    .map(
                      (member) => {
                        'title': member.fullName,
                        'subtitle': '${member.roleDisplayName} • Active',
                        'icon': Icons.person,
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
        'title': 'My Work',
        'icon': Icons.work_outline,
        'color': Colors.blue,
        'action': () => Navigator.pushNamed(context, '/my-work'),
      },
      {
        'title': 'Assign Work',
        'icon': Icons.assignment_outlined,
        'color': Colors.green,
        'action': () => Navigator.pushNamed(context, '/assign-work'),
      },
      {
        'title': 'My Team',
        'icon': Icons.group_outlined,
        'color': Colors.orange,
        'action': () => Navigator.pushNamed(context, '/my-team'),
      },
      {
        'title': 'Verify Work',
        'icon': Icons.verified_outlined,
        'color': Colors.purple,
        'action': () => Navigator.pushNamed(context, '/verify-work'),
      },
      {
        'title': 'Performance',
        'icon': Icons.analytics_outlined,
        'color': Colors.teal,
        'action': () => _showPerformanceDetails(),
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

  void _showPerformanceDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Performance details feature coming soon')),
    );
  }

  void _navigateToSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings feature coming soon')),
    );
  }
}
