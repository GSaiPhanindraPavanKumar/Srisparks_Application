import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_service.dart';
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
        // Load work performance metrics
        final workStats = await _workService.getWorkPerformanceMetrics(
          _currentUser!.id,
        );

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
        title: const Text('Lead Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
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
                      const Icon(Icons.person, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Welcome, ${_currentUser?.fullName ?? 'Lead'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Role: ${_currentUser?.roleDisplayName ?? 'Lead'}',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final crossAxisCount = isSmallScreen ? 2 : 4;
        final childAspectRatio = isSmallScreen ? 1.3 : 1.5;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildMetricCard(
              'Total Work',
              '${stats['total_work'] ?? 0}',
              Icons.work,
              Colors.blue,
              isSmallScreen,
            ),
            _buildMetricCard(
              'Completed',
              '${stats['completed_work'] ?? 0}',
              Icons.check_circle,
              Colors.green,
              isSmallScreen,
            ),
            _buildMetricCard(
              'Completion Rate',
              '${stats['completion_rate'] ?? 0}%',
              Icons.trending_up,
              Colors.orange,
              isSmallScreen,
            ),
            _buildMetricCard(
              'Overdue',
              '${stats['overdue_work'] ?? 0}',
              Icons.warning,
              Colors.red,
              isSmallScreen,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, [
    bool mobile = false,
  ]) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Icon(icon, size: mobile ? 28 : 32, color: color),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: mobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: mobile ? 11 : 12,
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

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final crossAxisCount = isSmallScreen ? 2 : 4;
        final childAspectRatio = isSmallScreen ? 1.1 : 1.2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildActionCard(
              'My Work',
              Icons.work_outline,
              Colors.blue,
              () => Navigator.pushNamed(context, '/my-work'),
              isSmallScreen,
            ),
            _buildActionCard(
              'Assign Work',
              Icons.assignment,
              Colors.green,
              () => Navigator.pushNamed(context, '/assign-work'),
              isSmallScreen,
            ),
            _buildActionCard(
              'My Team',
              Icons.group,
              Colors.orange,
              () => Navigator.pushNamed(context, '/my-team'),
              isSmallScreen,
            ),
            _buildActionCard(
              'Verify Work',
              Icons.verified,
              Colors.purple,
              () => Navigator.pushNamed(context, '/verify-work'),
              isSmallScreen,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, [
    bool mobile = false,
  ]) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Icon(icon, size: mobile ? 28 : 32, color: color),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: mobile ? 13 : 14,
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
