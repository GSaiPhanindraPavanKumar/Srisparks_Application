import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../models/installation_work_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../services/installation_service.dart';
import '../shared/customer_details_screen.dart';
import 'installation_work_detail_screen.dart';

class EmployeeCustomerDashboard extends StatefulWidget {
  const EmployeeCustomerDashboard({super.key});

  @override
  State<EmployeeCustomerDashboard> createState() =>
      _EmployeeCustomerDashboardState();
}

class _EmployeeCustomerDashboardState extends State<EmployeeCustomerDashboard>
    with SingleTickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final InstallationService _installationService = InstallationService();

  late TabController _tabController;

  UserModel? _currentUser;
  List<CustomerModel> _allCustomers = [];
  List<CustomerModel> _applicationPhase = [];
  List<CustomerModel> _amountPhase = [];
  List<CustomerModel> _materialPhase = [];
  List<CustomerModel> _installationPhase = [];
  List<CustomerModel> _completedPhase = [];

  bool _isLoading = true;
  String _searchQuery = '';
  bool _sortLatestFirst = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
    ); // All phases + All customers
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

      // Employee can only see customers from their office
      if (_currentUser?.officeId != null) {
        _allCustomers = await _customerService.getCustomersByOffice(
          _currentUser!.officeId!,
        );
      }

      _filterCustomers();
    } catch (e) {
      _showMessage('Error loading customers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCustomers() {
    final query = _searchQuery.toLowerCase();

    List<CustomerModel> filteredCustomers = _allCustomers;

    // Apply search filter
    if (query.isNotEmpty) {
      filteredCustomers = filteredCustomers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.email?.toLowerCase().contains(query) == true ||
            customer.phoneNumber?.contains(query) == true ||
            customer.electricMeterServiceNumber?.toLowerCase().contains(
                  query,
                ) ==
                true;
      }).toList();
    }

    // Sort customers
    if (_sortLatestFirst) {
      filteredCustomers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filteredCustomers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    // Group by phases
    _applicationPhase = filteredCustomers
        .where((c) => c.currentPhase == 'application')
        .toList();

    _amountPhase = filteredCustomers
        .where((c) => c.currentPhase == 'amount')
        .toList();

    _materialPhase = filteredCustomers
        .where(
          (c) => [
            'material_allocation',
            'material_delivery',
          ].contains(c.currentPhase),
        )
        .toList();

    _installationPhase = filteredCustomers
        .where(
          (c) => [
            'installation',
            'documentation',
            'meter_connection',
            'inverter_turnon',
          ].contains(c.currentPhase),
        )
        .toList();

    _completedPhase = filteredCustomers
        .where((c) => ['completed', 'service_phase'].contains(c.currentPhase))
        .toList();

    setState(() {});
  }

  // Helper method to check if employee can see amount details
  bool _canSeeAmountDetails() {
    return _currentUser?.role == UserRole.lead;
  }

  // Helper method to check if customer is in installation phase
  bool _isInstallationPhase(String phase) {
    return [
      'installation',
      'documentation',
      'meter_connection',
      'inverter_turnon',
    ].contains(phase);
  }

  // Helper method to show installation work options
  void _showInstallationWorkOptions(CustomerModel customer) async {
    try {
      // Show loading dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading installation work...'),
            ],
          ),
        ),
      );

      // Get current user
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        Navigator.pop(context);
        _showErrorDialog('Authentication error. Please login again.');
        return;
      }

      // Get employee's work items for this customer
      final workItems = await _installationService.getEmployeeWorkItems(
        currentUser.id,
      );
      final customerWorkItems = workItems
          .where((item) => item.customerId == customer.id)
          .toList();

      // Close loading dialog
      Navigator.pop(context);

      // Show work options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Installation Work - ${customer.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Phase: ${customer.currentPhase}'),
                        Text(
                          'Location: ${customer.address ?? 'Not specified'}',
                        ),
                        if (customer.kw != null)
                          Text('System Size: ${customer.kw} kW'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Work items
                if (customerWorkItems.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No installation work assigned yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            'Please contact your manager for work assignments',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: customerWorkItems.length,
                      itemBuilder: (context, index) {
                        final workItem = customerWorkItems[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getWorkStatusColor(
                                workItem.status.name,
                              ),
                              child: Icon(
                                _getWorkStatusIcon(workItem.status.name),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              _getWorkTypeDisplayName(workItem.workType.name),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: ${_getWorkStatusDisplayName(workItem.status.name)}',
                                ),
                                LinearProgressIndicator(
                                  value: workItem.progressPercentage / 100,
                                  backgroundColor: Colors.grey[300],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () {
                                Navigator.pop(context);
                                _navigateToWorkItemWithCustomer(
                                  workItem,
                                  customer,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
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
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Failed to load installation work: $e');
    }
  }

  Widget _buildInstallationTasksList(CustomerModel customer) {
    List<String> tasks = _getInstallationTasks(customer.currentPhase);

    return Column(
      children: tasks
          .map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.build_circle,
                    size: 16,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(task, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  List<String> _getInstallationTasks(String phase) {
    switch (phase) {
      case 'installation':
        return [
          'Site survey and preparation',
          'Mounting structure installation',
          'Solar panel mounting',
          'DC wiring and connections',
        ];
      case 'documentation':
        return [
          'System documentation review',
          'Electrical certifications',
          'Compliance verification',
          'Photo documentation',
        ];
      case 'meter_connection':
        return [
          'Meter installation preparation',
          'Grid connection setup',
          'Safety compliance check',
          'Final testing',
        ];
      case 'inverter_turnon':
        return [
          'Inverter configuration',
          'System commissioning',
          'Performance testing',
          'Customer handover',
        ];
      default:
        return ['General installation tasks'];
    }
  }

  void _navigateToInstallationWork(CustomerModel customer) {
    // For now, show a detailed work management screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _buildInstallationWorkScreen(customer),
      ),
    );
  }

  Widget _buildInstallationWorkScreen(CustomerModel customer) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Installation Work - ${customer.name}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.phone, customer.phoneNumber ?? 'N/A'),
                    _buildInfoRow(
                      Icons.location_on,
                      customer.city ?? 'Not specified',
                    ),
                    _buildInfoRow(
                      Icons.electrical_services,
                      '${customer.kw ?? 'N/A'} kW',
                    ),
                    _buildInfoRow(
                      Icons.info_outline,
                      'Phase: ${customer.currentPhase}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Work tasks section
            const Text(
              'Installation Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _getInstallationTasks(customer.currentPhase).length,
                itemBuilder: (context, index) {
                  final task = _getInstallationTasks(
                    customer.currentPhase,
                  )[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.build, color: Colors.white, size: 20),
                      ),
                      title: Text(task),
                      subtitle: const Text('Status: Assigned'),
                      trailing: ElevatedButton(
                        onPressed: () => _startTask(task, customer),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Start'),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showWorkPhotos(customer),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Work Photos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showWorkNotes(customer),
                    icon: const Icon(Icons.note_add),
                    label: const Text('Work Notes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  void _startTask(String task, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ready to start: $task?'),
            const SizedBox(height: 16),
            const Text(
              'This will begin time tracking for this task.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showTaskStarted(task);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Task'),
          ),
        ],
      ),
    );
  }

  void _showTaskStarted(String task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started: $task'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Stop',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Stopped: $task'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showWorkPhotos(CustomerModel customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Work photos feature - Camera integration coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showWorkNotes(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Work Notes'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add work notes, observations, or issues...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
                const SnackBar(
                  content: Text('Work notes saved'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save Notes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search and filters
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search customers...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          hintStyle: const TextStyle(color: Colors.white70),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _filterCustomers();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _sortLatestFirst
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() => _sortLatestFirst = !_sortLatestFirst);
                          _filterCustomers();
                        },
                        tooltip: _sortLatestFirst
                            ? 'Sort: Latest First'
                            : 'Sort: Oldest First',
                      ),
                    ),
                  ],
                ),
              ),
              // Phase tabs
              Container(
                color: Colors.white24,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'All (${_allCustomers.length})'),
                    Tab(text: 'Application (${_applicationPhase.length})'),
                    Tab(text: 'Amount (${_amountPhase.length})'),
                    Tab(text: 'Material (${_materialPhase.length})'),
                    Tab(text: 'Installation (${_installationPhase.length})'),
                    Tab(text: 'Completed (${_completedPhase.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomersList(_allCustomers, 'All Customers'),
          _buildCustomersList(_applicationPhase, 'Application Phase'),
          _buildCustomersList(_amountPhase, 'Amount Phase'),
          _buildCustomersList(_materialPhase, 'Material Phase'),
          _buildCustomersList(_installationPhase, 'Installation Phase'),
          _buildCustomersList(_completedPhase, 'Completed Projects'),
        ],
      ),
    );
  }

  Widget _buildCustomersList(
    List<CustomerModel> customers,
    String emptyMessage,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailsScreen(customer: customer),
          ),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (customer.email?.isNotEmpty == true)
                          Text(
                            customer.email!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Phase chip
                  _buildPhaseChip(customer.currentPhase),
                ],
              ),
              const SizedBox(height: 12),

              // Key information row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.phone,
                      customer.phoneNumber ?? 'N/A',
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.electrical_services,
                      customer.kw != null ? '${customer.kw} kW' : 'N/A',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status specific information
              _buildPhaseSpecificInfo(customer),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CustomerDetailsScreen(customer: customer),
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                  ),
                  const SizedBox(width: 8),

                  // Installation work button for installation phase customers
                  if (_isInstallationPhase(customer.currentPhase))
                    ElevatedButton.icon(
                      onPressed: () => _showInstallationWorkOptions(customer),
                      icon: const Icon(Icons.build, size: 16),
                      label: const Text('Installation Work'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),

                  // Only leads can manage phases
                  if (_currentUser?.role == UserRole.lead) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showPhaseActions(customer),
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Manage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseChip(String phase) {
    Color color;
    String label;

    switch (phase) {
      case 'application':
        color = Colors.blue;
        label = 'Application';
        break;
      case 'amount':
        color = Colors.orange;
        label = 'Amount';
        break;
      case 'material_allocation':
        color = Colors.purple;
        label = 'Material Allocation';
        break;
      case 'material_delivery':
        color = Colors.purple.shade700;
        label = 'Material Delivery';
        break;
      case 'installation':
        color = Colors.indigo;
        label = 'Installation';
        break;
      case 'documentation':
        color = Colors.indigo.shade700;
        label = 'Documentation';
        break;
      case 'meter_connection':
        color = Colors.teal;
        label = 'Meter Connection';
        break;
      case 'inverter_turnon':
        color = Colors.cyan;
        label = 'Inverter Turn-on';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'service_phase':
        color = Colors.green.shade700;
        label = 'Service Phase';
        break;
      default:
        color = Colors.grey;
        label = phase.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
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

  Widget _buildPhaseSpecificInfo(CustomerModel customer) {
    switch (customer.currentPhase) {
      case 'application':
        return _buildApplicationInfo(customer);
      case 'amount':
        return _buildAmountInfo(customer);
      case 'material_allocation':
      case 'material_delivery':
        return _buildMaterialInfo(customer);
      default:
        return _buildGeneralInfo(customer);
    }
  }

  Widget _buildApplicationInfo(CustomerModel customer) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            Icons.pending_actions,
            'Status: ${customer.applicationStatus?.toUpperCase() ?? 'PENDING'}',
            _getStatusColor(customer.applicationStatus ?? 'pending'),
          ),
        ),
        if (customer.applicationApprovalDate != null)
          Expanded(
            child: _buildInfoItem(
              Icons.check_circle,
              'Approved: ${DateFormat('dd/MM/yy').format(customer.applicationApprovalDate!)}',
              Colors.green,
            ),
          ),
      ],
    );
  }

  Widget _buildAmountInfo(CustomerModel customer) {
    // Role-based information display for amount phase
    if (_canSeeAmountDetails()) {
      // Lead can see full amount details
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.currency_rupee,
                  'Total: ₹${customer.amountTotal?.toStringAsFixed(0) ?? 'N/A'}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.payment,
                  'Paid: ₹${customer.amountPaid?.toStringAsFixed(0) ?? '0'}',
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.account_balance_wallet,
                  'Payment: ${customer.amountPaymentStatus?.toUpperCase() ?? 'PENDING'}',
                  _getPaymentStatusColor(
                    customer.amountPaymentStatus ?? 'pending',
                  ),
                ),
              ),
              if (customer.amountUtrNumber?.isNotEmpty == true)
                Expanded(
                  child: _buildInfoItem(
                    Icons.receipt,
                    'UTR: ${customer.amountUtrNumber}',
                    Colors.purple,
                  ),
                ),
            ],
          ),
        ],
      );
    } else {
      // Employee can only see KW and payment status
      return Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              Icons.electrical_services,
              'KW: ${customer.kw?.toString() ?? 'N/A'}',
              Colors.orange,
            ),
          ),
          Expanded(
            child: _buildInfoItem(
              Icons.account_balance_wallet,
              'Payment: ${customer.amountPaymentStatus?.toUpperCase() ?? 'PENDING'}',
              _getPaymentStatusColor(customer.amountPaymentStatus ?? 'pending'),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildMaterialInfo(CustomerModel customer) {
    // For material phase, show KW and material allocation status
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                Icons.electrical_services,
                'KW: ${customer.kw?.toString() ?? 'N/A'}',
                Colors.orange,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                Icons.inventory,
                'Material: ${customer.currentPhase == 'material_allocation' ? 'Allocating' : 'Delivering'}',
                customer.currentPhase == 'material_allocation'
                    ? Colors.purple
                    : Colors.purple.shade700,
              ),
            ),
          ],
        ),
        if (customer.materialPlannedDate != null ||
            customer.materialAllocationDate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (customer.materialPlannedDate != null)
                Expanded(
                  child: _buildInfoItem(
                    Icons.schedule,
                    'Planned: ${DateFormat('dd/MM/yy').format(customer.materialPlannedDate!)}',
                    Colors.blue,
                  ),
                ),
              if (customer.materialAllocationDate != null)
                Expanded(
                  child: _buildInfoItem(
                    Icons.check_circle,
                    'Allocated: ${DateFormat('dd/MM/yy').format(customer.materialAllocationDate!)}',
                    Colors.green,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGeneralInfo(CustomerModel customer) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            Icons.location_on,
            customer.city ?? 'Location not specified',
            Colors.red,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            Icons.calendar_today,
            'Created: ${DateFormat('dd/MM/yy').format(customer.createdAt)}',
            Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.red;
    }
  }

  void _showPhaseActions(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Phase: ${customer.currentPhase}'),
            const SizedBox(height: 16),
            Text('Choose an action:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (customer.currentPhase == 'application' &&
              customer.applicationStatus == 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showApplicationActions(customer);
              },
              child: const Text('Manage Application'),
            ),
          if (customer.currentPhase == 'amount')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAmountActions(customer);
              },
              child: const Text('Manage Amount'),
            ),
          if ([
            'material_allocation',
            'material_delivery',
          ].contains(customer.currentPhase))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showMaterialActions(customer);
              },
              child: const Text('Manage Material'),
            ),
        ],
      ),
    );
  }

  void _showApplicationActions(CustomerModel customer) {
    // Implementation for application management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application management coming soon')),
    );
  }

  void _showAmountActions(CustomerModel customer) {
    // Implementation for amount management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Amount management coming soon')),
    );
  }

  void _showMaterialActions(CustomerModel customer) {
    // Implementation for material phase management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Material phase management coming soon')),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToWorkItemWithCustomer(
    InstallationWorkItem workItem,
    CustomerModel customer,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstallationWorkDetailScreen(
          workItem: workItem,
          customer: customer,
        ),
      ),
    );
  }

  Color _getWorkStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'notstarted':
        return Colors.grey;
      case 'inprogress':
        return Colors.orange;
      case 'awaitingcompletion':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'verified':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getWorkStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'notstarted':
        return Icons.schedule;
      case 'inprogress':
        return Icons.play_arrow;
      case 'awaitingcompletion':
        return Icons.pause;
      case 'completed':
        return Icons.check_circle;
      case 'verified':
        return Icons.verified;
      default:
        return Icons.help;
    }
  }

  String _getWorkStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'notstarted':
        return 'Not Started';
      case 'inprogress':
        return 'In Progress';
      case 'awaitingcompletion':
        return 'Awaiting Completion';
      case 'completed':
        return 'Completed';
      case 'verified':
        return 'Verified';
      default:
        return status;
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
