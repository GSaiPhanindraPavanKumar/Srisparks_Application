import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/installation_work_model.dart';
import '../../models/user_model.dart';
import '../../services/installation_service.dart';
import '../../services/auth_service.dart';
import 'employee_work_detail_screen.dart';

class EmployeeInstallationScreen extends StatefulWidget {
  const EmployeeInstallationScreen({super.key});

  @override
  State<EmployeeInstallationScreen> createState() =>
      _EmployeeInstallationScreenState();
}

class _EmployeeInstallationScreenState
    extends State<EmployeeInstallationScreen> {
  final InstallationService _installationService = InstallationService();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  List<InstallationProject> _assignments = [];
  List<InstallationWorkItem> _workItems = [];
  Map<String, dynamic>? _workStats;
  Map<String, dynamic>? _activeSession;

  bool _isLoading = true;
  String? _error;
  String _selectedView = 'projects'; // 'projects' or 'workItems'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser == null) {
        throw Exception('User not found');
      }

      final futures = await Future.wait([
        _installationService.getEmployeeInstallationAssignments(
          _currentUser!.id,
        ),
        _installationService.getEmployeeWorkItems(_currentUser!.id),
        _installationService.getEmployeeWorkStats(_currentUser!.id),
        _installationService.getActiveWorkSession(_currentUser!.id),
      ]);

      setState(() {
        _assignments = futures[0] as List<InstallationProject>;
        _workItems = futures[1] as List<InstallationWorkItem>;
        _workStats = futures[2] as Map<String, dynamic>;
        _activeSession = futures[3] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Installations'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : Column(
              children: [
                _buildStatsHeader(),
                _buildActiveSessionCard(),
                _buildViewSelector(),
                Expanded(
                  child: _selectedView == 'projects'
                      ? _buildProjectsList()
                      : _buildWorkItemsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading installations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_workStats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[400]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Projects',
              _workStats!['total_projects'].toString(),
              Icons.work_outline,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Work Items',
              '${_workStats!['completed_work_items']}/${_workStats!['total_work_items']}',
              Icons.check_circle_outline,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Hours',
              _workStats!['total_hours'].toString(),
              Icons.access_time,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Complete',
              '${_workStats!['completion_rate']}%',
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActiveSessionCard() {
    if (_activeSession == null) return const SizedBox.shrink();

    final workItem = _activeSession!['installation_work_items'];
    final project = workItem['installation_projects'];
    final customer = project['customers'];
    final startTime = DateTime.parse(_activeSession!['start_time']);
    final duration = DateTime.now().difference(startTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.play_circle_filled, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Active Work Session',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Customer: ${customer['name']}'),
              Text('Work Type: ${workItem['work_type']}'),
              Text('Location: ${customer['address']}'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _navigateToWorkDetail(workItem['id']),
                icon: const Icon(Icons.visibility),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _selectedView = 'projects'),
              icon: const Icon(Icons.business),
              label: const Text('Projects'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedView == 'projects'
                    ? Colors.green
                    : Colors.grey[300],
                foregroundColor: _selectedView == 'projects'
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _selectedView = 'workItems'),
              icon: const Icon(Icons.work),
              label: const Text('Work Items'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedView == 'workItems'
                    ? Colors.green
                    : Colors.grey[300],
                foregroundColor: _selectedView == 'workItems'
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    if (_assignments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Installation Projects Assigned',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'You will see your assigned installation projects here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final project = _assignments[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(InstallationProject project) {
    final workItems = project.workItems;
    final completedItems = workItems
        .where((item) => item.status == 'completed')
        .length;
    final totalItems = workItems.length;
    final progress = totalItems > 0 ? (completedItems / totalItems) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getProjectStatusColor(progress),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    project.customerAddress,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            if (project.scheduledStartDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${DateFormat('MMM dd, yyyy').format(project.scheduledStartDate!)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Work Items: $completedItems/$totalItems completed',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProjectStatusColor(progress),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewProjectWorkItems(project),
                    icon: const Icon(Icons.list),
                    label: const Text('View Work Items'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _navigateToProject(project),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Work'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkItemsList() {
    if (_workItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Work Items Assigned',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Individual work items will appear here when assigned',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workItems.length,
      itemBuilder: (context, index) {
        final workItem = _workItems[index];
        return _buildWorkItemCard(workItem);
      },
    );
  }

  Widget _buildWorkItemCard(InstallationWorkItem workItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getWorkItemStatusColor(workItem.status),
          child: Icon(
            _getWorkItemStatusIcon(workItem.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          workItem.workType.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress: ${workItem.progressPercentage}%'),
            Text('Status: ${workItem.status.displayName}'),
            if (workItem.estimatedHours != null)
              Text('Est. Hours: ${workItem.estimatedHours}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (workItem.progressPercentage < 100)
              Icon(Icons.play_arrow, color: Colors.green[600]),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _navigateToWorkDetail(workItem.id),
      ),
    );
  }

  Color _getProjectStatusColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getWorkItemStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.completed:
      case WorkStatus.verified:
      case WorkStatus.acknowledged:
      case WorkStatus.approved:
        return Colors.green;
      case WorkStatus.inProgress:
        return Colors.orange;
      case WorkStatus.awaitingCompletion:
        return Colors.blue;
      case WorkStatus.notStarted:
      default:
        return Colors.grey;
    }
  }

  IconData _getWorkItemStatusIcon(WorkStatus status) {
    switch (status) {
      case WorkStatus.completed:
      case WorkStatus.verified:
      case WorkStatus.acknowledged:
      case WorkStatus.approved:
        return Icons.check;
      case WorkStatus.inProgress:
        return Icons.play_arrow;
      case WorkStatus.awaitingCompletion:
        return Icons.pause;
      case WorkStatus.notStarted:
      default:
        return Icons.pending;
    }
  }

  void _navigateToProject(InstallationProject project) {
    // Navigate to project overview with all work items
    Navigator.pushNamed(
      context,
      '/employee/project-detail',
      arguments: project,
    );
  }

  void _navigateToWorkDetail(String workItemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeWorkDetailScreen(workItemId: workItemId),
      ),
    );
  }

  void _viewProjectWorkItems(InstallationProject project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${project.customerName} - Work Items',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: project.workItems.length,
                    itemBuilder: (context, index) {
                      final workItem = project.workItems[index];
                      return _buildWorkItemCard(workItem);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
