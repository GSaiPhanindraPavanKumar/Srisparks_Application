import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/work_model.dart';
import '../../models/customer_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_service.dart';
import '../../services/customer_service.dart';
import '../../widgets/loading_widget.dart';
import 'employee_sidebar.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final AuthService _authService = AuthService();
  final WorkService _workService = WorkService();
  final CustomerService _customerService = CustomerService();

  UserModel? _currentUser;
  List<WorkModel>? _myWork;
  Map<String, dynamic>? _stats;
  List<CustomerModel> _recentCustomers = [];
  List<Map<String, dynamic>> _completedWork = [];
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
        // Load my work and performance metrics
        final myWork = await _workService.getMyWork();
        final workStats = await _workService.getWorkPerformanceMetrics(
          _currentUser!.id,
        );

        // Load additional data for enhanced dashboard
        await _getRecentCustomers();
        await _getCompletedWork();

        setState(() {
          _myWork = myWork;
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

  Future<void> _getCompletedWork() async {
    try {
      // For now, initialize with empty list - will be populated with actual completed work data
      setState(() {
        _completedWork = [];
      });
    } catch (e) {
      print('Error loading completed work: $e');
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
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.person_outline, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Employee Dashboard',
                style: TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
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
                  Navigator.pushNamed(context, '/profile');
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
      drawer: EmployeeSidebar(
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
              colors: [Colors.green.shade50, Colors.white],
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

                // Recent Work Section
                _buildRecentWorkSection(isMobile),
                const SizedBox(height: 24),

                // Quick Actions & Additional Info
                if (isMobile)
                  Column(
                    children: [
                      _buildQuickActionsSection(isMobile),
                      const SizedBox(height: 20),
                      _buildAdditionalInfoSection(isMobile),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildQuickActionsSection(isMobile),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildAdditionalInfoSection(isMobile),
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

  Widget _buildPerformanceGrid(bool isMobile) {
    final stats = _stats ?? {};

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 8 : 12,
      mainAxisSpacing: isMobile ? 8 : 12,
      childAspectRatio: isMobile ? 1.3 : 1.5,
      children: [
        _buildMetricCard(
          'Total Work',
          '${stats['total_work'] ?? 0}',
          Icons.work,
          Colors.blue,
          isMobile,
        ),
        _buildMetricCard(
          'Completed',
          '${stats['completed_work'] ?? 0}',
          Icons.check_circle,
          Colors.green,
          isMobile,
        ),
        _buildMetricCard(
          'Completion Rate',
          '${stats['completion_rate'] ?? 0}%',
          Icons.trending_up,
          Colors.orange,
          isMobile,
        ),
        _buildMetricCard(
          'Overdue',
          '${stats['overdue_work'] ?? 0}',
          Icons.warning,
          Colors.red,
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
        padding: EdgeInsets.all(isMobile ? 6.0 : 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Icon(icon, size: isMobile ? 20 : 28, color: color),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: isMobile ? 1 : 2),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 9 : 11,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentWork(bool isMobile) {
    if (_myWork == null || _myWork!.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Text(
            'No work assigned yet.',
            style: TextStyle(color: Colors.grey, fontSize: isMobile ? 12 : 14),
          ),
        ),
      );
    }

    final recentWork = _myWork!.take(3).toList();

    return Column(
      children: recentWork
          .map((work) => _buildWorkCard(work, isMobile))
          .toList(),
    );
  }

  Widget _buildWorkCard(WorkModel work, bool isMobile) {
    Color statusColor;
    switch (work.status) {
      case WorkStatus.pending:
        statusColor = Colors.orange;
        break;
      case WorkStatus.in_progress:
        statusColor = Colors.blue;
        break;
      case WorkStatus.completed:
        statusColor = Colors.green;
        break;
      case WorkStatus.verified:
        statusColor = Colors.purple;
        break;
      case WorkStatus.rejected:
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(isMobile ? 8 : 16),
        leading: Icon(Icons.work, color: statusColor, size: isMobile ? 20 : 24),
        title: Text(
          work.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
          maxLines: isMobile ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (work.description != null && work.description!.isNotEmpty)
              Text(
                work.description!,
                style: TextStyle(fontSize: isMobile ? 12 : 14),
                maxLines: isMobile ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: isMobile ? 2 : 4),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      work.statusDisplayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 4 : 8),
                if (work.isOverdue)
                  Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: isMobile ? 14 : 16,
                  ),
              ],
            ),
          ],
        ),
        trailing: work.canStart || work.canComplete
            ? IconButton(
                icon: Icon(
                  work.canStart ? Icons.play_arrow : Icons.check,
                  color: Colors.green,
                  size: isMobile ? 20 : 24,
                ),
                onPressed: () => Navigator.pushNamed(context, '/my-work'),
              )
            : null,
        onTap: () => Navigator.pushNamed(context, '/my-work'),
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
          'My Work',
          Icons.work_outline,
          Colors.blue,
          () => Navigator.pushNamed(context, '/my-work'),
          isMobile,
        ),
        _buildActionCard(
          'Profile',
          Icons.person,
          Colors.orange,
          () => Navigator.pushNamed(context, '/profile'),
          isMobile,
        ),
        _buildActionCard(
          'Help',
          Icons.help,
          Colors.purple,
          () => Navigator.pushNamed(context, '/help'),
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
          padding: EdgeInsets.all(isMobile ? 6.0 : 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Icon(icon, size: isMobile ? 20 : 28, color: color),
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
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
                  Icons.person_outline,
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
                      _currentUser?.fullName ?? 'Employee',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Employee • ${_currentUser?.roleDisplayName ?? 'Team Member'}',
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
                Flexible(
                  child: Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
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
        'trend': '+3.7%',
      },
      {
        'title': 'Completed',
        'value': '${stats['completed_work'] ?? 0}',
        'subtitle': 'This Month',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
        'trend': '+18.2%',
      },
      {
        'title': 'Completion Rate',
        'value': '${stats['completion_rate'] ?? 0}%',
        'subtitle': 'Performance',
        'icon': Icons.trending_up_outlined,
        'color': Colors.orange,
        'trend': '+5.1%',
      },
      {
        'title': 'Overdue',
        'value': '${stats['overdue_work'] ?? 0}',
        'subtitle': 'Needs Attention',
        'icon': Icons.warning_amber_outlined,
        'color': Colors.red,
        'trend': '-2.3%',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Performance Overview',
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

  Widget _buildRecentWorkSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Work Activity',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        _buildEnhancedRecentWork(isMobile),
      ],
    );
  }

  Widget _buildEnhancedRecentWork(bool isMobile) {
    if (_myWork == null || _myWork!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.work_off,
                size: isMobile ? 40 : 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No Work Assigned Yet',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'New work assignments will appear here',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final recentWork = _myWork!.take(3).toList();

    return Column(
      children: recentWork
          .map((work) => _buildEnhancedWorkCard(work, isMobile))
          .toList(),
    );
  }

  Widget _buildEnhancedWorkCard(WorkModel work, bool isMobile) {
    Color statusColor;
    IconData statusIcon;
    switch (work.status) {
      case WorkStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case WorkStatus.in_progress:
        statusColor = Colors.blue;
        statusIcon = Icons.work;
        break;
      case WorkStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case WorkStatus.verified:
        statusColor = Colors.purple;
        statusIcon = Icons.verified;
        break;
      case WorkStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: isMobile ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (work.description != null &&
                        work.description!.isNotEmpty)
                      Text(
                        work.description!,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: isMobile ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (work.canStart || work.canComplete)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    work.canStart ? Icons.play_arrow : Icons.check,
                    color: Colors.green,
                    size: isMobile ? 18 : 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  work.statusDisplayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (work.isOverdue)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: isMobile ? 12 : 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Overdue',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/my-work'),
                child: Text(
                  'View Details',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              ),
            ],
          ),
        ],
      ),
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
        'title': 'Profile',
        'icon': Icons.person_outline,
        'color': Colors.orange,
        'action': () => Navigator.pushNamed(context, '/profile'),
      },
      {
        'title': 'Help & Support',
        'icon': Icons.help_outline,
        'color': Colors.purple,
        'action': () => Navigator.pushNamed(context, '/help'),
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

  Widget _buildAdditionalInfoSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Tips & Updates',
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
              _buildInfoTile(
                'Work Efficiently',
                'Complete tasks on time to improve your performance rating',
                Icons.tips_and_updates,
                Colors.blue,
                isMobile,
              ),
              Divider(color: Colors.grey.shade200, height: 24),
              _buildInfoTile(
                'Stay Updated',
                'Check for new work assignments regularly',
                Icons.notifications_active,
                Colors.orange,
                isMobile,
              ),
              Divider(color: Colors.grey.shade200, height: 24),
              _buildInfoTile(
                'Need Help?',
                'Contact your supervisor if you need assistance',
                Icons.help_center,
                Colors.green,
                isMobile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isMobile ? 20 : 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings feature coming soon')),
    );
  }
}
