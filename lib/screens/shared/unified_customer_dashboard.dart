import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../services/office_service.dart';
import 'create_customer_application_screen.dart';

class UnifiedCustomerDashboard extends StatefulWidget {
  const UnifiedCustomerDashboard({super.key});

  @override
  State<UnifiedCustomerDashboard> createState() =>
      _UnifiedCustomerDashboardState();
}

class _UnifiedCustomerDashboardState extends State<UnifiedCustomerDashboard>
    with SingleTickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final OfficeService _officeService = OfficeService();

  late TabController _tabController;

  UserModel? _currentUser;
  List<CustomerModel> _allCustomers = [];
  List<CustomerModel> _applicationPhase = [];
  List<CustomerModel> _amountPhase = [];
  List<CustomerModel> _materialPhase = [];
  List<CustomerModel> _installationPhase = [];
  List<CustomerModel> _completedPhase = [];

  // Office filter for director
  List<OfficeModel> _offices = [];
  String? _selectedOfficeId;

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

      if (_currentUser?.role == UserRole.director) {
        _offices = await _officeService.getAllOffices();
        _allCustomers = await _customerService.getAllApplications();
      } else if (_currentUser?.officeId != null) {
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

    List<CustomerModel> filteredCustomers;

    // Apply office filter for directors
    if (_currentUser?.role == UserRole.director && _selectedOfficeId != null) {
      filteredCustomers = _allCustomers
          .where((c) => c.officeId == _selectedOfficeId)
          .toList();
    } else {
      filteredCustomers = _allCustomers;
    }

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
                    // Office filter for directors
                    if (_currentUser?.role == UserRole.director) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String?>(
                          value: _selectedOfficeId,
                          hint: const Text(
                            'All Offices',
                            style: TextStyle(color: Colors.white70),
                          ),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: Colors.purple.shade700,
                          underline: Container(),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'All Offices',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ..._offices.map(
                              (office) => DropdownMenuItem<String>(
                                value: office.id,
                                child: Text(
                                  office.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedOfficeId = value);
                            _filterCustomers();
                          },
                        ),
                      ),
                    ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateCustomerApplicationScreen(),
          ),
        ).then((_) => _loadData()),
        icon: const Icon(Icons.add),
        label: const Text('New Application'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
        onTap: () => _showCustomerDetails(customer),
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
                    onPressed: () => _showCustomerDetails(customer),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                  ),
                  const SizedBox(width: 8),
                  if (_canManagePhase(customer))
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

  bool _canManagePhase(CustomerModel customer) {
    // Directors and managers can manage all phases
    if (_currentUser?.role == UserRole.director ||
        _currentUser?.role == UserRole.manager) {
      return true;
    }
    return false;
  }

  void _showCustomerDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPhaseChip(customer.currentPhase),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Contact Information', [
                        'Email: ${customer.email ?? 'N/A'}',
                        'Phone: ${customer.phoneNumber ?? 'N/A'}',
                        'Address: ${customer.address ?? 'N/A'}',
                        'City: ${customer.city ?? 'N/A'}',
                      ]),
                      _buildDetailSection('Project Details', [
                        'KW Capacity: ${customer.kw ?? 'N/A'}',
                        'Electric Meter: ${customer.electricMeterServiceNumber ?? 'N/A'}',
                        'Current Phase: ${customer.currentPhase}',
                        'Created: ${DateFormat('dd/MM/yyyy HH:mm').format(customer.createdAt)}',
                      ]),
                      if (customer.currentPhase == 'application' ||
                          customer.applicationStatus == 'approved')
                        _buildDetailSection('Application Phase', [
                          'Status: ${customer.applicationStatus?.toUpperCase() ?? 'PENDING'}',
                          if (customer.applicationApprovalDate != null)
                            'Approved On: ${DateFormat('dd/MM/yyyy HH:mm').format(customer.applicationApprovalDate!)}',
                          'Estimated KW: ${customer.estimatedKw ?? 'N/A'}',
                          'Estimated Cost: ₹${customer.estimatedCost?.toStringAsFixed(0) ?? 'N/A'}',
                          'Site Survey: ${customer.siteSurveyCompleted == true ? 'Completed' : 'Pending'}',
                        ]),
                      if (customer.currentPhase == 'amount' ||
                          (customer.amountTotal != null &&
                              customer.amountTotal! > 0))
                        _buildDetailSection('Amount Phase', [
                          'Total Amount: ₹${customer.amountTotal?.toStringAsFixed(0) ?? 'N/A'}',
                          'Amount Paid: ₹${customer.amountPaid?.toStringAsFixed(0) ?? '0'}',
                          'Payment Status: ${customer.amountPaymentStatus?.toUpperCase() ?? 'PENDING'}',
                          if (customer.amountUtrNumber?.isNotEmpty == true)
                            'UTR Number: ${customer.amountUtrNumber}',
                          if (customer.amountPaidDate != null)
                            'Payment Date: ${DateFormat('dd/MM/yyyy').format(customer.amountPaidDate!)}',
                          if (customer.amountNotes?.isNotEmpty == true)
                            'Notes: ${customer.amountNotes}',
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
