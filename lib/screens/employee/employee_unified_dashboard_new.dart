import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import 'employee_sidebar.dart';
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
    _tabController = TabController(length: _phases.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedPhase = _phases[_tabController.index];
      });
      _filterCustomers();
    });
    _loadCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authService.getCurrentUser();

      if (user?.officeId != null) {
        // Load customers from employee's office
        final customers = await _customerService.getCustomersByOffice(
          user!.officeId!,
        );

        setState(() {
          _customers = customers;
          _currentUser = user;
          _filteredCustomers = customers;
        });
        _filterCustomers();
      } else {
        setState(() {
          _error = 'No office assigned to user';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load customers: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCustomers() {
    List<CustomerModel> filtered = _customers;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        return customer.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (customer.email?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (customer.phoneNumber?.contains(_searchQuery) ?? false);
      }).toList();
    }

    // Filter by phase
    if (_selectedPhase != 'all') {
      filtered = filtered
          .where((customer) => customer.currentPhase == _selectedPhase)
          .toList();
    }

    // Filter by view (all vs assigned)
    if (_selectedView == 'assigned') {
      // For employees, we might filter by assigned customers in the future
      // For now, show all customers from their office
    }

    setState(() {
      _filteredCustomers = filtered;
    });
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Text(
              'View: ${_selectedView == 'all' ? 'All Customers' : 'Assigned Customers'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedView = _selectedView == 'all' ? 'assigned' : 'all';
              });
              _filterCustomers();
            },
            child: Text(_selectedView == 'all' ? 'Show Assigned' : 'Show All'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No customers found',
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
                    customer.currentPhase,
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
                Text(customer.phoneNumber ?? 'No phone'),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(child: Text(customer.address ?? 'No address')),
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
                // Phase-specific status indicators
                if (customer.currentPhase == 'amount') ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: customer.calculatedPaymentStatus == 'Fully Paid'
                          ? Colors.green
                          : customer.calculatedPaymentStatus == 'Partially Paid'
                          ? Colors.orange
                          : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customer.calculatedPaymentStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (customer.currentPhase == 'material') ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: customer.materialAllocationStatus == 'delivered'
                          ? Colors.green
                          : customer.materialAllocationStatus == 'allocated'
                          ? Colors.orange
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customer.materialAllocationStatus.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${_formatDateTime(customer.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),

            // Employee actions based on phase
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                const SizedBox(width: 8),

                // Phase-specific actions for employees
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
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
                ],

                if (customer.currentPhase == 'amount') ...[
                  ElevatedButton.icon(
                    onPressed: () => _viewAmountInfo(customer),
                    icon: const Icon(Icons.monetization_on, size: 16),
                    label: const Text('Amount Info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                if (customer.currentPhase == 'material') ...[
                  ElevatedButton.icon(
                    onPressed: () => _viewMaterialInfo(customer),
                    icon: const Icon(Icons.inventory, size: 16),
                    label: const Text('Material Info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                if (customer.currentPhase == 'installation') ...[
                  ElevatedButton.icon(
                    onPressed: () => _completeInstallation(customer),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
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

  void _completeInstallation(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Installation'),
        content: Text('Mark installation as completed for ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Installation marked as completed'),
                ),
              );
              _loadCustomers();
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  // Employee restricted amount info view (only KW and payment status)
  void _viewAmountInfo(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${customer.name} - Amount Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Employee can only see KW and payment status, not amounts
              _buildAmountInfoCard(
                'Project Capacity',
                '${customer.amountKw?.toString() ?? 'Not specified'} KW',
                Icons.solar_power,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildAmountInfoCard(
                'Payment Status',
                customer.calculatedPaymentStatus,
                Icons.payment,
                customer.calculatedPaymentStatus == 'Fully Paid'
                    ? Colors.green
                    : customer.calculatedPaymentStatus == 'Partially Paid'
                    ? Colors.orange
                    : Colors.red,
              ),
              const SizedBox(height: 12),
              _buildAmountInfoCard(
                'Project Details',
                customer.projectSummary,
                Icons.description,
                Colors.blue,
              ),
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

  // Employee restricted material info view
  void _viewMaterialInfo(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${customer.name} - Material Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Employee can see basic material info but not sensitive details
              _buildAmountInfoCard(
                'Material Status',
                customer.materialAllocationStatus.toUpperCase(),
                Icons.inventory_2,
                customer.materialAllocationStatus == 'delivered'
                    ? Colors.green
                    : customer.materialAllocationStatus == 'allocated'
                    ? Colors.orange
                    : Colors.grey,
              ),
              const SizedBox(height: 12),
              _buildAmountInfoCard(
                'Project Capacity',
                '${customer.amountKw?.toString() ?? 'Not specified'} KW',
                Icons.solar_power,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              if (customer.materialAllocationNotes != null &&
                  customer.materialAllocationNotes!.isNotEmpty)
                _buildAmountInfoCard(
                  'Material Notes',
                  customer.materialAllocationNotes!,
                  Icons.note,
                  Colors.blue,
                ),
              if (customer.materialAllocationNotes != null &&
                  customer.materialAllocationNotes!.isNotEmpty)
                const SizedBox(height: 12),
              if (customer.materialDeliveryDate != null)
                _buildAmountInfoCard(
                  'Delivery Date',
                  _formatDateTime(customer.materialDeliveryDate!),
                  Icons.local_shipping,
                  Colors.green,
                ),
              if (customer.materialDeliveryDate != null)
                const SizedBox(height: 12),
              _buildAmountInfoCard(
                'Project Details',
                customer.projectSummary,
                Icons.description,
                Colors.blue,
              ),
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

  Widget _buildAmountInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
