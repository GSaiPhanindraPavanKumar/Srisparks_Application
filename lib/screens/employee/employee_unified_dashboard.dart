import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../models/installation_work_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../services/installation_service.dart';
import 'employee_sidebar.dart';
import 'employee_work_detail_screen.dart';
import '../../config/app_router.dart';

class EmployeeUnifiedDashboard extends StatefulWidget {
  const EmployeeUnifiedDashboard({super.key});

  @override
  State<EmployeeUnifiedDashboard> createState() =>
      _EmployeeUnifiedDashboardState();
}

class _EmployeeUnifiedDashboardState extends State<EmployeeUnifiedDashboard>
    with TickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final InstallationService _installationService = InstallationService();

  late TabController _tabController;

  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];

  UserModel? _currentUser;

  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedPhase = 'all';
  String _selectedView = 'all'; // 'all' or 'assigned'

  final List<String> _phases = [
    'all',
    'application',
    'amount',
    'material',
    'installation',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCurrentUser();
    _loadCustomers();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedPhase = _phases[_tabController.index];
        _filterCustomers();
      });
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authService.getCurrentUser();
      final userId = user?.id;

      if (user?.officeId != null) {
        // Load customers from employee's office
        final customers = await _customerService.getCustomersByOffice(
          user!.officeId!,
        );
        setState(() {
          _customers = customers;
          _filterCustomers();
        });
      } else {
        // Load all customers if no office restriction
        final customers = await _customerService.getAllApplications();
        setState(() {
          _customers = customers;
          _filterCustomers();
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load customers: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCustomers() {
    setState(() {
      List<CustomerModel> sourceList = _customers;

      _filteredCustomers = sourceList.where((customer) {
        // Phase filter
        if (_selectedPhase != 'all' &&
            customer.currentPhase != _selectedPhase) {
          return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!customer.name.toLowerCase().contains(query) &&
              !(customer.email?.toLowerCase().contains(query) ?? false) &&
              !(customer.phoneNumber?.toLowerCase().contains(query) ?? false) &&
              !(customer.address?.toLowerCase().contains(query) ?? false)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sort by creation date (latest first)
      _filteredCustomers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Viewing all customers from your office',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (customer.email != null)
                        Text(
                          customer.email!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    customer.currentPhase.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    customer.phoneNumber ?? 'No phone',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customer.address ?? 'No address',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Phase: ${customer.currentPhase.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${_formatDateTime(customer.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),

            // Employee actions based on phase
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _viewDetails(customer),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),

                if (customer.currentPhase == 'installation') ...[
                  FutureBuilder<List<InstallationWorkItem>>(
                    future: _getAssignedWorkItems(customer.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          width: 120,
                          height: 36,
                          padding: const EdgeInsets.all(8),
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        // Employee is not assigned to this installation
                        return const SizedBox.shrink();
                      }

                      final workItems = snapshot.data!;

                      return ElevatedButton.icon(
                        onPressed: () =>
                            _viewInstallationWork(customer, workItems),
                        icon: const Icon(Icons.construction, size: 16),
                        label: Text(
                          'Installation Work (${workItems.length})',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // For non-installation phases, keep existing buttons
                  if (customer.currentPhase == 'application') ...[
                    ElevatedButton.icon(
                      onPressed: () => _conductSiteSurvey(customer),
                      icon: const Icon(Icons.location_searching, size: 16),
                      label: const Text('Site Survey'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],

                  if (customer.currentPhase == 'survey') ...[
                    ElevatedButton.icon(
                      onPressed: () => _completeSurvey(customer),
                      icon: const Icon(Icons.assignment_turned_in, size: 16),
                      label: const Text('Complete Survey'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ],

                // General update button for any phase
                ElevatedButton.icon(
                  onPressed: () => _updateProgress(customer),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _conductSiteSurvey(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conduct Site Survey'),
        content: Text('Start site survey for ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Site survey started')),
              );
              _loadCustomers();
            },
            child: const Text('Start Survey'),
          ),
        ],
      ),
    );
  }

  void _completeSurvey(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Site Survey'),
        content: Text('Complete site survey for ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Site survey completed')),
              );
              _loadCustomers();
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _viewDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${customer.name} - Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', customer.name),
              _buildDetailRow('Email', customer.email ?? 'Not provided'),
              _buildDetailRow('Phone', customer.phoneNumber ?? 'Not provided'),
              _buildDetailRow('Address', customer.address ?? 'Not provided'),
              _buildDetailRow('Project', customer.projectSummary),
              _buildDetailRow('Current Phase', customer.currentPhase),
              _buildDetailRow(
                'Service Number',
                customer.electricMeterServiceNumber ?? 'Not provided',
              ),
              if (customer.currentPhase == 'application') ...[
                _buildDetailRow(
                  'Application Status',
                  customer.applicationStatusDisplayName,
                ),
                if (customer.siteSurveyCompleted)
                  _buildDetailRow('Survey Status', 'Completed')
                else
                  _buildDetailRow('Survey Status', 'Pending'),
              ],
              if (customer.applicationNotes != null)
                _buildDetailRow('Notes', customer.applicationNotes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _updateProgress(CustomerModel customer) {
    // TODO: Navigate to customer update form
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updating progress for ${customer.name}')),
    );
  }

  // Get work items assigned to the current employee for a specific customer
  Future<List<InstallationWorkItem>> _getAssignedWorkItems(
    String customerId,
  ) async {
    try {
      if (_currentUser == null) return [];

      final project = await _installationService.getInstallationProject(
        customerId,
      );
      if (project == null) return [];

      // Filter work items assigned to current employee
      final assignedWorkItems = project.workItems.where((workItem) {
        return workItem.leadEmployeeId == _currentUser!.id ||
            workItem.teamMemberIds.contains(_currentUser!.id);
      }).toList();

      return assignedWorkItems;
    } catch (e) {
      print('Error getting assigned work items: $e');
      return [];
    }
  }

  void _viewInstallationWork(
    CustomerModel customer,
    List<InstallationWorkItem> workItems,
  ) {
    // If only one work item, navigate directly to detail screen
    if (workItems.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EmployeeWorkDetailScreen(workItemId: workItems.first.id),
        ),
      );
    } else {
      // Show selection dialog for multiple work items
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${customer.name} - Installation Work'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select work item to manage:'),
                const SizedBox(height: 16),
                ...workItems
                    .map(
                      (workItem) => Card(
                        child: ListTile(
                          leading: Icon(
                            _getWorkTypeIcon(workItem.workType),
                            color: _getStatusColor(workItem.status),
                          ),
                          title: Text(workItem.workType.displayName),
                          subtitle: Text(
                            'Status: ${workItem.status.displayName}',
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmployeeWorkDetailScreen(
                                  workItemId: workItem.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
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

  Color _getStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.notStarted:
        return Colors.grey;
      case WorkStatus.inProgress:
        return Colors.orange;
      case WorkStatus.completed:
        return Colors.green;
      case WorkStatus.verified:
        return Colors.blue;
      case WorkStatus.acknowledged:
        return Colors.purple;
      case WorkStatus.approved:
        return Colors.teal;
      case WorkStatus.awaitingCompletion:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceList = _customers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard - Customer View'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createCustomerApplication);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'All (${sourceList.length})'),
            Tab(
              text:
                  'Application (${sourceList.where((c) => c.currentPhase == 'application').length})',
            ),
            Tab(
              text:
                  'Amount (${sourceList.where((c) => c.currentPhase == 'amount').length})',
            ),
            Tab(
              text:
                  'Material (${sourceList.where((c) => c.currentPhase == 'material').length})',
            ),
            Tab(
              text:
                  'Installation (${sourceList.where((c) => c.currentPhase == 'installation').length})',
            ),
            Tab(
              text:
                  'Completed (${sourceList.where((c) => c.currentPhase == 'completed').length})',
            ),
          ],
        ),
      ),
      drawer: EmployeeSidebar(
        currentUser: _currentUser,
        onLogout: () => Navigator.pushReplacementNamed(context, AppRoutes.auth),
      ),
      body: Column(
        children: [
          // View Toggle
          _buildViewToggle(),

          // Search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterCustomers();
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCustomers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedView == 'assigned'
                              ? 'No assigned customers found'
                              : 'No customers found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_selectedView == 'assigned') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Contact your lead for work assignments',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCustomers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        return _buildCustomerCard(_filteredCustomers[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
