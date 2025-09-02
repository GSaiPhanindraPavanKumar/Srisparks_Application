import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../services/office_service.dart';
import '../shared/create_customer_application_screen.dart';
import '../shared/customer_details_screen.dart';
import '../director/material_allocation_plan.dart';

class ManagerUnifiedDashboard extends StatefulWidget {
  const ManagerUnifiedDashboard({super.key});

  @override
  State<ManagerUnifiedDashboard> createState() =>
      _ManagerUnifiedDashboardState();
}

class _ManagerUnifiedDashboardState extends State<ManagerUnifiedDashboard>
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
  List<OfficeModel> _offices = [];

  bool _isLoading = true;
  String _searchQuery = '';
  bool _sortLatestFirst = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
      _offices = await _officeService.getAllOffices();
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

    List<CustomerModel> filteredCustomers;

    // Apply search filter
    if (query.isNotEmpty) {
      filteredCustomers = _allCustomers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.email?.toLowerCase().contains(query) == true ||
            customer.phoneNumber?.contains(query) == true ||
            customer.electricMeterServiceNumber?.toLowerCase().contains(
                  query,
                ) ==
                true;
      }).toList();
    } else {
      filteredCustomers = _allCustomers;
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

    // Add survey phase for customers who have completed site survey
    List<CustomerModel> surveyPhase = filteredCustomers
        .where((c) => c.currentPhase == 'survey')
        .toList();

    // Add manager review phase
    List<CustomerModel> managerReviewPhase = filteredCustomers
        .where((c) => c.currentPhase == 'manager_review')
        .toList();

    // Add director approval phase
    List<CustomerModel> directorApprovalPhase = filteredCustomers
        .where((c) => c.currentPhase == 'director_approval')
        .toList();

    // Add approved phase
    List<CustomerModel> approvedPhase = filteredCustomers
        .where((c) => c.currentPhase == 'approved')
        .toList();

    _amountPhase = filteredCustomers
        .where((c) => c.currentPhase == 'amount')
        .toList();

    _materialPhase = filteredCustomers
        .where(
          (c) => [
            'material_allocation',
            'material_delivery',
            'material',
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

    // Combine related phases for display
    _applicationPhase.addAll(surveyPhase);
    _applicationPhase.addAll(managerReviewPhase);
    _applicationPhase.addAll(directorApprovalPhase);
    _applicationPhase.addAll(approvedPhase);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager - Customer Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
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
          _buildCustomersList(_allCustomers),
          _buildCustomersList(_applicationPhase),
          _buildCustomersList(_amountPhase),
          _buildCustomersList(_materialPhase),
          _buildCustomersList(_installationPhase),
          _buildCustomersList(_completedPhase),
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
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCustomersList(List<CustomerModel> customers) {
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
        return _buildManagerCustomerCard(customer);
      },
    );
  }

  Widget _buildManagerCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                _buildPhaseChip(customer.currentPhase),
                const SizedBox(width: 8),
                // Show approval status chips
                ..._buildApprovalStatusChips(customer),
              ],
            ),
            const SizedBox(height: 12),

            // Customer details
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

            // Phase specific information
            _buildPhaseSpecificInfo(customer),

            const SizedBox(height: 12),

            // Manager action buttons
            _buildManagerActionButtons(customer),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerActionButtons(CustomerModel customer) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => _showCustomerDetails(customer),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
              ),
            ],
          ),
        ),
        // Manager specific actions based on phase
        if (customer.currentPhase == 'survey') ...[
          // Survey phase - manager can review and recommend
          // Show recommend buttons only if manager hasn't given recommendation yet
          // and director hasn't made final decision (approved/rejected)
          if (_canManagerRecommend(customer))
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _recommendApproval(customer),
                  icon: const Icon(Icons.thumb_up, size: 16),
                  label: const Text('Recommend'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _recommendRejection(customer),
                  icon: const Icon(Icons.thumb_down, size: 16),
                  label: const Text('Not Recommend'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          // Show manager recommendation status if it exists
          if (customer.managerRecommendation != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: customer.managerRecommendation == 'approve'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: customer.managerRecommendation == 'approve'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              child: Text(
                'Manager ${customer.managerRecommendation == 'approve' ? 'Recommended' : 'Not Recommended'}',
                style: TextStyle(
                  color: customer.managerRecommendation == 'approve'
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ] else if (customer.currentPhase == 'application') ...[
          // Application phase actions
          if (customer.applicationStatus == 'pending') ...[
            Row(
              children: [
                // Show Recommend button only if manager can still recommend
                if (_canManagerRecommend(customer))
                  ElevatedButton.icon(
                    onPressed: () => _showManagerRecommendationDialog(customer),
                    icon: const Icon(Icons.recommend, size: 16),
                    label: const Text('Recommend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_canManagerRecommend(customer)) const SizedBox(width: 8),
                if (!customer.siteSurveyCompleted)
                  ElevatedButton.icon(
                    onPressed: () => _showCompleteSiteSurveyDialog(customer),
                    icon: const Icon(Icons.assignment_turned_in, size: 16),
                    label: const Text('Complete Survey'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ] else if (!customer.siteSurveyCompleted) ...[
            ElevatedButton.icon(
              onPressed: () => _showCompleteSiteSurveyDialog(customer),
              icon: const Icon(Icons.assignment_turned_in, size: 16),
              label: const Text('Complete Survey'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ] else if (customer.currentPhase == 'manager_review') ...[
          // Manager review phase - final recommendation
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _submitFinalRecommendation(customer, true),
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _submitFinalRecommendation(customer, false),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ] else if (customer.currentPhase == 'amount') ...[
          ElevatedButton.icon(
            onPressed: () => _manageAmount(customer),
            icon: const Icon(Icons.attach_money, size: 16),
            label: const Text('Manage Amount'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],

        // Material allocation phase actions
        if (customer.currentPhase == 'material_allocation' ||
            customer.currentPhase == 'material') ...[
          ElevatedButton.icon(
            onPressed: () => _openMaterialAllocationPlan(customer),
            icon: const Icon(Icons.inventory, size: 16),
            label: const Text('Allocation Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
          ),
        ],

        // Show payment management buttons for customers with pending payments in any phase
        // (except completed phase) - this allows updating pending payments even after phase progression
        if (customer.currentPhase != 'completed' &&
            customer.amountTotal != null &&
            customer.amountTotal! > 0 &&
            customer.calculatedPaymentStatus != 'completed') ...[
          // Only add payment buttons if they're not already added (to avoid duplicates in amount phase)
          if (customer.currentPhase != 'amount') ...[
            ElevatedButton.icon(
              onPressed: () => _manageAmount(customer),
              icon: const Icon(Icons.attach_money, size: 16),
              label: const Text('Manage Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ],
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

  // Build approval status chips to show manager recommendation and director decision
  List<Widget> _buildApprovalStatusChips(CustomerModel customer) {
    List<Widget> chips = [];

    // Manager recommendation chip
    if (customer.managerRecommendation != null) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: customer.managerRecommendation == 'approve'
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: customer.managerRecommendation == 'approve'
                  ? Colors.green
                  : Colors.red,
              width: 1,
            ),
          ),
          child: Text(
            'M: ${customer.managerRecommendation == 'approve' ? 'Rec' : 'Not Rec'}',
            style: TextStyle(
              color: customer.managerRecommendation == 'approve'
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      );
    }

    // Director decision chip
    if (customer.applicationStatus != 'pending') {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 4));
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: customer.applicationStatus == 'approved'
                ? Colors.blue.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: customer.applicationStatus == 'approved'
                  ? Colors.blue
                  : Colors.orange,
              width: 1,
            ),
          ),
          child: Text(
            'D: ${customer.applicationStatus == 'approved' ? 'Approved' : customer.applicationStatus.toUpperCase()}',
            style: TextStyle(
              color: customer.applicationStatus == 'approved'
                  ? Colors.blue.shade700
                  : Colors.orange.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      );
    }

    return chips;
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
        return _buildAmountPhaseDisplay(customer);
      default:
        return _buildGeneralInfo(customer);
    }
  }

  Widget _buildAmountPhaseDisplay(CustomerModel customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Keep the existing amount info for consistency
        _buildAmountInfo(customer),
        const SizedBox(height: 8),
        // Add detailed amount phase details like director
        ...(_buildAmountPhaseDetails(customer)),
      ],
    );
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

  Widget _buildApplicationInfo(CustomerModel customer) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                Icons.pending_actions,
                'Status: ${customer.applicationStatus.toUpperCase()}',
                _getStatusColor(customer.applicationStatus),
              ),
            ),
            // Removed the approval date display to avoid confusion
            // as the correct status is already shown in the chips beside the customer name
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                Icons.construction,
                'Survey: ${customer.siteSurveyCompleted == true ? 'Completed' : 'Pending'}',
                customer.siteSurveyCompleted == true
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            if (customer.managerRecommendation != null)
              Expanded(
                child: _buildInfoItem(
                  Icons.recommend,
                  'Recommended: ${customer.managerRecommendation?.toUpperCase()}',
                  customer.managerRecommendation == 'approve'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
          ],
        ),
      ],
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
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.currency_rupee,
                  'Total: ₹${totalAmount.toStringAsFixed(0)}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.payment,
                  'Paid: ₹${paidAmount.toStringAsFixed(0)}',
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
                  Icons.pending_actions,
                  'Pending: ₹${pendingAmount.toStringAsFixed(0)}',
                  Colors.orange,
                ),
              ),
              if (hasAdvancedWithPendingPayment)
                Expanded(
                  child: _buildInfoItem(
                    Icons.warning,
                    'Pending after phase',
                    Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
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

  // Manager Actions
  Future<void> _showManagerRecommendationDialog(CustomerModel customer) async {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manager Recommendation - ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provide your recommendation for this application:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
                hintText: 'Add your recommendation details...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitManagerRecommendation(
                customer,
                'reject',
                commentController.text.trim(),
              );
            },
            child: Text(
              'Recommend Rejection',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitManagerRecommendation(
                customer,
                'approve',
                commentController.text.trim(),
              );
            },
            child: const Text('Recommend Approval'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitManagerRecommendation(
    CustomerModel customer,
    String recommendation,
    String comment,
  ) async {
    try {
      await _customerService.recommendApplication(
        customer.id,
        _currentUser!.id,
        recommendation,
        comment.isEmpty ? null : comment,
      );

      _showMessage('Manager recommendation submitted successfully');
      _loadData();
    } catch (e) {
      _showMessage('Error submitting recommendation: $e');
    }
  }

  Future<void> _showCompleteSiteSurveyDialog(CustomerModel customer) async {
    DateTime? siteSurveyDate = DateTime.now();
    String roofType = 'concrete';
    String roofArea = '';
    String shadingIssues = 'minimal';
    String electricalCapacity = 'adequate';
    String customerRequirement = 'grid_tie_system';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Complete Site Survey - ${customer.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Survey Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Survey Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: siteSurveyDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => siteSurveyDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(
                          siteSurveyDate != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(siteSurveyDate!)
                              : 'Select survey date',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Roof Type
                DropdownButtonFormField<String>(
                  value: roofType,
                  decoration: const InputDecoration(
                    labelText: 'Roof Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'concrete',
                      child: Text('Concrete'),
                    ),
                    DropdownMenuItem(value: 'metal', child: Text('Metal')),
                    DropdownMenuItem(value: 'tile', child: Text('Tile')),
                    DropdownMenuItem(
                      value: 'asbestos',
                      child: Text('Asbestos'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => roofType = value!),
                ),
                const SizedBox(height: 12),

                // Roof Area
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Roof Area (sq ft) (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => roofArea = value,
                ),
                const SizedBox(height: 12),

                // Shading Issues
                DropdownButtonFormField<String>(
                  value: shadingIssues,
                  decoration: const InputDecoration(
                    labelText: 'Shading Issues',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'minimal', child: Text('Minimal')),
                    DropdownMenuItem(
                      value: 'moderate',
                      child: Text('Moderate'),
                    ),
                    DropdownMenuItem(
                      value: 'significant',
                      child: Text('Significant'),
                    ),
                    DropdownMenuItem(value: 'severe', child: Text('Severe')),
                  ],
                  onChanged: (value) => setState(() => shadingIssues = value!),
                ),
                const SizedBox(height: 12),

                // Electrical Capacity
                DropdownButtonFormField<String>(
                  value: electricalCapacity,
                  decoration: const InputDecoration(
                    labelText: 'Electrical Infrastructure',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'adequate',
                      child: Text('Adequate'),
                    ),
                    DropdownMenuItem(
                      value: 'upgrade_needed',
                      child: Text('Upgrade Needed'),
                    ),
                    DropdownMenuItem(
                      value: 'insufficient',
                      child: Text('Insufficient'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => electricalCapacity = value!),
                ),
                const SizedBox(height: 12),

                // Customer Requirements (System Type)
                DropdownButtonFormField<String>(
                  value: customerRequirement,
                  decoration: const InputDecoration(
                    labelText: 'System Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'grid_tie_system',
                      child: Text('Grid-Tie System'),
                    ),
                    DropdownMenuItem(
                      value: 'off_grid_system',
                      child: Text('Off-Grid System'),
                    ),
                    DropdownMenuItem(
                      value: 'hybrid_system',
                      child: Text('Hybrid System'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => customerRequirement = value!),
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
                await _completeSiteSurvey(
                  customer,
                  siteSurveyDate!,
                  roofType,
                  roofArea,
                  shadingIssues,
                  electricalCapacity,
                  customerRequirement,
                );
              },
              child: const Text('Complete Survey'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeSiteSurvey(
    CustomerModel customer,
    DateTime surveyDate,
    String roofType,
    String roofArea,
    String shadingIssues,
    String electricalCapacity,
    String customerRequirement,
  ) async {
    try {
      final surveyData = {
        'survey_date': surveyDate.toIso8601String(),
        'roof_type': roofType,
        'roof_area': roofArea,
        'shading_issues': shadingIssues,
        'electrical_capacity': electricalCapacity,
        'customer_requirements': customerRequirement,
      };

      await _customerService.completeSiteSurvey(
        customer.id,
        _currentUser!.id,
        surveyData,
      );

      _showMessage('Site survey completed successfully');
      _loadData();
    } catch (e) {
      _showMessage('Error completing site survey: $e');
    }
  }

  Future<void> _submitFinalRecommendation(
    CustomerModel customer,
    bool approve,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Final Approval' : 'Final Rejection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${approve ? 'Approve' : 'Reject'} ${customer.name} for director review?',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Manager Comments',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              _showMessage('Final recommendation submitted to director');
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _recommendApproval(CustomerModel customer) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recommend Approval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recommend approval for ${customer.name}?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Recommendation Comment (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                // Store comment
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showMessage('Recommendation submitted successfully');
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Recommend Approval'),
          ),
        ],
      ),
    );
  }

  Future<void> _recommendRejection(CustomerModel customer) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recommend Rejection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recommend rejection for ${customer.name}?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                // Store comment
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showMessage('Recommendation submitted successfully');
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Recommend Rejection'),
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

                if (kw == null || totalAmount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid kW and amount values'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _customerService.setAmountPhaseDetails(
                    customerId: customer.id,
                    userId: _currentUser!.id,
                    finalKw: kw,
                    totalAmount: totalAmount,
                  );

                  Navigator.pop(context);
                  _showMessage('Amount phase details set successfully');
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error setting amount: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Set Amount'),
            ),

          // Add Payment button (only if amount is set and there's pending amount)
          if (isAmountSet && customer.pendingAmount > 0)
            ElevatedButton(
              onPressed: () async {
                final paymentAmount = double.tryParse(
                  _paymentAmountController.text,
                );
                final utr = _utrController.text.trim();

                if (paymentAmount == null || paymentAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid payment amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (paymentAmount > customer.pendingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Payment amount cannot exceed pending amount',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (utr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter UTR/Transaction number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _customerService.addPayment(
                    customerId: customer.id,
                    userId: _currentUser!.id,
                    paymentAmount: paymentAmount,
                    paymentDate: DateTime.now(),
                    utrNumber: utr,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  );

                  Navigator.pop(context);
                  _showMessage('Payment added successfully');
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding payment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add Payment'),
            ),
        ],
      ),
    );
  }

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
                            'Date: ${DateFormat('dd/MM/yyyy').format(date)}',
                          ),
                          if (utr.isNotEmpty) Text('UTR: $utr'),
                          if (notes.isNotEmpty) Text('Notes: $notes'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ] else ...[
                Text(
                  'No payments recorded yet',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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

  /*
  void _showPaymentSettingDialog(CustomerModel customer) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController kwController = TextEditingController();
    String selectedSystem = 'On Grid'; // Default selection
    
    // Pre-fill controllers if values exist
    if (customer.amountTotal != null && customer.amountTotal! > 0) {
      amountController.text = customer.amountTotal.toString();
    }
    if (customer.amountKw != null && customer.amountKw! > 0) {
      kwController.text = customer.amountKw.toString();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Payment Amount'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // System Type Selection
              DropdownButtonFormField<String>(
                value: selectedSystem,
                decoration: const InputDecoration(
                  labelText: 'System Type',
                  border: OutlineInputBorder(),
                ),
                items: ['On Grid', 'Off Grid'].map((String system) {
                  return DropdownMenuItem<String>(
                    value: system,
                    child: Text(system),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSystem = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Total kW Input
              TextField(
                controller: kwController,
                decoration: const InputDecoration(
                  labelText: 'Total kW',
                  border: OutlineInputBorder(),
                  suffixText: 'kW',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Amount Input
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Note: Once set, kW and amount cannot be modified. Please verify before confirming.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
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
              final amountText = amountController.text.trim();
              final kwText = kwController.text.trim();
              
              if (amountText.isEmpty || kwText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter both kW and amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final amount = double.tryParse(amountText);
              final kw = double.tryParse(kwText);
              
              if (amount == null || amount <= 0 || kw == null || kw <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid positive numbers'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                await _customerService.setAmountPhaseDetails(
                  customerId: customer.id,
                  userId: _currentUser!.id,
                  finalKw: kw.toInt(),
                  totalAmount: amount,
                  notes: 'Amount and kW set by manager',
                );
                
                Navigator.pop(context);
                _loadData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Amount and kW set successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  void _showPaymentManagementDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Management - ${customer.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary
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
                      'Total Amount: ₹${customer.amountTotal?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total kW: ${customer.amountKw?.toStringAsFixed(2) ?? '0.00'} kW',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'System: ${customer.metadata?['systemType'] ?? 'Not specified'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Paid: ₹${customer.totalAmountPaid.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          'Pending: ₹${customer.pendingAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (customer.amountTotal ?? 0) > 0 
                          ? customer.totalAmountPaid / (customer.amountTotal ?? 1) 
                          : 0,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Add Payment Button
              if (customer.calculatedPaymentStatus != 'completed')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _addPayment(customer);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              const Text(
                'Payment History:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              
              // Payment History List
              Expanded(
                child: Builder(
                  builder: (context) {
                    final payments = customer.paymentHistory;
                    
                    if (payments.isEmpty) {
                      return const Center(
                        child: Text(
                          'No payments recorded yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        final date = DateTime.tryParse(payment['paymentDate']?.toString() ?? '') ?? DateTime.now();
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(Icons.payment, color: Colors.green),
                            ),
                            title: Text(
                              '₹${payment['amount']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${_formatDate(date)}'),
                                if (payment['utrNumber'] != null && payment['utrNumber'].toString().isNotEmpty)
                                  Text('UTR: ${payment['utrNumber']}'),
                                if (payment['note'] != null && payment['note'].toString().isNotEmpty)
                                  Text('Note: ${payment['note']}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                          // Show payment detail in new way - we'll implement this later
                        },
                            ),
                          ),
                        );
                      },
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
  }
  
  void _addPayment(CustomerModel customer) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController utrController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    
    final double pendingAmount = customer.pendingAmount;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pending Amount: ₹${pendingAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: utrController,
                decoration: const InputDecoration(
                  labelText: 'UTR Number (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Date Picker
              ListTile(
                title: const Text('Payment Date'),
                subtitle: Text(_formatDate(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                    });
                  }
                },
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
              final amountText = amountController.text.trim();
              
              if (amountText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter payment amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final amount = double.tryParse(amountText);
              
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (amount > pendingAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment amount cannot exceed pending amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                await _customerService.addPayment(
                  customerId: customer.id,
                  userId: _currentUser!.id,
                  paymentAmount: amount,
                  paymentDate: selectedDate,
                  utrNumber: utrController.text.trim().isNotEmpty 
                      ? utrController.text.trim() 
                      : 'MGR${DateTime.now().millisecondsSinceEpoch}',
                  notes: noteController.text.trim().isNotEmpty 
                      ? noteController.text.trim() 
                      : 'Payment added by manager',
                );
                
                Navigator.pop(context);
                _loadData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding payment: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add Payment'),
          ),
        ],
      ),
    );
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
  // Removed old unused payment methods
  */

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
      _loadData();
    } catch (e) {
      _showMessage('Error opening material allocation plan: $e');
    }
  }

  // Helper method to determine if manager can provide recommendation
  bool _canManagerRecommend(CustomerModel customer) {
    // Manager can recommend if:
    // 1. No manager recommendation exists yet
    // 2. Director hasn't made final decision (approved/rejected)
    // 3. Application is still in pending status
    return customer.managerRecommendation == null &&
        customer.applicationStatus == 'pending';
  }

  void _showCustomerDetails(CustomerModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customer: customer),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
