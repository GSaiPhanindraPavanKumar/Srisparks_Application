import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/work_service.dart';
import '../../services/customer_service.dart';
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
        // Load work statistics for the office
        final workStats = await _workService.getWorkStatistics(
          _currentUser!.officeId!,
        );
        final customerStats = await _customerService.getCustomerStatistics(
          _currentUser!.officeId!,
        );

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
        title: const Text('Manager Dashboard'),
        backgroundColor: Colors.indigo,
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
      drawer: ManagerSidebar(
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
                          const Icon(Icons.person, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Welcome, ${_currentUser?.fullName ?? 'Manager'}',
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
                        'Role: ${_currentUser?.roleDisplayName ?? 'Manager'}',
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
                'Office Performance',
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
          'Pending Work',
          '${workStats['pending'] ?? 0}',
          Icons.pending,
          Colors.orange,
          isMobile,
        ),
        _buildMetricCard(
          'In Progress',
          '${workStats['in_progress'] ?? 0}',
          Icons.work,
          Colors.blue,
          isMobile,
        ),
        _buildMetricCard(
          'Completed',
          '${workStats['completed'] ?? 0}',
          Icons.check_circle,
          Colors.green,
          isMobile,
        ),
        _buildMetricCard(
          'Total Customers',
          '${customerStats['total_customers'] ?? 0}',
          Icons.business,
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

  Widget _buildQuickActions(bool isMobile) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 8 : 12,
      mainAxisSpacing: isMobile ? 8 : 12,
      childAspectRatio: isMobile ? 1.1 : 1.2,
      children: [
        _buildActionCard(
          'Assign Work',
          Icons.assignment,
          Colors.blue,
          () => Navigator.pushNamed(context, '/assign-work'),
          isMobile,
        ),
        _buildActionCard(
          'My Team',
          Icons.group,
          Colors.green,
          () => Navigator.pushNamed(context, '/my-team'),
          isMobile,
        ),
        _buildActionCard(
          'Verify Work',
          Icons.verified,
          Colors.orange,
          () => Navigator.pushNamed(context, '/verify-work'),
          isMobile,
        ),
        _buildActionCard(
          'Reports',
          Icons.analytics,
          Colors.purple,
          () => Navigator.pushNamed(context, '/reports'),
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
