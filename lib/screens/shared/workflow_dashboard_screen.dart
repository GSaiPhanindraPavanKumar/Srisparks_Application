import 'package:flutter/material.dart';
import '../../models/workflow_models.dart';
import '../../models/user_model.dart';
import '../../services/workflow_service.dart';
import '../../services/auth_service.dart';

class WorkflowDashboardScreen extends StatefulWidget {
  const WorkflowDashboardScreen({super.key});

  @override
  State<WorkflowDashboardScreen> createState() =>
      _WorkflowDashboardScreenState();
}

class _WorkflowDashboardScreenState extends State<WorkflowDashboardScreen>
    with TickerProviderStateMixin {
  final WorkflowService _workflowService = WorkflowService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  UserModel? _currentUser;
  Map<String, dynamic>? _analytics;
  List<WorkAssignmentModel> _workAssignments = [];
  List<CustomerComplaintModel> _complaints = [];
  List<InventoryComponentModel> _lowStockItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUserProfile();

      if (_currentUser != null) {
        final officeId = _currentUser!.role == UserRole.director
            ? null
            : _currentUser!.officeId;

        // Load analytics
        if (officeId != null) {
          _analytics = await _workflowService.getWorkflowAnalytics(officeId);
        }

        // Load current work assignments
        _workAssignments = await _workflowService.getWorkAssignments(
          officeId: officeId,
          isCompleted: false,
        );

        // Load active complaints
        _complaints = await _workflowService.getCustomerComplaints(
          officeId: officeId,
          status: 'open',
        );

        // Load low stock items
        _lowStockItems = await _workflowService.getInventoryComponents(
          officeId: officeId,
          lowStockOnly: true,
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow Management'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.assignment), text: 'Work'),
            Tab(icon: Icon(Icons.report_problem), text: 'Complaints'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildWorkTab(),
                _buildComplaintsTab(),
                _buildInventoryTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Distribution Cards
          const Text(
            'Customer Status Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStatusDistributionGrid(),

          const SizedBox(height: 24),

          // Quick Stats
          const Text(
            'Quick Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Work',
                  '${_workAssignments.length}',
                  Icons.work,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Open Complaints',
                  '${_complaints.length}',
                  Icons.report,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Low Stock Items',
                  '${_lowStockItems.length}',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activities
          const Text(
            'Recent Work Assignments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._workAssignments
              .take(5)
              .map((assignment) => _buildWorkAssignmentCard(assignment)),
        ],
      ),
    );
  }

  Widget _buildStatusDistributionGrid() {
    if (_analytics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Analytics not available'),
        ),
      );
    }

    final statusData = _analytics!['status_distribution'] as List? ?? [];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: CustomerStatus.values.map((status) {
        final count = statusData
            .where((item) => item['status'] == status.name)
            .map((item) => item['count'] as int)
            .fold(0, (a, b) => a + b);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDisplayName(status),
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getStatusDisplayName(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.application:
        return 'Application';
      case CustomerStatus.loanApproval:
        return 'Loan';
      case CustomerStatus.installationAssigned:
        return 'Assigned';
      case CustomerStatus.material:
        return 'Material';
      case CustomerStatus.installation:
        return 'Installation';
      case CustomerStatus.documentation:
        return 'Documentation';
      case CustomerStatus.meter:
        return 'Meter';
      case CustomerStatus.inverterTurnOn:
        return 'Inverter';
      case CustomerStatus.completed:
        return 'Completed';
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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

  Widget _buildWorkTab() {
    return Column(
      children: [
        // Filter Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CustomerStatus>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Stage',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Stages'),
                    ),
                    ...CustomerStatus.values.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusDisplayName(status)),
                      ),
                    ),
                  ],
                  onChanged: (status) {
                    // TODO: Implement filtering
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateWorkAssignmentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('New Assignment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Work Assignments List
        Expanded(
          child: _workAssignments.isEmpty
              ? const Center(
                  child: Text(
                    'No active work assignments',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _workAssignments.length,
                  itemBuilder: (context, index) {
                    return _buildWorkAssignmentCard(_workAssignments[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWorkAssignmentCard(WorkAssignmentModel assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStageColor(assignment.workStage),
          child: Icon(
            _getStageIcon(assignment.workStage),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          assignment.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getStatusDisplayName(assignment.workStage),
              style: TextStyle(color: _getStageColor(assignment.workStage)),
            ),
            Text(
              'Location: ${assignment.locationDisplayName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (assignment.scheduledDate != null)
              Text(
                'Scheduled: ${assignment.scheduledDate!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned Employees:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: assignment.assignedUserNames
                      .map(
                        (name) => Chip(
                          label: Text(name),
                          backgroundColor: Colors.orange.shade100,
                          labelStyle: const TextStyle(fontSize: 12),
                        ),
                      )
                      .toList(),
                ),

                if (assignment.notes != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(assignment.notes!),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAddEmployeeDialog(assignment),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Employee'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showUpdateProgressDialog(assignment),
                      icon: const Icon(Icons.update),
                      label: const Text('Update Progress'),
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
        ],
      ),
    );
  }

  Color _getStageColor(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.application:
        return Colors.purple;
      case CustomerStatus.loanApproval:
        return Colors.indigo;
      case CustomerStatus.installationAssigned:
        return Colors.blue;
      case CustomerStatus.material:
        return Colors.cyan;
      case CustomerStatus.installation:
        return Colors.orange;
      case CustomerStatus.documentation:
        return Colors.amber;
      case CustomerStatus.meter:
        return Colors.lime;
      case CustomerStatus.inverterTurnOn:
        return Colors.lightGreen;
      case CustomerStatus.completed:
        return Colors.green;
    }
  }

  IconData _getStageIcon(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.application:
        return Icons.description;
      case CustomerStatus.loanApproval:
        return Icons.account_balance;
      case CustomerStatus.installationAssigned:
        return Icons.assignment;
      case CustomerStatus.material:
        return Icons.inventory;
      case CustomerStatus.installation:
        return Icons.build;
      case CustomerStatus.documentation:
        return Icons.folder;
      case CustomerStatus.meter:
        return Icons.speed;
      case CustomerStatus.inverterTurnOn:
        return Icons.power;
      case CustomerStatus.completed:
        return Icons.check_circle;
    }
  }

  Widget _buildComplaintsTab() {
    return Column(
      children: [
        // Complaint Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Customer Complaints (${_complaints.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateComplaintDialog(),
                icon: const Icon(Icons.add),
                label: const Text('New Complaint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Complaints List
        Expanded(
          child: _complaints.isEmpty
              ? const Center(
                  child: Text(
                    'No active complaints',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    return _buildComplaintCard(_complaints[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(CustomerComplaintModel complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: complaint.serviceType == ServiceType.freeService
              ? Colors.green
              : Colors.red,
          child: Icon(
            complaint.serviceType == ServiceType.freeService
                ? Icons.free_breakfast
                : Icons.payment,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          complaint.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${complaint.customerName}'),
            Text(
              'Type: ${complaint.typeDisplayName}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Service: ${complaint.serviceTypeDisplayName}',
              style: TextStyle(
                color: complaint.serviceType == ServiceType.freeService
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            complaint.priority.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        onTap: () => _showComplaintDetails(complaint),
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Column(
      children: [
        // Inventory Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Low Stock Alert (${_lowStockItems.length} items)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showInventoryManagement(),
                icon: const Icon(Icons.inventory),
                label: const Text('Manage Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Low Stock Items
        Expanded(
          child: _lowStockItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'All items are well stocked!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lowStockItems.length,
                  itemBuilder: (context, index) {
                    return _buildInventoryCard(_lowStockItems[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(InventoryComponentModel component) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red,
          child: const Icon(Icons.warning, color: Colors.white),
        ),
        title: Text(
          component.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${component.category}'),
            Text(
              'Current Stock: ${component.currentStock} ${component.unit}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Minimum Required: ${component.minimumStock} ${component.unit}',
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _showRestockDialog(component),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Restock'),
        ),
      ),
    );
  }

  // Dialog Methods (Placeholder implementations)
  void _showCreateWorkAssignmentDialog() {
    // TODO: Implement create work assignment dialog
    _showMessage('Create Work Assignment dialog - To be implemented');
  }

  void _showAddEmployeeDialog(WorkAssignmentModel assignment) {
    // TODO: Implement add employee dialog
    _showMessage('Add Employee dialog - To be implemented');
  }

  void _showUpdateProgressDialog(WorkAssignmentModel assignment) {
    // TODO: Implement update progress dialog
    _showMessage('Update Progress dialog - To be implemented');
  }

  void _showCreateComplaintDialog() {
    // TODO: Implement create complaint dialog
    _showMessage('Create Complaint dialog - To be implemented');
  }

  void _showComplaintDetails(CustomerComplaintModel complaint) {
    // TODO: Implement complaint details dialog
    _showMessage('Complaint Details dialog - To be implemented');
  }

  void _showInventoryManagement() {
    // TODO: Implement inventory management screen
    _showMessage('Inventory Management screen - To be implemented');
  }

  void _showRestockDialog(InventoryComponentModel component) {
    // TODO: Implement restock dialog
    _showMessage('Restock dialog - To be implemented');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
