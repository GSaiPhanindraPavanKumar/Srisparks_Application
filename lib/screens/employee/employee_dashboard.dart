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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Welcome, ${_currentUser?.fullName ?? 'Employee'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Role: ${_currentUser?.roleDisplayName ?? 'Employee'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Performance metrics
          const Text(
            'Your Performance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPerformanceGrid(),
          const SizedBox(height: 24),

          // Recent work
          const Text(
            'Recent Work',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRecentWork(),
          const SizedBox(height: 24),

          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    final stats = _stats ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Work',
          '${stats['total_work'] ?? 0}',
          Icons.work,
          Colors.blue,
        ),
        _buildMetricCard(
          'Completed',
          '${stats['completed_work'] ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildMetricCard(
          'Completion Rate',
          '${stats['completion_rate'] ?? 0}%',
          Icons.trending_up,
          Colors.orange,
        ),
        _buildMetricCard(
          'Overdue',
          '${stats['overdue_work'] ?? 0}',
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentWork() {
    if (_myWork == null || _myWork!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No work assigned yet.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final recentWork = _myWork!.take(3).toList();

    return Column(
      children: recentWork.map((work) => _buildWorkCard(work)).toList(),
    );
  }

  Widget _buildWorkCard(WorkModel work) {
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.work, color: statusColor),
        title: Text(
          work.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(work.description ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (work.isOverdue)
                  const Icon(Icons.warning, color: Colors.red, size: 16),
              ],
            ),
          ],
        ),
        trailing: work.canStart || work.canComplete
            ? IconButton(
                icon: Icon(
                  work.canStart ? Icons.play_arrow : Icons.check,
                  color: Colors.green,
                ),
                onPressed: () => _handleWorkAction(work),
              )
            : null,
        onTap: () => _showWorkDetails(work),
      ),
    );
  }

  void _handleWorkAction(WorkModel work) async {
    try {
      if (work.canStart) {
        await _workService.startWork(work.id);
        _showMessage('Work started successfully');
      } else if (work.canComplete) {
        await _workService.completeWork(work.id, null);
        _showMessage('Work completed successfully');
      }
      _loadDashboard();
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  void _showWorkDetails(WorkModel work) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(work.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${work.description ?? 'No description'}'),
            const SizedBox(height: 8),
            Text('Status: ${work.statusDisplayName}'),
            Text('Priority: ${work.priorityDisplayName}'),
            if (work.dueDate != null)
              Text('Due: ${work.dueDate!.toLocal().toString().split(' ')[0]}'),
            if (work.estimatedHours != null)
              Text('Estimated Hours: ${work.estimatedHours}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildActionCard(
          'My Work',
          Icons.work_outline,
          Colors.blue,
          () => Navigator.pushNamed(context, '/my-work'),
        ),
        _buildActionCard(
          'Time Tracking',
          Icons.timer,
          Colors.green,
          () => Navigator.pushNamed(context, '/time-tracking'),
        ),
        _buildActionCard(
          'Profile',
          Icons.person,
          Colors.orange,
          () => Navigator.pushNamed(context, '/profile'),
        ),
        _buildActionCard(
          'Help',
          Icons.help,
          Colors.purple,
          () => Navigator.pushNamed(context, '/help'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
