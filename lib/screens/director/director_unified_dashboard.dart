import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../models/installation_work_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../services/office_service.dart';
import '../../services/user_service.dart';
import '../../services/installation_service.dart';
import 'installation_management_dashboard.dart';
import '../shared/create_customer_application_screen.dart';
import '../shared/customer_details_screen.dart';
import 'material_allocation_plan.dart';

class DirectorUnifiedDashboard extends StatefulWidget {
  const DirectorUnifiedDashboard({super.key});

  @override
  State<DirectorUnifiedDashboard> createState() =>
      _DirectorUnifiedDashboardState();
}

class _DirectorUnifiedDashboardState extends State<DirectorUnifiedDashboard>
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
  List<CustomerModel> _documentationPhase = [];
  List<CustomerModel> _meterConnectionPhase = [];
  List<CustomerModel> _inverterTurnonPhase = [];
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
    _tabController = TabController(length: 9, vsync: this);
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
      if (_currentUser == null) return;

      // Load offices for director
      _offices = await _officeService.getAllOffices();

      await _loadCustomers();
    } catch (e) {
      _showMessage('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCustomers() async {
    try {
      if (_selectedOfficeId != null) {
        _allCustomers = await _customerService.getCustomersByOffice(
          _selectedOfficeId!,
        );
      } else {
        // Load all customers across all offices (director access)
        _allCustomers = await _customerService.getAllCustomers();
      }

      print('Debug: Loaded ${_allCustomers.length} total customers');
      _categorizeCustomers();
    } catch (e) {
      _showMessage('Error loading customers: $e');
    }
  }

  void _categorizeCustomers() {
    final filtered = _allCustomers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (customer.phoneNumber?.contains(_searchQuery) ?? false) ||
          (customer.address?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
    }).toList();

    if (_sortLatestFirst) {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    _applicationPhase = filtered
        .where((c) => c.currentPhase == 'application')
        .toList();
    _amountPhase = filtered.where((c) => c.currentPhase == 'amount').toList();
    _materialPhase = filtered
        .where((c) => c.currentPhase == 'material_allocation')
        .toList();
    _installationPhase = filtered
        .where((c) => c.currentPhase == 'installation')
        .toList();
    _documentationPhase = filtered
        .where((c) => c.currentPhase == 'documentation')
        .toList();
    _meterConnectionPhase = filtered
        .where((c) => c.currentPhase == 'meter_connection')
        .toList();
    _inverterTurnonPhase = filtered
        .where((c) => c.currentPhase == 'inverter_turnon')
        .toList();
    _completedPhase = filtered
        .where((c) => c.currentPhase == 'completed')
        .toList();

    print('Debug: Categorized customers:');
    print('  Application: ${_applicationPhase.length}');
    print('  Amount: ${_amountPhase.length}');
    print('  Material: ${_materialPhase.length}');
    print('  Installation: ${_installationPhase.length}');
    print('  Documentation: ${_documentationPhase.length}');
    print('  Meter Connection: ${_meterConnectionPhase.length}');
    print('  Inverter Turnon: ${_inverterTurnonPhase.length}');
    print('  Completed: ${_completedPhase.length}');

    // Debug: Print current phases of all customers
    for (final customer in _allCustomers) {
      print(
        '  Customer ${customer.name} is in phase: ${customer.currentPhase}',
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Director Dashboard'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(180),
          child: Column(
            children: [
              // Office Filter Dropdown
              if (_offices.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedOfficeId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Office',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: Colors.white,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Offices'),
                      ),
                      ..._offices.map(
                        (office) => DropdownMenuItem<String>(
                          value: office.id,
                          child: Text(office.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedOfficeId = value;
                      });
                      _loadCustomers();
                    },
                  ),
                ),
              const SizedBox(height: 8),
              // Search and Sort
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search customers...',
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          _categorizeCustomers();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _sortLatestFirst = !_sortLatestFirst;
                        });
                        _categorizeCustomers();
                      },
                      icon: Icon(
                        _sortLatestFirst
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                      ),
                      color: Colors.white,
                      tooltip: _sortLatestFirst
                          ? 'Latest First'
                          : 'Oldest First',
                    ),
                  ],
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'All (${_allCustomers.length})'),
                  Tab(text: 'Application (${_applicationPhase.length})'),
                  Tab(text: 'Amount (${_amountPhase.length})'),
                  Tab(text: 'Material (${_materialPhase.length})'),
                  Tab(text: 'Installation (${_installationPhase.length})'),
                  Tab(text: 'Documentation (${_documentationPhase.length})'),
                  Tab(
                    text: 'Meter Connection (${_meterConnectionPhase.length})',
                  ),
                  Tab(text: 'Inverter Turnon (${_inverterTurnonPhase.length})'),
                  Tab(text: 'Completed (${_completedPhase.length})'),
                ],
              ),
              const SizedBox(height: 8), // Add some bottom padding
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerList(_allCustomers),
                _buildCustomerList(_applicationPhase),
                _buildCustomerList(_amountPhase),
                _buildCustomerList(_materialPhase),
                _buildCustomerList(_installationPhase),
                _buildCustomerList(_documentationPhase),
                _buildCustomerList(_meterConnectionPhase),
                _buildCustomerList(_inverterTurnonPhase),
                _buildCustomerList(_completedPhase),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            onPressed: () => _loadCustomers(),
            backgroundColor: Colors.blue,
            heroTag: "refresh",
            child: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => _navigateToCreateCustomer(context),
            backgroundColor: Colors.purple,
            heroTag: "add",
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Customer',
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(List<CustomerModel> customers) {
    if (customers.isEmpty) {
      return const Center(
        child: Text(
          'No customers found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return _buildCustomerCard(customer);
        },
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getPhaseColor(customer.currentPhase),
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                customer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            // Phase indicator chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPhaseColor(customer.currentPhase),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                customer.currentPhase.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${customer.phoneNumber}'),
              ],
            ),
            const SizedBox(height: 4),
            if (customer.currentPhase == 'application')
              _buildApplicationStatusChip(customer),
            if (customer.currentPhase == 'amount') _buildAmountInfo(customer),
            // Show payment info for customers in other phases who have pending payments
            if (customer.currentPhase != 'amount' &&
                customer.currentPhase != 'application' &&
                customer.amountTotal != null &&
                customer.amountTotal! > 0)
              _buildAmountInfo(customer),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerDetails(customer),
                const SizedBox(height: 16),
                _buildActionButtons(customer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationStatusChip(CustomerModel customer) {
    final isDirectorApproved = customer.applicationStatus == 'approved';
    final isDirectorRejected = customer.applicationStatus == 'rejected';
    final hasRecommendation =
        customer.managerRecommendation?.isNotEmpty == true;

    Color chipColor;
    String chipText;

    if (isDirectorApproved) {
      chipColor = Colors.green;
      chipText = 'Director Approved';
    } else if (isDirectorRejected) {
      chipColor = Colors.red;
      chipText = 'Director Rejected';
    } else if (hasRecommendation) {
      chipColor = Colors.orange;
      chipText = 'Pending Director Decision';
    } else {
      chipColor = Colors.grey;
      chipText = 'Pending Manager Recommendation';
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Chip(
        label: Text(
          chipText,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: chipColor,
      ),
    );
  }

  Widget _buildAmountInfo(CustomerModel customer) {
    final totalAmount = customer.amountTotal ?? 0;
    final paidAmount = customer.totalAmountPaid;
    final pendingAmount = customer.pendingAmount;
    final isInAmountPhase = customer.currentPhase == 'amount';
    final hasAdvancedWithPendingPayment = !isInAmountPhase && pendingAmount > 0;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAdvancedWithPendingPayment)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Advanced with Pending Payment',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            'Total: ₹${NumberFormat('#,##,###').format(totalAmount)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            'Paid: ₹${NumberFormat('#,##,###').format(paidAmount)} | Pending: ₹${NumberFormat('#,##,###').format(pendingAmount)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (customer.paymentHistory.isNotEmpty)
            Text(
              'Payments: ${customer.paymentHistory.length}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          Chip(
            label: Text(
              customer.calculatedPaymentStatus.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            backgroundColor: _getPaymentStatusColor(
              customer.calculatedPaymentStatus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails(CustomerModel customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ..._buildPhaseSpecificDetails(customer),
      ],
    );
  }

  List<Widget> _buildPhaseSpecificDetails(CustomerModel customer) {
    switch (customer.currentPhase.toLowerCase()) {
      case 'application':
        return _buildApplicationPhaseDetails(customer);
      case 'survey':
        return _buildSurveyPhaseDetails(customer);
      case 'manager_review':
        return _buildManagerReviewPhaseDetails(customer);
      case 'director_approval':
        return _buildDirectorApprovalPhaseDetails(customer);
      case 'amount':
        return _buildAmountPhaseDetails(customer);
      case 'material':
      case 'material_allocation':
        return _buildMaterialPhaseDetails(customer);
      case 'material_delivery':
        return _buildMaterialDeliveryPhaseDetails(customer);
      case 'installation':
        return _buildInstallationPhaseDetails(customer);
      case 'documentation':
        return _buildDocumentationPhaseDetails(customer);
      case 'meter_connection':
        return _buildMeterConnectionPhaseDetails(customer);
      case 'inverter_turnon':
        return _buildInverterTurnOnPhaseDetails(customer);
      case 'completed':
      case 'service_phase':
        return _buildCompletedPhaseDetails(customer);
      default:
        return _buildDefaultDetails(customer);
    }
  }

  List<Widget> _buildApplicationPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      _buildDetailRow(
        'Applied Date',
        DateFormat('dd/MM/yyyy').format(customer.createdAt),
        icon: Icons.calendar_today,
      ),
      _buildDetailRow(
        'Application Status',
        customer.applicationStatus.toUpperCase(),
        icon: Icons.assignment,
      ),
      if (customer.kw != null)
        _buildDetailRow('Requested kW', '${customer.kw}', icon: Icons.bolt),
      if (customer.electricMeterServiceNumber?.isNotEmpty == true)
        _buildDetailRow(
          'Meter Number',
          customer.electricMeterServiceNumber!,
          icon: Icons.electrical_services,
        ),
      if (customer.applicationNotes?.isNotEmpty == true)
        _buildDetailRow(
          'Application Notes',
          customer.applicationNotes!,
          icon: Icons.note,
        ),
    ];
  }

  List<Widget> _buildSurveyPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      _buildDetailRow(
        'Survey Status',
        customer.siteSurveyCompleted ? 'Completed' : 'Pending',
        icon: customer.siteSurveyCompleted ? Icons.check_circle : Icons.pending,
      ),
      if (customer.siteSurveyDate != null)
        _buildDetailRow(
          'Survey Date',
          DateFormat('dd/MM/yyyy').format(customer.siteSurveyDate!),
          icon: Icons.calendar_today,
        ),
      _buildDetailRow(
        'Feasibility',
        customer.feasibilityStatus,
        icon: Icons.assessment,
      ),
      if (customer.estimatedKw != null)
        _buildDetailRow(
          'Estimated kW',
          '${customer.estimatedKw}',
          icon: Icons.bolt,
        ),
      if (customer.estimatedCost != null)
        _buildDetailRow(
          'Estimated Cost',
          '₹${customer.estimatedCost!.toStringAsFixed(0)}',
          icon: Icons.currency_rupee,
        ),
    ];
  }

  List<Widget> _buildManagerReviewPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.siteSurveyDate != null)
        _buildDetailRow(
          'Survey Completed',
          DateFormat('dd/MM/yyyy').format(customer.siteSurveyDate!),
          icon: Icons.check_circle,
        ),
      if (customer.estimatedKw != null)
        _buildDetailRow(
          'Estimated kW',
          '${customer.estimatedKw}',
          icon: Icons.bolt,
        ),
      if (customer.estimatedCost != null)
        _buildDetailRow(
          'Estimated Cost',
          '₹${customer.estimatedCost!.toStringAsFixed(0)}',
          icon: Icons.currency_rupee,
        ),
      _buildDetailRow(
        'Feasibility',
        customer.feasibilityStatus,
        icon: Icons.assessment,
      ),
      if (customer.managerRecommendation?.isNotEmpty == true)
        _buildDetailRow(
          'Manager Recommendation',
          customer.managerRecommendation!.toUpperCase(),
          icon: customer.managerRecommendation == 'approval'
              ? Icons.thumb_up
              : Icons.thumb_down,
        ),
    ];
  }

  List<Widget> _buildDirectorApprovalPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.managerRecommendation?.isNotEmpty == true)
        _buildDetailRow(
          'Manager Recommendation',
          customer.managerRecommendation!.toUpperCase(),
          icon: customer.managerRecommendation == 'approval'
              ? Icons.thumb_up
              : Icons.thumb_down,
        ),
      if (customer.estimatedKw != null)
        _buildDetailRow(
          'Estimated kW',
          '${customer.estimatedKw}',
          icon: Icons.bolt,
        ),
      if (customer.estimatedCost != null)
        _buildDetailRow(
          'Estimated Cost',
          '₹${customer.estimatedCost!.toStringAsFixed(0)}',
          icon: Icons.currency_rupee,
        ),
      _buildDetailRow(
        'Application Status',
        customer.applicationStatus.toUpperCase(),
        icon: Icons.verified_user,
      ),
      if (customer.applicationApprovalDate != null)
        _buildDetailRow(
          'Approval Date',
          DateFormat('dd/MM/yyyy').format(customer.applicationApprovalDate!),
          icon: Icons.calendar_today,
        ),
    ];
  }

  List<Widget> _buildAmountPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.amountTotal != null)
        _buildDetailRow(
          'Total Amount',
          '₹${customer.amountTotal!.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet,
        ),
      _buildDetailRow(
        'Amount Paid',
        '₹${customer.totalAmountPaid.toStringAsFixed(0)}',
        icon: Icons.payment,
      ),
      _buildDetailRow(
        'Pending Amount',
        '₹${customer.pendingAmount.toStringAsFixed(0)}',
        icon: Icons.pending_actions,
      ),
      _buildDetailRow(
        'Payment Status',
        customer.calculatedPaymentStatus.toUpperCase(),
        icon: Icons.payment,
      ),
      _buildDetailRow(
        'Payments Made',
        '${customer.paymentHistory.length}',
        icon: Icons.receipt,
      ),
    ];
  }

  List<Widget> _buildMaterialPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.kw != null)
        _buildDetailRow('Final kW', '${customer.kw}', icon: Icons.flash_on),
      _buildDetailRow(
        'Material Status',
        'Allocation Required',
        icon: Icons.inventory,
      ),
      _buildDetailRow(
        'Payment Status',
        customer.calculatedPaymentStatus.toUpperCase(),
        icon: Icons.payment,
      ),
      if (customer.amountTotal != null)
        _buildDetailRow(
          'Project Value',
          '₹${customer.amountTotal!.toStringAsFixed(0)}',
          icon: Icons.currency_rupee,
        ),
      _buildDetailRow('Office', customer.officeId, icon: Icons.business),
    ];
  }

  List<Widget> _buildMaterialDeliveryPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.kw != null)
        _buildDetailRow('Final kW', '${customer.kw}', icon: Icons.flash_on),
      _buildDetailRow(
        'Material Status',
        'Allocated - Delivery Pending',
        icon: Icons.local_shipping,
      ),
      _buildDetailRow(
        'Delivery Priority',
        'Standard',
        icon: Icons.priority_high,
      ),
    ];
  }

  List<Widget> _buildInstallationPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.kw != null)
        _buildDetailRow('Final kW', '${customer.kw}', icon: Icons.flash_on),
      _buildDetailRow(
        'Installation Status',
        'Ready for Installation',
        icon: Icons.construction,
      ),
      _buildDetailRow('Material Status', 'Delivered', icon: Icons.check_circle),
    ];
  }

  List<Widget> _buildDocumentationPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.kw != null)
        _buildDetailRow('Final kW', '${customer.kw}', icon: Icons.flash_on),
      _buildDetailRow(
        'Installation Status',
        'Completed',
        icon: Icons.check_circle,
      ),
      _buildDetailRow(
        'Documentation',
        'Pending Submission',
        icon: Icons.description,
      ),
    ];
  }

  List<Widget> _buildMeterConnectionPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.kw != null)
        _buildDetailRow('Final kW', '${customer.kw}', icon: Icons.flash_on),
      _buildDetailRow('Documentation', 'Submitted', icon: Icons.check_circle),
      _buildDetailRow(
        'Meter Connection',
        'Pending',
        icon: Icons.electrical_services,
      ),
    ];
  }

  List<Widget> _buildInverterTurnOnPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.kw != null)
        _buildDetailRow('Final kW', '${customer.kw}', icon: Icons.flash_on),
      _buildDetailRow('Meter Status', 'Connected', icon: Icons.check_circle),
      _buildDetailRow(
        'Inverter Status',
        'Ready for Turn On',
        icon: Icons.power,
      ),
    ];
  }

  List<Widget> _buildCompletedPhaseDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      if (customer.kw != null)
        _buildDetailRow('Final kW', '${customer.kw}', icon: Icons.flash_on),
      _buildDetailRow('Project Status', 'Completed', icon: Icons.check_circle),
      _buildDetailRow('Commissioning', 'System Active', icon: Icons.power),
      if (customer.amountTotal != null)
        _buildDetailRow(
          'Project Value',
          '₹${customer.amountTotal!.toStringAsFixed(0)}',
          icon: Icons.currency_rupee,
        ),
    ];
  }

  List<Widget> _buildDefaultDetails(CustomerModel customer) {
    return [
      _buildDetailRow(
        'Address',
        customer.address ?? 'No address',
        icon: Icons.location_on,
      ),
      _buildDetailRow(
        'Applied Date',
        DateFormat('dd/MM/yyyy').format(customer.createdAt),
        icon: Icons.calendar_today,
      ),
      _buildDetailRow(
        'Current Phase',
        customer.currentPhase.toUpperCase(),
        icon: Icons.timeline,
      ),
      if (customer.kw != null)
        _buildDetailRow('kW Capacity', '${customer.kw}', icon: Icons.flash_on),
    ];
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
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
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CustomerModel customer) {
    List<Widget> buttons = [];

    if (customer.currentPhase == 'application') {
      final hasRecommendation =
          customer.managerRecommendation?.isNotEmpty == true;
      final isApproved = customer.applicationStatus == 'approved';
      final isRejected = customer.applicationStatus == 'rejected';

      // Show recommend button only if no recommendation exists and not yet decided
      if (!hasRecommendation && !isApproved && !isRejected) {
        // For director - they can approve/reject directly
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: () => _approveApplication(customer),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _rejectApplication(customer),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ]);
      } else if (hasRecommendation && !isApproved && !isRejected) {
        // Show approve/reject if manager has recommended but director hasn't decided
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: () => _approveApplication(customer),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _rejectApplication(customer),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ]);
      }

      // Site survey completion button for approved applications
      if (isApproved && !customer.siteSurveyCompleted) {
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _showCompleteSiteSurveyDialog(customer),
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Complete Site Survey'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }

      // Proceed to amount phase button
      if (isApproved && customer.siteSurveyCompleted) {
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _proceedToAmount(customer),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Proceed to Amount Phase'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
    }

    if (customer.currentPhase == 'amount') {
      buttons.addAll([
        ElevatedButton.icon(
          onPressed: () => _manageAmount(customer),
          icon: const Icon(Icons.attach_money, size: 16),
          label: const Text('Manage Amount'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _proceedToMaterialPhase(customer),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Proceed to Next Phase'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ]);
    }

    // Show payment management buttons for customers with pending payments in any phase
    // (except completed phase) - this allows updating pending payments even after phase progression
    if (customer.currentPhase != 'completed' &&
        customer.amountTotal != null &&
        customer.amountTotal! > 0 &&
        customer.calculatedPaymentStatus != 'completed') {
      // Only add payment buttons if they're not already added (to avoid duplicates in amount phase)
      if (customer.currentPhase != 'amount') {
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: () => _manageAmount(customer),
            icon: const Icon(Icons.attach_money, size: 16),
            label: const Text('Manage Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ]);
      }
    }

    // Material allocation phase actions
    if (customer.currentPhase == 'material_allocation' ||
        customer.currentPhase == 'material') {
      buttons.addAll([
        ElevatedButton.icon(
          onPressed: () => _openMaterialAllocationPlan(customer),
          icon: const Icon(Icons.inventory, size: 16),
          label: const Text('Allocation Plan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
      ]);
    }

    // Installation phase actions
    if (customer.currentPhase == 'installation') {
      buttons.add(
        FutureBuilder<InstallationProject?>(
          key: ValueKey(
            'installation_${customer.id}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
          ), // Refresh every second
          future: InstallationService().getInstallationProject(customer.id),
          builder: (context, snapshot) {
            print(
              'FutureBuilder for ${customer.name}: state=${snapshot.connectionState}, hasData=${snapshot.hasData}, data=${snapshot.data}',
            );

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

            if (snapshot.hasError) {
              print('Error loading installation project: ${snapshot.error}');
              return ElevatedButton.icon(
                onPressed: () => _showAssignInstallationDialog(customer),
                icon: const Icon(Icons.assignment_add, size: 16),
                label: const Text('Assign Installation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
              );
            }

            final hasProject = snapshot.data != null;
            print('Customer ${customer.name} hasProject: $hasProject');

            if (!hasProject) {
              // Customer doesn't have installation project - show assign button
              return ElevatedButton.icon(
                onPressed: () => _showAssignInstallationDialog(customer),
                icon: const Icon(Icons.assignment_add, size: 16),
                label: const Text('Assign Installation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
              );
            } else {
              // Customer has installation project - show manage button
              return ElevatedButton.icon(
                onPressed: () => _openInstallationDashboard(customer),
                icon: const Icon(Icons.build, size: 16),
                label: const Text('Manage Installation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              );
            }
          },
        ),
      );
      buttons.add(const SizedBox(width: 8));
    }

    // Documentation phase actions
    if (customer.currentPhase == 'documentation') {
      buttons.addAll([
        ElevatedButton.icon(
          onPressed: () => _submitDocumentation(customer),
          icon: const Icon(Icons.description, size: 16),
          label: const Text('Submit Documentation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
      ]);
    }

    // Meter Connection phase actions
    if (customer.currentPhase == 'meter_connection') {
      buttons.addAll([
        ElevatedButton.icon(
          onPressed: () => _submitMeterConnection(customer),
          icon: const Icon(Icons.electrical_services, size: 16),
          label: const Text('Submit Meter Connection'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
      ]);
    }

    // Inverter Turnon phase actions
    if (customer.currentPhase == 'inverter_turnon') {
      buttons.addAll([
        ElevatedButton.icon(
          onPressed: () => _submitInverterTurnon(customer),
          icon: const Icon(Icons.power, size: 16),
          label: const Text('Submit Inverter Turnon'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
      ]);
    }

    // Universal View Details button for all customers
    buttons.addAll([
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: () => _navigateToCustomerDetails(customer),
        icon: const Icon(Icons.visibility, size: 16),
        label: const Text('View Details'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
    ]);

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'application':
        return Colors.blue;
      case 'amount':
        return Colors.green;
      case 'material_allocation':
        return Colors.orange;
      case 'installation':
        return Colors.purple;
      case 'documentation':
        return Colors.teal;
      case 'meter_connection':
        return Colors.indigo;
      case 'inverter_turnon':
        return Colors.deepOrange;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
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

  Future<void> _approveApplication(CustomerModel customer) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content: Text(
          'Do you want to approve the application for ${customer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _customerService.approveApplication(
                  customer.id,
                  _currentUser!.id,
                );
                _showMessage('Application approved successfully');
                _loadCustomers();
              } catch (e) {
                _showMessage('Error approving application: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectApplication(CustomerModel customer) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Text(
          'Do you want to reject the application for ${customer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _customerService.rejectApplication(
                  customer.id,
                  _currentUser!.id,
                  'Rejected by director',
                );
                _showMessage('Application rejected');
                _loadCustomers();
              } catch (e) {
                _showMessage('Error rejecting application: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageAmount(CustomerModel customer) async {
    final _kwController = TextEditingController();
    final _totalAmountController = TextEditingController();
    final _paymentAmountController = TextEditingController();
    final _utrController = TextEditingController();
    final _notesController = TextEditingController();

    // Initialize with existing values
    _kwController.text =
        customer.kw?.toString() ?? customer.estimatedKw?.toString() ?? '';
    _totalAmountController.text = customer.amountTotal?.toString() ?? '';

    // Check if amount and kW are already set (prevent editing)
    final bool isAmountSet =
        customer.amountTotal != null && customer.amountKw != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Amount - ${customer.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: ₹${NumberFormat('#,##,###').format(customer.amountTotal ?? 0)}',
                    ),
                    Text(
                      'Paid: ₹${NumberFormat('#,##,###').format(customer.totalAmountPaid)}',
                    ),
                    Text(
                      'Pending: ₹${NumberFormat('#,##,###').format(customer.pendingAmount)}',
                    ),
                    Text(
                      'Status: ${customer.calculatedPaymentStatus.toUpperCase()}',
                    ),
                    if (customer.paymentHistory.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Payments Made: ${customer.paymentHistory.length}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Show payment history if exists
              if (customer.paymentHistory.isNotEmpty) ...[
                Text(
                  'Payment History:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: customer.paymentHistory.map((payment) {
                        final amount = payment['amount']?.toDouble() ?? 0.0;
                        final date =
                            DateTime.tryParse(payment['date'] ?? '') ??
                            DateTime.now();
                        final utr = payment['utr_number'] ?? '';
                        return Card(
                          child: ListTile(
                            dense: true,
                            title: Text(
                              '₹${NumberFormat('#,##,###').format(amount)}',
                            ),
                            subtitle: Text(
                              '${DateFormat('dd/MM/yyyy').format(date)} - UTR: $utr',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Final kW - disable editing if already set
              TextFormField(
                controller: _kwController,
                enabled: !isAmountSet,
                decoration: InputDecoration(
                  labelText: 'Final kW Capacity',
                  border: OutlineInputBorder(),
                  suffixText: 'kW',
                  helperText: isAmountSet ? 'Cannot modify once set' : null,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Total Amount - disable editing if already set
              TextFormField(
                controller: _totalAmountController,
                enabled: !isAmountSet,
                decoration: InputDecoration(
                  labelText: 'Total Project Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                  helperText: isAmountSet ? 'Cannot modify once set' : null,
                ),
                keyboardType: TextInputType.number,
              ),

              // Only show payment fields if amount is set
              if (isAmountSet && customer.pendingAmount > 0) ...[
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  'Add New Payment:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Payment Amount
                TextFormField(
                  controller: _paymentAmountController,
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₹',
                    helperText:
                        'Max: ₹${NumberFormat('#,##,###').format(customer.pendingAmount)}',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // UTR Number
                TextFormField(
                  controller: _utrController,
                  decoration: const InputDecoration(
                    labelText: 'UTR/Transaction Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          // View Details button
          if (isAmountSet)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showPaymentDetails(customer);
              },
              child: const Text('View Details'),
            ),

          // Set Amount button (only if not set)
          if (!isAmountSet)
            ElevatedButton(
              onPressed: () async {
                final kw = int.tryParse(_kwController.text);
                final totalAmount = double.tryParse(
                  _totalAmountController.text,
                );

                if (kw == null || kw <= 0) {
                  _showMessage('Please enter valid kW capacity');
                  return;
                }

                if (totalAmount == null || totalAmount <= 0) {
                  _showMessage('Please enter valid total amount');
                  return;
                }

                try {
                  Navigator.pop(context);
                  await _customerService.setAmountPhaseDetails(
                    customerId: customer.id,
                    userId: _currentUser!.id,
                    finalKw: kw,
                    totalAmount: totalAmount,
                  );
                  _showMessage('Amount phase details set successfully');
                  _loadCustomers();
                } catch (e) {
                  _showMessage('Error setting amount details: $e');
                }
              },
              child: const Text('Set Amount'),
            ),

          // Add Payment button (only if amount is set and pending amount > 0)
          if (isAmountSet && customer.pendingAmount > 0)
            ElevatedButton(
              onPressed: () async {
                final paymentAmount = double.tryParse(
                  _paymentAmountController.text,
                );
                final utr = _utrController.text.trim();

                if (paymentAmount == null || paymentAmount <= 0) {
                  _showMessage('Please enter valid payment amount');
                  return;
                }

                if (utr.isEmpty) {
                  _showMessage('Please enter UTR number');
                  return;
                }

                try {
                  Navigator.pop(context);
                  await _customerService.addPayment(
                    customerId: customer.id,
                    userId: _currentUser!.id,
                    paymentAmount: paymentAmount,
                    paymentDate: DateTime.now(),
                    utrNumber: utr,
                    notes: _notesController.text.trim(),
                  );
                  _showMessage('Payment added successfully');
                  _loadCustomers();
                } catch (e) {
                  _showMessage('Error adding payment: $e');
                }
              },
              child: const Text('Add Payment'),
            ),
        ],
      ),
    );
  }

  // Navigate to customer details screen
  void _navigateToCustomerDetails(CustomerModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customer: customer),
      ),
    );
  }

  // New method to show payment details
  void _showPaymentDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Details - ${customer.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount: ₹${NumberFormat('#,##,###').format(customer.amountTotal ?? 0)}',
                      ),
                      Text(
                        'Amount Paid: ₹${NumberFormat('#,##,###').format(customer.totalAmountPaid)}',
                      ),
                      Text(
                        'Pending Amount: ₹${NumberFormat('#,##,###').format(customer.pendingAmount)}',
                      ),
                      Text(
                        'Status: ${customer.calculatedPaymentStatus.toUpperCase()}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Payment History
              if (customer.paymentHistory.isNotEmpty) ...[
                Text(
                  'Payment History (${customer.paymentHistory.length} payments)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...customer.paymentHistory.map((payment) {
                  final amount = payment['amount']?.toDouble() ?? 0.0;
                  final date =
                      DateTime.tryParse(payment['date'] ?? '') ??
                      DateTime.now();
                  final utr = payment['utr_number'] ?? '';
                  final notes = payment['notes'] ?? '';

                  return Card(
                    child: ListTile(
                      title: Text(
                        '₹${NumberFormat('#,##,###').format(amount)}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                          ),
                          Text('UTR: $utr'),
                          if (notes.isNotEmpty) Text('Notes: $notes'),
                        ],
                      ),
                      isThreeLine: notes.isNotEmpty,
                    ),
                  );
                }).toList(),
              ] else
                Text('No payments recorded yet'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (customer.pendingAmount > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _manageAmount(customer);
              },
              child: const Text('Add Payment'),
            ),
        ],
      ),
    );
  }

  Future<void> _proceedToAmount(CustomerModel customer) async {
    try {
      await _customerService.moveToNextPhase(customer.id, 'amount');
      _showMessage('Customer moved to amount phase');
      _loadCustomers();
    } catch (e) {
      _showMessage('Error moving to amount phase: $e');
    }
  }

  Future<void> _proceedToMaterialPhase(CustomerModel customer) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Proceed to Material Phase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${customer.name}'),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ₹${NumberFormat('#,##,###').format(customer.amountTotal ?? 0)}',
            ),
            Text(
              'Amount Paid: ₹${NumberFormat('#,##,###').format(customer.totalAmountPaid)}',
            ),
            Text(
              'Pending Amount: ₹${NumberFormat('#,##,###').format(customer.pendingAmount)}',
            ),
            const SizedBox(height: 16),
            if (customer.pendingAmount > 0)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment is not complete. You can proceed and collect remaining payment later.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (customer.pendingAmount == 0)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment is complete. Ready to proceed to material allocation.',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Do you want to proceed to Material Allocation phase?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _customerService.moveToNextPhase(
          customer.id,
          'material_allocation',
        );
        _showMessage('Customer moved to material allocation phase');
        _loadCustomers();
      } catch (e) {
        _showMessage('Error moving to material phase: $e');
      }
    }
  }

  Future<void> _submitDocumentation(CustomerModel customer) async {
    DateTime? submissionDate = DateTime.now();
    String? selectedEmployeeId;
    List<UserModel> officeEmployees = [];

    // Load employees for the current office
    try {
      if (_selectedOfficeId != null) {
        officeEmployees = await UserService().getUsersByOffice(
          _selectedOfficeId!,
        );
      } else {
        // If no office filter, load employees from customer's office
        officeEmployees = await UserService().getUsersByOffice(
          customer.officeId,
        );
      }

      // Filter to show only active employees
      officeEmployees = officeEmployees.where((user) => user.isActive).toList();
    } catch (e) {
      _showMessage('Error loading employees: $e');
      return;
    }

    if (officeEmployees.isEmpty) {
      _showMessage('No employees found for this office');
      return;
    }

    // Show dialog with date picker and employee dropdown
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Submit Documentation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${customer.name}'),
                const SizedBox(height: 16),

                // Date picker
                Text(
                  'Submission Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: submissionDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 30)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        submissionDate = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 8),
                        Text(
                          submissionDate != null
                              ? DateFormat('dd/MM/yyyy').format(submissionDate!)
                              : 'Select Date',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Employee dropdown
                Text(
                  'Submitted By:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedEmployeeId,
                  decoration: InputDecoration(
                    hintText: 'Select Employee',
                    border: OutlineInputBorder(),
                  ),
                  items: officeEmployees.map((employee) {
                    return DropdownMenuItem<String>(
                      value: employee.id,
                      child: Text('${employee.name} (${employee.role})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedEmployeeId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an employee';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This will:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('• Record the submission date as selected'),
                      Text('• Record the selected employee as submitter'),
                      Text('• Move the customer to meter connection phase'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (submissionDate != null && selectedEmployeeId != null) {
                  Navigator.pop(context, {
                    'submissionDate': submissionDate,
                    'selectedEmployeeId': selectedEmployeeId,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select both date and employee'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Documentation'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        await _customerService.updateCustomer(customer.id, {
          'documentation_submission_date':
              (result['submissionDate'] as DateTime).toIso8601String(),
          'document_submitted_by': result['selectedEmployeeId'],
          'documentation_updated_by': _currentUser?.id,
          'documentation_updated_timestamp': DateTime.now().toIso8601String(),
          'current_phase': 'meter_connection',
        });
        _showMessage('Documentation submitted successfully!');
        _loadCustomers();
      } catch (e) {
        _showMessage('Error submitting documentation: $e');
      }
    }
  }

  Future<void> _submitMeterConnection(CustomerModel customer) async {
    DateTime? meterDate = DateTime.now();

    // Show dialog with date picker only (no employee dropdown needed)
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Submit Meter Connection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${customer.name}'),
                const SizedBox(height: 16),

                // Date picker
                Text(
                  'Date of Meter Connection:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: meterDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 30)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        meterDate = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 8),
                        Text(
                          meterDate != null
                              ? DateFormat('dd/MM/yyyy').format(meterDate!)
                              : 'Select Date',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    border: Border.all(color: Colors.indigo.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This will:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('• Record the meter connection date as selected'),
                      Text('• Move the customer to inverter turnon phase'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (meterDate != null) {
                  Navigator.pop(context, {'meterDate': meterDate});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select the meter connection date'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Meter Connection'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        await _customerService.updateCustomer(customer.id, {
          'date_of_meter': (result['meterDate'] as DateTime).toIso8601String(),
          'meter_updated_by': _currentUser?.id,
          'meter_updated_time': DateTime.now().toIso8601String(),
          'current_phase': 'inverter_turnon',
        });
        _showMessage('Meter connection submitted successfully!');
        _loadCustomers();
      } catch (e) {
        _showMessage('Error submitting meter connection: $e');
      }
    }
  }

  Future<void> _submitInverterTurnon(CustomerModel customer) async {
    DateTime? inverterDate = DateTime.now();

    // Show dialog with date picker only (similar to meter connection)
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Submit Inverter Turnon'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${customer.name}'),
                const SizedBox(height: 16),

                // Date picker
                Text(
                  'Date of Inverter Turnon:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: inverterDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 30)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        inverterDate = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 8),
                        Text(
                          inverterDate != null
                              ? DateFormat('dd/MM/yyyy').format(inverterDate!)
                              : 'Select Date',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    border: Border.all(color: Colors.deepOrange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This will:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('• Record the inverter turnon date as selected'),
                      Text('• Move the customer to completed phase'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (inverterDate != null) {
                  Navigator.pop(context, {'inverterDate': inverterDate});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select the inverter turnon date'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Inverter Turnon'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        await _customerService.updateCustomer(customer.id, {
          'date_of_inverter': (result['inverterDate'] as DateTime)
              .toIso8601String(),
          'inverter_updated_by': _currentUser?.id,
          'inverter_updated_time': DateTime.now().toIso8601String(),
          'current_phase': 'completed',
        });
        _showMessage('Inverter turnon submitted successfully!');
        _loadCustomers();
      } catch (e) {
        _showMessage('Error submitting inverter turnon: $e');
      }
    }
  }

  Future<void> _showCompleteSiteSurveyDialog(CustomerModel customer) async {
    DateTime? siteSurveyDate = DateTime.now();
    String roofType = 'concrete';
    String roofArea = '';
    String shadingIssues = 'none';
    String electricalConnection = 'good';
    String accessibilityNotes = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Site Survey - ${customer.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Survey Date
              ListTile(
                title: const Text('Survey Date'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(siteSurveyDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: siteSurveyDate!,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    siteSurveyDate = date;
                  }
                },
              ),

              // Roof Type
              DropdownButtonFormField<String>(
                value: roofType,
                decoration: const InputDecoration(labelText: 'Roof Type'),
                items: ['concrete', 'tin', 'tile', 'mixed'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => roofType = value!,
              ),

              // Roof Area
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Available Roof Area (sq ft)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => roofArea = value,
              ),

              // Shading Issues
              DropdownButtonFormField<String>(
                value: shadingIssues,
                decoration: const InputDecoration(labelText: 'Shading Issues'),
                items: ['none', 'minimal', 'moderate', 'severe'].map((issue) {
                  return DropdownMenuItem(
                    value: issue,
                    child: Text(issue.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => shadingIssues = value!,
              ),

              // Electrical Connection
              DropdownButtonFormField<String>(
                value: electricalConnection,
                decoration: const InputDecoration(
                  labelText: 'Electrical Connection',
                ),
                items: ['good', 'needs_upgrade', 'poor'].map((connection) {
                  return DropdownMenuItem(
                    value: connection,
                    child: Text(connection.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => electricalConnection = value!,
              ),

              // Accessibility Notes
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Accessibility Notes',
                ),
                maxLines: 2,
                onChanged: (value) => accessibilityNotes = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _customerService
                    .completeSiteSurvey(customer.id, _currentUser!.id, {
                      'survey_date': siteSurveyDate!.toIso8601String(),
                      'roof_type': roofType,
                      'roof_area': roofArea.isNotEmpty ? roofArea : null,
                      'shading_issues': shadingIssues,
                      'electrical_connection': electricalConnection,
                      'accessibility_notes': accessibilityNotes.isNotEmpty
                          ? accessibilityNotes
                          : null,
                    });
                _showMessage('Site survey completed successfully');
                _loadCustomers();
              } catch (e) {
                _showMessage('Error completing site survey: $e');
              }
            },
            child: const Text('Complete Survey'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateCustomer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCustomerApplicationScreen(),
      ),
    ).then((_) => _loadCustomers());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openMaterialAllocationPlan(CustomerModel customer) async {
    try {
      // Find the office for this customer
      OfficeModel? customerOffice;
      for (final office in _offices) {
        if (office.id == customer.officeId) {
          customerOffice = office;
          break;
        }
      }

      if (customerOffice == null) {
        _showMessage('Office information not found for this customer');
        return;
      }

      // Navigate to material allocation plan
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MaterialAllocationPlan(
            customer: customer,
            office: customerOffice!,
          ),
        ),
      );

      // Refresh data after returning from allocation plan
      _loadCustomers();
    } catch (e) {
      _showMessage('Error opening material allocation plan: $e');
    }
  }

  // Installation assignment methods
  void _showAssignInstallationDialog(CustomerModel customer) async {
    try {
      // Get employees from the same office as the customer
      final userService = UserService();
      final allOfficeUsers = await userService.getUsersByOffice(
        customer.officeId,
      );
      final employees = allOfficeUsers
          .where((user) => user.role == UserRole.employee)
          .toList();

      if (employees.isEmpty) {
        _showMessage('No employees found in customer\'s office for assignment');
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => InstallationAssignmentDialog(
          customer: customer,
          availableEmployees: employees,
          currentUser: _currentUser!,
          onAssigned: () {
            _loadCustomers(); // Refresh the customer list
          },
        ),
      );
    } catch (e) {
      _showMessage('Error loading employees: $e');
    }
  }

  void _openInstallationDashboard(CustomerModel customer) async {
    try {
      // Get the installation project
      final project = await InstallationService().getInstallationProject(
        customer.id,
      );

      if (project != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InstallationManagementDashboard(
              customer: customer,
              project: project,
              currentUser: _currentUser!,
            ),
          ),
        ).then((_) {
          // Refresh data after returning from installation dashboard
          _loadCustomers();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No installation project found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading installation project: $e')),
      );
    }
  }
}

// Installation Assignment Dialog Widget
class InstallationAssignmentDialog extends StatefulWidget {
  final CustomerModel customer;
  final List<UserModel> availableEmployees;
  final UserModel currentUser;
  final VoidCallback onAssigned;

  const InstallationAssignmentDialog({
    super.key,
    required this.customer,
    required this.availableEmployees,
    required this.currentUser,
    required this.onAssigned,
  });

  @override
  State<InstallationAssignmentDialog> createState() =>
      _InstallationAssignmentDialogState();
}

class _InstallationAssignmentDialogState
    extends State<InstallationAssignmentDialog> {
  final Set<String> _selectedEmployeeIds = <String>{};
  final TextEditingController _notesController = TextEditingController();
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  final Set<InstallationWorkType> _selectedWorkTypes = <InstallationWorkType>{};

  @override
  void initState() {
    super.initState();
    // Select all work types by default
    _selectedWorkTypes.addAll(InstallationWorkType.values);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.assignment_add, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assign Installation\n${widget.customer.name}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: ${widget.customer.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (widget.customer.address != null)
                      Text('Address: ${widget.customer.address}'),
                    if (widget.customer.phoneNumber != null)
                      Text('Phone: ${widget.customer.phoneNumber}'),
                    if (widget.customer.kw != null)
                      Text('System Size: ${widget.customer.kw} kW'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Work Types Selection
              const Text(
                'Installation Work Types:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: InstallationWorkType.values.map((workType) {
                    final isSelected = _selectedWorkTypes.contains(workType);
                    return CheckboxListTile(
                      title: Text(workType.displayName),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedWorkTypes.add(workType);
                          } else {
                            _selectedWorkTypes.remove(workType);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Scheduled Date
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Start Date:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _selectDate,
                    child: Text(
                      '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Employee Selection
              const Text(
                'Assign to Employees (from same office):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.availableEmployees.isEmpty
                    ? const Center(
                        child: Text(
                          'No employees available in this office',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.availableEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = widget.availableEmployees[index];
                          final isSelected = _selectedEmployeeIds.contains(
                            employee.id,
                          );

                          return CheckboxListTile(
                            title: Text(employee.fullName ?? 'Unknown'),
                            subtitle: Text(employee.phoneNumber ?? ''),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedEmployeeIds.add(employee.id);
                                } else {
                                  _selectedEmployeeIds.remove(employee.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add any special instructions...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _isLoading ||
                  _selectedEmployeeIds.isEmpty ||
                  _selectedWorkTypes.isEmpty
              ? null
              : _assignInstallation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create Installation Project'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _assignInstallation() async {
    if (_selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one employee')),
      );
      return;
    }

    if (_selectedWorkTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one work type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create installation project with work types
      final project = await InstallationService().createInstallationProject(
        customerId: widget.customer.id,
        customerName: widget.customer.name,
        customerAddress: widget.customer.address ?? '',
        siteLatitude: widget.customer.latitude ?? 0.0,
        siteLongitude: widget.customer.longitude ?? 0.0,
        workTypes: _selectedWorkTypes.toList(),
        scheduledStartDate: _scheduledDate,
      );

      // Assign employees to the project
      await InstallationService().assignEmployeesToProject(
        projectId: project.projectId,
        employeeIds: _selectedEmployeeIds.toList(),
        assignedById: widget.currentUser.id,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Installation assigned to ${_selectedEmployeeIds.length} employee(s) with ${_selectedWorkTypes.length} work types',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating installation project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Installation Dashboard Screen
class InstallationDashboardScreen extends StatefulWidget {
  final CustomerModel customer;
  final UserModel currentUser;

  const InstallationDashboardScreen({
    super.key,
    required this.customer,
    required this.currentUser,
  });

  @override
  State<InstallationDashboardScreen> createState() =>
      _InstallationDashboardScreenState();
}

class _InstallationDashboardScreenState
    extends State<InstallationDashboardScreen> {
  InstallationProject? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    try {
      _project = await InstallationService().getInstallationProject(
        widget.customer.id,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading installation project: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Installation: ${widget.customer.name}'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Name: ${widget.customer.name}'),
                          if (widget.customer.address != null)
                            Text('Address: ${widget.customer.address}'),
                          if (widget.customer.phoneNumber != null)
                            Text('Phone: ${widget.customer.phoneNumber}'),
                          if (widget.customer.kw != null)
                            Text('System Size: ${widget.customer.kw} kW'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Work Items List
                  Text(
                    'Installation Work Items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _project!.workItems.length,
                      itemBuilder: (context, index) {
                        final workItem = _project!.workItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _getWorkTypeIcon(workItem.workType),
                              color: _getStatusColor(workItem.status),
                            ),
                            title: Text(workItem.workType.displayName),
                            subtitle: Text(
                              'Status: ${workItem.status.displayName}',
                            ),
                            trailing: Chip(
                              label: Text(
                                workItem.status.displayName,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: _getStatusColor(
                                workItem.status,
                              ).withOpacity(0.2),
                            ),
                            onTap: () {
                              // TODO: Open work item detail screen
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
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
}
