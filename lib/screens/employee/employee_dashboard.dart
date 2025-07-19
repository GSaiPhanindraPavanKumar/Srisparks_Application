import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/work_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_service.dart';
import 'employee_sidebar.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final AuthService _authService = AuthService();
  final WorkService _workService = WorkService();

  UserModel? _currentUser;
  List<WorkModel>? _myWork;
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
        // Load my work and performance metrics
        final myWork = await _workService.getMyWork();
        final workStats = await _workService.getWorkPerformanceMetrics(
          _currentUser!.id,
        );

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
        title: const Text('Employee Dashboard'),
        backgroundColor: Colors.green,
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
      drawer: EmployeeSidebar(
        currentUser: _currentUser,
        onLogout: _handleLogout,
      ),
    );
  }

  Widget _buildDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
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
                          const Icon(Icons.person, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Welcome, ${_currentUser?.fullName ?? 'Employee'}',
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
                        'Role: ${_currentUser?.roleDisplayName ?? 'Employee'}',
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

              // Performance metrics
              Text(
                'Your Performance',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildPerformanceGrid(isMobile),
              const SizedBox(height: 24),

              // Recent work
              Text(
                'Recent Work',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentWork(isMobile),
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
}
