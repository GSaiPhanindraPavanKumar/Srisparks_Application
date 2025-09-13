import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../models/installation_work_model.dart';
import '../../services/installation_service.dart';
import '../../services/user_service.dart';
import '../shared/work_item_details_dashboard.dart';

class InstallationManagementDashboard extends StatefulWidget {
  final CustomerModel customer;
  final InstallationProject project;
  final UserModel currentUser;

  const InstallationManagementDashboard({
    super.key,
    required this.customer,
    required this.project,
    required this.currentUser,
  });

  @override
  State<InstallationManagementDashboard> createState() =>
      _InstallationManagementDashboardState();
}

class _InstallationManagementDashboardState
    extends State<InstallationManagementDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  InstallationProject? _project;
  List<UserModel> _assignedEmployees = [];
  Map<String, List<UserModel>> _workItemEmployees = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _project = widget.project;
    _loadProjectDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectDetails() async {
    setState(() => _isLoading = true);
    try {
      // Reload project with latest data
      _project = await InstallationService().getInstallationProject(
        widget.customer.id,
      );

      if (_project != null) {
        // Load assigned employees for each work item
        _workItemEmployees.clear();
        Set<String> allEmployeeIds = {};

        for (final workItem in _project!.workItems) {
          print(
            'Work item ID: "${workItem.id}", team members: ${workItem.teamMemberIds}',
          );

          // Use the team member IDs that are already in the work item data
          if (workItem.teamMemberIds.isNotEmpty) {
            // Create UserModel objects from the team member data
            List<UserModel> employees = [];
            for (int i = 0; i < workItem.teamMemberIds.length; i++) {
              final employeeId = workItem.teamMemberIds[i];
              final employeeName = i < workItem.teamMemberNames.length
                  ? workItem.teamMemberNames[i]
                  : 'Unknown Employee';

              employees.add(
                UserModel(
                  id: employeeId,
                  fullName: employeeName,
                  email: '', // We don't have email in this data
                  phoneNumber: '', // We don't have phone in this data
                  role: UserRole.employee, // Default role
                  status: UserStatus.active, // Assume active
                  officeId: '', // We don't have office ID in this data
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );

              allEmployeeIds.add(employeeId);
            }

            _workItemEmployees[workItem.id] = employees;
          } else {
            _workItemEmployees[workItem.id] = [];
          }
        }

        // Load complete employee details for unique employees
        _assignedEmployees = await _loadEmployeeDetails(
          allEmployeeIds.toList(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading project details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<UserModel>> _loadEmployeeDetails(List<String> employeeIds) async {
    try {
      final employees = <UserModel>[];
      for (final id in employeeIds) {
        final employee = await UserService().getUserById(id);
        if (employee != null) employees.add(employee);
      }
      return employees;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Installation Management'),
            Text(
              widget.customer.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.work), text: 'Work Items'),
            Tab(icon: Icon(Icons.people), text: 'Team'),
            Tab(icon: Icon(Icons.timeline), text: 'Progress'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _project == null
          ? const Center(
              child: Text(
                'No installation project found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildWorkItemsTab(),
                _buildTeamTab(),
                _buildProgressTab(),
              ],
            ),
      floatingActionButton: _project != null
          ? FloatingActionButton.extended(
              onPressed: _showQuickActions,
              icon: const Icon(Icons.settings),
              label: const Text('Quick Actions'),
              backgroundColor: Colors.blue.shade700,
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Summary Card
          _buildProjectSummaryCard(),
          const SizedBox(height: 16),

          // Customer Information Card
          _buildCustomerInfoCard(),
          const SizedBox(height: 16),

          // Project Status Card
          _buildProjectStatusCard(),
          const SizedBox(height: 16),

          // Quick Stats
          _buildQuickStatsCard(),
        ],
      ),
    );
  }

  Widget _buildProjectSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Project Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Project ID', _project!.projectId),
            _buildInfoRow('Customer', widget.customer.name),
            _buildInfoRow('System Size', '${widget.customer.kw ?? 'N/A'} kW'),
            _buildInfoRow('Assigned Date', _formatDate(_project!.createdAt)),
            _buildInfoRow('Current Status', _getProjectStatusText()),
            if (_project!.workItems.isNotEmpty)
              _buildInfoRow(
                'Progress',
                '${_project!.progressPercentage.toStringAsFixed(1)}%',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Customer Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Name', widget.customer.name),
            if (widget.customer.address != null)
              _buildInfoRow('Address', widget.customer.address!),
            if (widget.customer.phoneNumber != null)
              _buildInfoRow('Phone', widget.customer.phoneNumber!),
            if (widget.customer.email != null)
              _buildInfoRow('Email', widget.customer.email!),
            _buildInfoRow(
              'Location',
              '${_project!.siteLatitude.toStringAsFixed(6)}, ${_project!.siteLongitude.toStringAsFixed(6)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectStatusCard() {
    final status = _project!.overallStatus;
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  'Project Status',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Status indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(_getStatusIcon(status), size: 48, color: statusColor),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (_project!.workItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _project!.progressPercentage / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_project!.progressPercentage.toStringAsFixed(1)}% Complete',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Quick Statistics',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Work Items',
                    _project!.totalWorkItems.toString(),
                    Icons.work,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    _project!.completedWorkItems.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Verified',
                    _project!.verifiedWorkItems.toString(),
                    Icons.verified,
                    Colors.teal,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Team Members',
                    _assignedEmployees.length.toString(),
                    Icons.people,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkItemsTab() {
    return RefreshIndicator(
      onRefresh: _loadProjectDetails,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _project!.workItems.length,
        itemBuilder: (context, index) {
          final workItem = _project!.workItems[index];
          final assignedEmployees = _workItemEmployees[workItem.id] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(workItem.status),
                child: Icon(
                  _getWorkTypeIcon(workItem.workType),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            workItem.status,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          workItem.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(workItem.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_calculateWorkItemProgress(workItem)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (assignedEmployees.isNotEmpty)
                    Text(
                      'Assigned to: ${assignedEmployees.map((e) => e.fullName).join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _calculateWorkItemProgress(workItem) / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getStatusColor(workItem.status),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${_calculateWorkItemProgress(workItem)}%'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Work item details
                      if (workItem.startTime != null)
                        _buildDetailRow(
                          'Started',
                          _formatDateTime(workItem.startTime!),
                        ),
                      if (workItem.endTime != null)
                        _buildDetailRow(
                          'Completed',
                          _formatDateTime(workItem.endTime!),
                        ),
                      _buildDetailRow(
                        'Total Work Hours',
                        workItem.totalWorkHours.toStringAsFixed(1),
                      ),
                      _buildDetailRow(
                        'Employees Working',
                        '${workItem.employeesWorking} of ${workItem.totalAssignedEmployees}',
                      ),
                      if (workItem.isVerified)
                        _buildDetailRow('Verification Status', 'Verified'),

                      const SizedBox(height: 16),

                      // Assigned employees
                      if (assignedEmployees.isNotEmpty) ...[
                        Text(
                          'Assigned Team Members',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: assignedEmployees.map((employee) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.blue.shade700,
                                child: Text(
                                  (employee.fullName ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              label: Text(employee.fullName ?? 'Unknown'),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _manageEmployees(workItem),
                            icon: const Icon(Icons.people, size: 18),
                            label: const Text('Manage Team'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              print(
                                'View Details clicked for: ${workItem.workType.displayName}',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'View Details clicked for ${workItem.workType.displayName}',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              _viewWorkItemDetails(workItem);
                            },
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamTab() {
    return RefreshIndicator(
      onRefresh: _loadProjectDetails,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Team overview card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Team Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Total Team Members: ${_assignedEmployees.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add/Remove team members button
                  ElevatedButton.icon(
                    onPressed: _manageProjectTeam,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Manage Project Team'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Team members list
          if (_assignedEmployees.isNotEmpty) ...[
            Text(
              'Team Members',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ..._assignedEmployees.map((employee) {
              final workItemsAssigned = _getEmployeeWorkItems(employee.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade700,
                    child: Text(
                      (employee.fullName ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    employee.fullName ?? 'Unknown Employee',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${employee.role}'),
                      Text(
                        'Assigned to ${workItemsAssigned.length} work item(s)',
                      ),
                      if (workItemsAssigned.isNotEmpty)
                        Text(
                          'Tasks: ${workItemsAssigned.map((w) => w.workType.displayName).join(', ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showEmployeeOptions(employee),
                  ),
                  onTap: () => _viewEmployeeDetails(employee),
                ),
              );
            }).toList(),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No team members assigned yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _manageProjectTeam,
                      child: const Text('Assign Team Members'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return RefreshIndicator(
      onRefresh: _loadProjectDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall progress card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Overall Progress',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Progress circle
                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: _project!.progressPercentage / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green.shade600,
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_project!.progressPercentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Complete',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Progress breakdown
                    _buildProgressItem(
                      'Not Started',
                      _project!.workItems
                          .where((w) => w.status == WorkStatus.notStarted)
                          .length,
                      _project!.totalWorkItems,
                      Colors.grey,
                    ),
                    _buildProgressItem(
                      'In Progress',
                      _project!.workItems
                          .where((w) => w.status == WorkStatus.inProgress)
                          .length,
                      _project!.totalWorkItems,
                      Colors.orange,
                    ),
                    _buildProgressItem(
                      'Completed',
                      _project!.completedWorkItems,
                      _project!.totalWorkItems,
                      Colors.blue,
                    ),
                    _buildProgressItem(
                      'Verified',
                      _project!.verifiedWorkItems,
                      _project!.totalWorkItems,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Timeline card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Project Timeline',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    _buildTimelineItem(
                      'Project Created',
                      _formatDateTime(_project!.createdAt),
                      Icons.start,
                      Colors.blue,
                      true,
                    ),

                    // Work item timeline
                    ..._project!.workItems
                        .where((w) => w.startTime != null)
                        .map((workItem) {
                          return _buildTimelineItem(
                            '${workItem.workType.displayName} Started',
                            _formatDateTime(workItem.startTime!),
                            Icons.play_arrow,
                            Colors.orange,
                            true,
                          );
                        })
                        .toList(),

                    ..._project!.workItems.where((w) => w.endTime != null).map((
                      workItem,
                    ) {
                      return _buildTimelineItem(
                        '${workItem.workType.displayName} Completed',
                        _formatDateTime(workItem.endTime!),
                        Icons.check_circle,
                        Colors.green,
                        true,
                      );
                    }).toList(),

                    // Future milestone
                    if (!_project!.isProjectCompleted)
                      _buildTimelineItem(
                        'Project Completion',
                        'Pending',
                        Icons.flag,
                        Colors.grey,
                        false,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '$count of $total',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    IconData icon,
    Color color,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isCompleted ? color : Colors.grey.shade300,
            child: Icon(
              icon,
              size: 16,
              color: isCompleted ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getProjectStatusText() {
    return _getStatusText(_project!.overallStatus);
  }

  Color _getStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.notStarted:
        return Colors.grey;
      case WorkStatus.inProgress:
        return Colors.orange;
      case WorkStatus.awaitingCompletion:
        return Colors.blue;
      case WorkStatus.completed:
        return Colors.green;
      case WorkStatus.verified:
        return Colors.teal;
      case WorkStatus.acknowledged:
        return Colors.purple;
      case WorkStatus.approved:
        return Colors.indigo;
    }
  }

  String _getStatusText(WorkStatus status) {
    switch (status) {
      case WorkStatus.notStarted:
        return 'Not Started';
      case WorkStatus.inProgress:
        return 'In Progress';
      case WorkStatus.awaitingCompletion:
        return 'Awaiting Completion';
      case WorkStatus.completed:
        return 'Completed';
      case WorkStatus.verified:
        return 'Verified';
      case WorkStatus.acknowledged:
        return 'Acknowledged';
      case WorkStatus.approved:
        return 'Approved';
    }
  }

  IconData _getStatusIcon(WorkStatus status) {
    switch (status) {
      case WorkStatus.notStarted:
        return Icons.schedule;
      case WorkStatus.inProgress:
        return Icons.play_circle;
      case WorkStatus.awaitingCompletion:
        return Icons.pending;
      case WorkStatus.completed:
        return Icons.check_circle;
      case WorkStatus.verified:
        return Icons.verified;
      case WorkStatus.acknowledged:
        return Icons.thumb_up;
      case WorkStatus.approved:
        return Icons.approval;
    }
  }

  IconData _getWorkTypeIcon(InstallationWorkType workType) {
    switch (workType) {
      case InstallationWorkType.structureWork:
        return Icons.construction;
      case InstallationWorkType.panels:
        return Icons.solar_power;
      case InstallationWorkType.inverterWiring:
        return Icons.electrical_services;
      case InstallationWorkType.earthing:
        return Icons.electrical_services;
      case InstallationWorkType.lightningArrestor:
        return Icons.flash_on;
    }
  }

  List<InstallationWorkItem> _getEmployeeWorkItems(String employeeId) {
    final workItemIds = _workItemEmployees.entries
        .where((entry) => entry.value.any((emp) => emp.id == employeeId))
        .map((entry) => entry.key)
        .toSet();

    return _project!.workItems
        .where((w) => workItemIds.contains(w.id))
        .toList();
  }

  // Calculate work item progress based on status
  int _calculateWorkItemProgress(InstallationWorkItem workItem) {
    switch (workItem.status) {
      case WorkStatus.notStarted:
        return 0;
      case WorkStatus.inProgress:
        // Calculate based on working employees percentage
        if (workItem.totalAssignedEmployees > 0) {
          return ((workItem.employeesWorking /
                      workItem.totalAssignedEmployees) *
                  50)
              .round();
        }
        return 25;
      case WorkStatus.awaitingCompletion:
        return 75;
      case WorkStatus.completed:
        return 100;
      case WorkStatus.verified:
      case WorkStatus.acknowledged:
      case WorkStatus.approved:
        return 100;
    }
  }

  // Action methods
  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Data'),
              onTap: () {
                Navigator.pop(context);
                _loadProjectDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Team'),
              onTap: () {
                Navigator.pop(context);
                _manageProjectTeam();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Project'),
              onTap: () {
                Navigator.pop(context);
                _editProject();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('View Location'),
              onTap: () {
                Navigator.pop(context);
                _viewProjectLocation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _manageEmployees(InstallationWorkItem workItem) {
    // TODO: Implement employee management for specific work item
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Manage employees for ${workItem.workType.displayName}'),
      ),
    );
  }

  void _viewWorkItemDetails(InstallationWorkItem workItem) {
    print(
      'Navigating to work item details dashboard for: ${workItem.workType.displayName}',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkItemDetailsDashboard(
          workItem: workItem,
          customerName: widget.customer.name,
        ),
      ),
    );
  }

  void _manageProjectTeam() {
    // TODO: Implement project team management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manage project team functionality coming soon'),
      ),
    );
  }

  void _showEmployeeOptions(UserModel employee) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              employee.fullName ?? 'Unknown Employee',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _viewEmployeeDetails(employee);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Manage Assignments'),
              onTap: () {
                Navigator.pop(context);
                _manageEmployeeAssignments(employee);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Remove from Project'),
              onTap: () {
                Navigator.pop(context);
                _removeEmployeeFromProject(employee);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewEmployeeDetails(UserModel employee) {
    // TODO: Navigate to employee details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${employee.fullName}')),
    );
  }

  void _manageEmployeeAssignments(UserModel employee) {
    // TODO: Implement employee assignment management
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manage assignments for ${employee.fullName}')),
    );
  }

  void _removeEmployeeFromProject(UserModel employee) {
    // TODO: Implement employee removal from project
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Employee'),
        content: Text(
          'Remove ${employee.fullName} from this installation project?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${employee.fullName} removed from project'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _editProject() {
    // TODO: Implement project editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit project functionality coming soon')),
    );
  }

  void _viewProjectLocation() {
    // TODO: Implement location viewing (map)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location: ${_project!.siteLatitude}, ${_project!.siteLongitude}',
        ),
      ),
    );
  }
}

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
  Map<String, List<Map<String, dynamic>>> _sessionData = {};
  bool _isLoading = true;
  String? _error;

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

      final sessionData = await widget.installationService
          .getWorkItemSessionDetails(widget.workItem.id);

      if (mounted) {
        setState(() {
          _sessionData = sessionData;
          _isLoading = false;
          _error = null;
        });
        print(
          'Session data loaded successfully: ${sessionData.keys.length} employees found',
        );
      }
    } catch (e) {
      print('Error loading session details: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getWorkTypeIcon(widget.workItem.workType),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Work Item Details',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.workItem.workType.displayName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text('Error loading session details'),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _sessionData.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.work_off,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text('No work sessions found'),
                            const SizedBox(height: 8),
                            Text(
                              'This work item has no recorded work sessions yet.',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _buildSessionContent(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSessionContent() {
    List<Widget> widgets = [];

    // Work item basic info
    widgets.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        widget.workItem.status,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.workItem.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(widget.workItem.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text('${widget.workItem.progressPercentage}% Complete'),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.workItem.startTime != null)
                Text(
                  'Started: ${_formatDateTime(widget.workItem.startTime!)}',
                  style: const TextStyle(fontSize: 12),
                ),
              if (widget.workItem.endTime != null)
                Text(
                  'Completed: ${_formatDateTime(widget.workItem.endTime!)}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );

    widgets.add(const SizedBox(height: 8));

    // Session data grouped by employee
    for (final entry in _sessionData.entries) {
      final employeeName = entry.key;
      final sessions = entry.value;

      widgets.add(
        Card(
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade700,
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
            subtitle: Text(
              '${sessions.length} work session${sessions.length != 1 ? 's' : ''}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: sessions.map((session) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.play_arrow,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Started: ${_formatDateTime(DateTime.parse(session['start_time']))}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (session['end_time'] != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.stop,
                                  size: 16,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ended: ${_formatDateTime(DateTime.parse(session['end_time']))}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Colors.blue.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Duration: ${_calculateDuration(session['start_time'], session['end_time'])}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.radio_button_on,
                                  size: 16,
                                  color: Colors.orange.shade600,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Currently in progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (session['session_notes'] != null &&
                              session['session_notes']
                                  .toString()
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notes:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    session['session_notes'].toString(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration(String startTime, String endTime) {
    final start = DateTime.parse(startTime);
    final end = DateTime.parse(endTime);
    final duration = end.difference(start);

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Color _getStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.notStarted:
        return Colors.grey;
      case WorkStatus.inProgress:
        return Colors.orange;
      case WorkStatus.awaitingCompletion:
        return Colors.blue;
      case WorkStatus.completed:
        return Colors.green;
      case WorkStatus.verified:
        return Colors.teal;
      case WorkStatus.acknowledged:
        return Colors.purple;
      case WorkStatus.approved:
        return Colors.indigo;
    }
  }

  IconData _getWorkTypeIcon(InstallationWorkType workType) {
    switch (workType) {
      case InstallationWorkType.structureWork:
        return Icons.construction;
      case InstallationWorkType.panels:
        return Icons.solar_power;
      case InstallationWorkType.inverterWiring:
        return Icons.electrical_services;
      case InstallationWorkType.earthing:
        return Icons.electrical_services;
      case InstallationWorkType.lightningArrestor:
        return Icons.flash_on;
    }
  }
}
