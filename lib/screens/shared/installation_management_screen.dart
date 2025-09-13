import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/installation_work_model.dart';
import '../../models/user_model.dart';
import '../../models/customer_model.dart';
import '../../services/installation_service.dart';
import '../../services/auth_service.dart';
import '../../services/customer_service.dart';
import 'assign_installation_work_screen.dart';
import 'work_item_details_dashboard.dart';

class InstallationManagementScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final UserRole userRole;

  const InstallationManagementScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.userRole,
  });

  @override
  State<InstallationManagementScreen> createState() =>
      _InstallationManagementScreenState();
}

class _InstallationManagementScreenState
    extends State<InstallationManagementScreen>
    with SingleTickerProviderStateMixin {
  final InstallationService _installationService = InstallationService();
  final AuthService _authService = AuthService();
  final CustomerService _customerService = CustomerService();

  late TabController _tabController;
  UserModel? _currentUser;
  InstallationProject? _project;
  CustomerModel? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await _authService.getCurrentUser();

      // Load customer data
      _customer = await _customerService.getCustomerById(widget.customerId);

      // Try to load existing installation project
      try {
        _project = await _installationService.getInstallationProject(
          widget.customerId,
        );
      } catch (e) {
        // Project doesn't exist yet, this is OK
        _project = null;
      }
    } catch (e) {
      _showMessage('Error loading installation data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Installation - ${widget.customerName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Work Items', icon: Icon(Icons.work)),
            Tab(text: 'Team Status', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _project == null
          ? _buildCreateProjectView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildWorkItemsTab(),
                _buildTeamStatusTab(),
              ],
            ),
      floatingActionButton: _project != null && _canManageWork()
          ? FloatingActionButton.extended(
              onPressed: _showAssignWorkDialog,
              icon: const Icon(Icons.assignment_ind),
              label: const Text('Assign Work'),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildCreateProjectView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Installation Project Found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an installation project to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (_canManageWork())
            ElevatedButton.icon(
              onPressed: _createInstallationProject,
              icon: const Icon(Icons.add),
              label: const Text('Create Installation Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_project == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Project Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Customer', _project!.customerName),
                  _buildSummaryRow('Address', _project!.customerAddress),
                  _buildSummaryRow(
                    'Total Work Items',
                    '${_project!.totalWorkItems}',
                  ),
                  _buildSummaryRow(
                    'Completed Items',
                    '${_project!.completedWorkItems}',
                  ),
                  _buildSummaryRow(
                    'Progress',
                    '${_project!.progressPercentage.toStringAsFixed(1)}%',
                  ),
                  _buildSummaryRow(
                    'Status',
                    _project!.overallStatus.displayName,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Progress Indicator
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Progress',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _project!.progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_project!.completedWorkItems} of ${_project!.totalWorkItems} work items completed',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Work Types Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Types Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._project!.workItems.map(
                    (item) => _buildWorkTypeStatusTile(item),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkItemsTab() {
    if (_project == null || _project!.workItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Work Items',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Work items will appear here once created',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _project!.workItems.length,
      itemBuilder: (context, index) {
        final workItem = _project!.workItems[index];
        return _buildWorkItemCard(workItem);
      },
    );
  }

  Widget _buildTeamStatusTab() {
    if (_project == null || _project!.workItems.isEmpty) {
      return Center(
        child: Text(
          'No team assigned yet',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    // Collect all unique employees from all work items
    Map<String, EmployeeStatus> employeeStatus = {};

    for (var workItem in _project!.workItems) {
      for (var log in workItem.employeeLogs.values) {
        employeeStatus[log.employeeId] = EmployeeStatus(
          employeeId: log.employeeId,
          employeeName: log.employeeName,
          isCurrentlyWorking: log.isCurrentlyWorking,
          isAtSite: log.isCurrentlyAtSite,
          totalHours: log.totalHours,
          assignedWorkTypes: [workItem.workType],
        );
      }
    }

    if (employeeStatus.isEmpty) {
      return Center(
        child: Text(
          'No employees assigned yet',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: employeeStatus.length,
      itemBuilder: (context, index) {
        final employee = employeeStatus.values.elementAt(index);
        return _buildEmployeeStatusCard(employee);
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkTypeStatusTile(InstallationWorkItem item) {
    Color statusColor;
    IconData statusIcon;

    switch (item.status) {
      case WorkStatus.notStarted:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
        break;
      case WorkStatus.inProgress:
        statusColor = Colors.orange;
        statusIcon = Icons.play_arrow;
        break;
      case WorkStatus.completed:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case WorkStatus.verified:
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        break;
      case WorkStatus.acknowledged:
        statusColor = Colors.teal;
        statusIcon = Icons.thumb_up;
        break;
      case WorkStatus.approved:
        statusColor = Colors.purple;
        statusIcon = Icons.approval;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(statusIcon, color: statusColor),
      ),
      title: Text(item.workType.displayName),
      subtitle: Text(item.status.displayName),
      trailing: item.status == WorkStatus.inProgress
          ? Text(
              '${item.employeesWorking}/${item.totalAssignedEmployees} working',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      onTap: () => _showWorkItemDetails(item),
    );
  }

  Widget _buildWorkItemCard(InstallationWorkItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.workType.displayName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(item.status),
              ],
            ),

            const SizedBox(height: 12),

            // Assignment info
            if (item.leadEmployeeName.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('Lead: ${item.leadEmployeeName}'),
                ],
              ),
              if (item.teamMemberNames.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.group, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Team: ${item.teamMemberNames.join(', ')}'),
                    ),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 12),

            // Progress info
            if (item.status != WorkStatus.notStarted) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time,
                      'Total Hours: ${item.totalWorkHours.toStringAsFixed(1)}',
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.people,
                      '${item.employeesAtSite}/${item.totalAssignedEmployees} at site',
                      item.employeesAtSite == item.totalAssignedEmployees
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                if (_canManageWork() && item.status == WorkStatus.notStarted)
                  ElevatedButton.icon(
                    onPressed: () => _assignEmployees(item),
                    icon: Icon(Icons.assignment_ind, size: 16),
                    label: Text('Assign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),

                const SizedBox(width: 8),

                TextButton.icon(
                  onPressed: () {
                    print(
                      'View Details clicked for: ${item.workType.displayName}',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'View Details clicked for ${item.workType.displayName}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    _showWorkItemDetails(item);
                  },
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View Details'),
                ),

                const Spacer(),

                if (_canVerifyWork() &&
                    item.isReadyForVerification &&
                    !item.isVerified)
                  ElevatedButton.icon(
                    onPressed: () => _verifyWork(item),
                    icon: Icon(Icons.verified, size: 16),
                    label: Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),

                if (_canAcknowledgeWork() &&
                    item.isVerified &&
                    !item.isAcknowledged)
                  ElevatedButton.icon(
                    onPressed: () => _acknowledgeWork(item),
                    icon: Icon(Icons.thumb_up, size: 16),
                    label: Text('Acknowledge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),

                if (_canApproveWork() &&
                    item.isAcknowledged &&
                    !item.isApproved)
                  ElevatedButton.icon(
                    onPressed: () => _approveWork(item),
                    icon: Icon(Icons.approval, size: 16),
                    label: Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
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

  Widget _buildEmployeeStatusCard(EmployeeStatus employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: employee.isCurrentlyWorking
              ? Colors.green
              : employee.isAtSite
              ? Colors.orange
              : Colors.grey,
          child: Icon(
            employee.isCurrentlyWorking
                ? Icons.work
                : employee.isAtSite
                ? Icons.location_on
                : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(employee.employeeName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employee.isCurrentlyWorking
                  ? 'Currently Working'
                  : employee.isAtSite
                  ? 'At Site'
                  : 'Not at Site',
            ),
            Text('Total Hours: ${employee.totalHours.toStringAsFixed(1)}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.location_on),
          onPressed: () => _showEmployeeLocationHistory(employee),
        ),
      ),
    );
  }

  Widget _buildStatusChip(WorkStatus status) {
    Color color;
    switch (status) {
      case WorkStatus.notStarted:
        color = Colors.grey;
        break;
      case WorkStatus.inProgress:
        color = Colors.orange;
        break;
      case WorkStatus.completed:
        color = Colors.blue;
        break;
      case WorkStatus.verified:
        color = Colors.green;
        break;
      case WorkStatus.acknowledged:
        color = Colors.teal;
        break;
      case WorkStatus.approved:
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Action methods
  Future<void> _createInstallationProject() async {
    if (_customer == null) {
      _showMessage('Customer data not loaded. Please try again.');
      return;
    }

    try {
      await _installationService.createInstallationProject(
        customerId: widget.customerId,
        customerName: _customer!.name,
        customerAddress: _customer!.address ?? 'Address not provided',
        siteLatitude:
            _customer!.latitude ?? 17.3850, // Default to Hyderabad if not set
        siteLongitude:
            _customer!.longitude ?? 78.4867, // Default to Hyderabad if not set
        workTypes: InstallationWorkType.values,
      );

      _showMessage('Installation project created successfully');
      _loadData();
    } catch (e) {
      _showMessage('Error creating installation project: $e');
    }
  }

  void _showAssignWorkDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignInstallationWorkScreen(
          project: _project!,
          currentUser: _currentUser!,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _assignEmployees(InstallationWorkItem item) {
    // TODO: Implement employee assignment dialog
    _showMessage('Employee assignment feature coming soon');
  }

  void _showWorkItemDetails(InstallationWorkItem item) {
    print(
      'Navigating to work item details dashboard for: ${item.workType.displayName}',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkItemDetailsDashboard(
          workItem: item,
          customerName: widget.customerName,
        ),
      ),
    );
  }

  void _showEmployeeLocationHistory(EmployeeStatus employee) {
    // TODO: Show employee location history
    _showMessage('Location history for ${employee.employeeName}');
  }

  Future<void> _verifyWork(InstallationWorkItem item) async {
    // TODO: Implement work verification
    try {
      await _installationService.verifyWork(
        workItemId: item.id,
        verifiedBy: _currentUser!.id,
        notes: 'Work verified by ${widget.userRole.name}',
      );
      _showMessage('Work verified successfully');
      _loadData();
    } catch (e) {
      _showMessage('Error verifying work: $e');
    }
  }

  Future<void> _acknowledgeWork(InstallationWorkItem item) async {
    try {
      await _installationService.acknowledgeWork(
        workItemId: item.id,
        acknowledgedBy: _currentUser!.id,
        notes: 'Work acknowledged by manager',
      );
      _showMessage('Work acknowledged successfully');
      _loadData();
    } catch (e) {
      _showMessage('Error acknowledging work: $e');
    }
  }

  Future<void> _approveWork(InstallationWorkItem item) async {
    try {
      await _installationService.approveWork(
        workItemId: item.id,
        approvedBy: _currentUser!.id,
        notes: 'Work approved by director',
      );
      _showMessage('Work approved successfully');
      _loadData();
    } catch (e) {
      _showMessage('Error approving work: $e');
    }
  }

  // Permission check methods
  bool _canManageWork() =>
      widget.userRole == UserRole.director ||
      widget.userRole == UserRole.manager ||
      widget.userRole == UserRole.lead;

  bool _canVerifyWork() => widget.userRole == UserRole.lead;

  bool _canAcknowledgeWork() => widget.userRole == UserRole.manager;

  bool _canApproveWork() => widget.userRole == UserRole.director;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// Helper class for employee status
class EmployeeStatus {
  final String employeeId;
  final String employeeName;
  final bool isCurrentlyWorking;
  final bool isAtSite;
  final double totalHours;
  final List<InstallationWorkType> assignedWorkTypes;

  EmployeeStatus({
    required this.employeeId,
    required this.employeeName,
    required this.isCurrentlyWorking,
    required this.isAtSite,
    required this.totalHours,
    required this.assignedWorkTypes,
  });
}

// Work Item Details Dialog
class WorkItemDetailsDialog extends StatefulWidget {
  final InstallationWorkItem workItem;
  final InstallationService installationService;

  const WorkItemDetailsDialog({
    super.key,
    required this.workItem,
    required this.installationService,
  });

  @override
  State<WorkItemDetailsDialog> createState() => _WorkItemDetailsDialogState();
}

class _WorkItemDetailsDialogState extends State<WorkItemDetailsDialog> {
  Map<String, List<Map<String, dynamic>>>? _employeeSessions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    try {
      print(
        'WorkItemDetailsDialog initialized for work item: ${widget.workItem.id}',
      );
      _loadSessionDetails();
    } catch (e) {
      print('Error in WorkItemDetailsDialog initState: $e');
    }
  }

  Future<void> _loadSessionDetails() async {
    try {
      print('Loading session details for work item: ${widget.workItem.id}');
      final sessions = await widget.installationService
          .getWorkItemSessionDetails(widget.workItem.id);
      print('Loaded ${sessions.keys.length} employee sessions');
      if (mounted) {
        setState(() {
          _employeeSessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading session details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load session details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.work, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_getWorkTypeDisplayName(widget.workItem.workType.name)} - Work Sessions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildSessionsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsContent() {
    if (_employeeSessions == null || _employeeSessions!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No work sessions found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Work sessions will appear here when employees start working',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _employeeSessions!.length,
      itemBuilder: (context, index) {
        final employeeName = _employeeSessions!.keys.elementAt(index);
        final sessions = _employeeSessions![employeeName]!;
        return _buildEmployeeSessionCard(employeeName, sessions);
      },
    );
  }

  Widget _buildEmployeeSessionCard(
    String employeeName,
    List<Map<String, dynamic>> sessions,
  ) {
    // Calculate total time worked by this employee
    Duration totalWorkTime = Duration.zero;
    for (final session in sessions) {
      if (session['end_time'] != null) {
        final startTime = DateTime.parse(session['start_time']);
        final endTime = DateTime.parse(session['end_time']);
        totalWorkTime += endTime.difference(startTime);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Text(
            employeeName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Sessions: ${sessions.length}'),
            Text('Total Time: ${_formatDuration(totalWorkTime)}'),
          ],
        ),
        children: sessions
            .map((session) => _buildSessionTile(session))
            .toList(),
      ),
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final startTime = DateTime.parse(session['start_time']);
    final endTime = session['end_time'] != null
        ? DateTime.parse(session['end_time'])
        : null;
    final duration = endTime != null ? endTime.difference(startTime) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                endTime != null ? Icons.check_circle : Icons.schedule,
                color: endTime != null ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                endTime != null ? 'Completed Session' : 'Active Session',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: endTime != null ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Start Time
          Row(
            children: [
              const Icon(Icons.play_arrow, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              const Text(
                'Started: ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(startTime)),
            ],
          ),

          // End Time
          if (endTime != null)
            Row(
              children: [
                const Icon(Icons.stop, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Ended: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(endTime)),
              ],
            )
          else
            const Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'In Progress...',
                  style: TextStyle(
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

          // Duration
          if (duration != null)
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Duration: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(_formatDuration(duration)),
              ],
            ),

          // Notes
          if (session['session_notes'] != null &&
              session['session_notes'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text(
                    'Notes: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Expanded(child: Text(session['session_notes'].toString())),
                ],
              ),
            ),

          const Divider(height: 16),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getWorkTypeDisplayName(String workType) {
    switch (workType.toLowerCase()) {
      case 'structurework':
        return 'Structure Work';
      case 'panels':
        return 'Panel Installation';
      case 'inverterwiring':
        return 'Inverter Wiring';
      case 'earthing':
        return 'Earthing System';
      case 'lightningarrestor':
        return 'Lightning Arrestor';
      default:
        return workType;
    }
  }
}
