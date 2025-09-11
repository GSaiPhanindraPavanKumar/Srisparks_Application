import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import 'lead_sidebar.dart';
import '../shared/customer_details_screen.dart';
import '../../config/app_router.dart';

class LeadUnifiedDashboard extends StatefulWidget {
  const LeadUnifiedDashboard({super.key});

  @override
  State<LeadUnifiedDashboard> createState() => _LeadUnifiedDashboardState();
}

class _LeadUnifiedDashboardState extends State<LeadUnifiedDashboard>
    with SingleTickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();

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
      drawer: LeadSidebar(
        currentUser: _currentUser,
        onLogout: () => Navigator.pushReplacementNamed(context, AppRoutes.auth),
      ),
      appBar: AppBar(
        title: const Text('Lead - Customer Management'),
        backgroundColor: Colors.teal,
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
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createCustomerApplication);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Application'),
        backgroundColor: Colors.teal,
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
        return _buildLeadCustomerCard(customer);
      },
    );
  }

  Widget _buildLeadCustomerCard(CustomerModel customer) {
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
                      const SizedBox(height: 4),
                      Text(
                        'Feasibility: ${customer.feasibilityStatus}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPhaseChip(customer.currentPhase),
              ],
            ),
            const SizedBox(height: 12),

            // Customer details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.phone, customer.phoneNumber ?? 'N/A'),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.location_city,
                        customer.city ?? 'N/A',
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.electrical_services,
                        '${customer.kw ?? 'N/A'} KW',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        DateFormat('dd/MM/yyyy').format(customer.createdAt),
                      ),
                      const SizedBox(height: 4),
                      if (customer.siteSurveyCompleted == true)
                        _buildInfoRow(
                          Icons.check_circle,
                          'Survey Done',
                          color: Colors.green,
                        )
                      else
                        _buildInfoRow(
                          Icons.pending,
                          'Survey Pending',
                          color: Colors.orange,
                        ),
                      const SizedBox(height: 4),
                      if (customer.amountTotal != null)
                        _buildInfoRow(
                          Icons.currency_rupee,
                          '₹${customer.amountTotal!.toStringAsFixed(0)}',
                        ),
                      if (customer.currentPhase == 'amount' && customer.calculatedPaymentStatus != 'pending')
                        _buildInfoRow(
                          Icons.payment,
                          '${customer.calculatedPaymentStatus.toUpperCase()}',
                          color: customer.calculatedPaymentStatus == 'completed' ? Colors.green : Colors.orange,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons (Lead specific - no recommendation options)
            _buildLeadActionButtons(customer),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseChip(String phase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getPhaseColor(phase).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getPhaseColor(phase)),
      ),
      child: Text(
        _getPhaseDisplayName(phase),
        style: TextStyle(
          color: _getPhaseColor(phase),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildLeadActionButtons(CustomerModel customer) {
    return Row(
      children: [
        // View Details button (always available)
        TextButton.icon(
          onPressed: () => _viewCustomerDetails(customer),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View Details'),
        ),
        const Spacer(),

        // Lead specific actions based on phase (no recommendation options)
        if (customer.currentPhase == 'application' &&
            customer.applicationStatus == 'pending' &&
            customer.siteSurveyCompleted != true) ...[
          ElevatedButton.icon(
            onPressed: () => _conductSiteSurvey(customer),
            icon: const Icon(Icons.location_searching, size: 16),
            label: const Text('Site Survey'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ] else if (customer.currentPhase == 'amount' &&
            customer.amountPaymentStatus != 'paid') ...[
          ElevatedButton.icon(
            onPressed: () => _viewAmountDetails(customer),
            icon: const Icon(Icons.currency_rupee, size: 16),
            label: const Text('Amount Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ] else if ([
          'material',
          'material_allocation',
          'material_delivery',
        ].contains(customer.currentPhase)) ...[
          ElevatedButton.icon(
            onPressed: () => _viewMaterialStatus(customer),
            icon: const Icon(Icons.inventory, size: 16),
            label: const Text('Material Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
          ),
        ] else if ([
          'installation',
          'documentation',
          'meter_connection',
          'inverter_turnon',
        ].contains(customer.currentPhase)) ...[
          ElevatedButton.icon(
            onPressed: () => _viewInstallationStatus(customer),
            icon: const Icon(Icons.build, size: 16),
            label: const Text('Installation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  void _viewCustomerDetails(CustomerModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customer: customer),
      ),
    );
  }

  void _conductSiteSurvey(CustomerModel customer) {
    DateTime? siteSurveyDate = DateTime.now();

    // Survey details fields
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
                  'Complete the site survey for this application:',
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
                      setState(() {
                        siteSurveyDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
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

                const Text(
                  'Survey Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

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

                // Customer Requirements
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
                  roofArea.trim(),
                  shadingIssues,
                  electricalCapacity,
                  customerRequirement,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
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
      _loadData(); // Reload data to refresh the UI
    } catch (e) {
      _showMessage('Error completing site survey: $e');
    }
  }

  void _viewAmountDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Amount Details - ${customer.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Basic Amount Information
              _buildAmountDetailCard(
                'Project Information',
                [
                  _buildDetailRow('Customer Name', customer.name),
                  _buildDetailRow('Final Capacity', customer.amountKw != null 
                      ? '${customer.amountKw} kW' : 'Not set'),
                  _buildDetailRow('Total Project Amount', customer.amountTotal != null 
                      ? '₹${customer.amountTotal!.toStringAsFixed(0)}' : 'Not set'),
                ],
              ),
              const SizedBox(height: 16),
              
              // Payment Status Summary
              if (customer.amountTotal != null && customer.amountTotal! > 0) ...[
                _buildAmountDetailCard(
                  'Payment Status',
                  [
                    _buildDetailRow('Total Amount', '₹${customer.amountTotal!.toStringAsFixed(0)}'),
                    _buildDetailRow('Amount Paid', '₹${customer.totalAmountPaid.toStringAsFixed(0)}'),
                    _buildDetailRow('Pending Amount', '₹${customer.pendingAmount.toStringAsFixed(0)}'),
                    _buildDetailRow('Payment Status', customer.calculatedPaymentStatus.toUpperCase(),
                        valueColor: customer.calculatedPaymentStatus == 'completed' ? Colors.green : 
                                   customer.calculatedPaymentStatus == 'partial' ? Colors.orange : Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Payment History
              if (customer.paymentHistory.isNotEmpty) ...[
                _buildAmountDetailCard(
                  'Payment History (${customer.paymentHistory.length} payments)',
                  customer.paymentHistory.map((payment) => 
                    _buildPaymentHistoryItem(payment)
                  ).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Additional Information
              if (customer.amountNotes != null || customer.amountClearedDate != null) ...[
                _buildAmountDetailCard(
                  'Additional Information',
                  [
                    if (customer.amountClearedDate != null)
                      _buildDetailRow('Phase Cleared On', 
                          DateFormat('dd/MM/yyyy HH:mm').format(customer.amountClearedDate!)),
                    if (customer.amountNotes != null)
                      _buildDetailRow('Notes', customer.amountNotes!),
                  ],
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

  void _viewMaterialStatus(CustomerModel customer) {
    _showMessage('Material status view - to be implemented');
  }

  void _viewInstallationStatus(CustomerModel customer) {
    _showMessage('Installation status view - to be implemented');
  }

  // Helper methods for amount details UI
  Widget _buildAmountDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem(Map<String, dynamic> payment) {
    final amount = payment['amount']?.toDouble() ?? 0.0;
    final date = payment['date'] != null ? DateTime.parse(payment['date']) : null;
    final utr = payment['utr'] ?? '';
    final notes = payment['notes'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (date != null)
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          if (utr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'UTR: $utr',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: $notes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'application':
        return Colors.blue;
      case 'survey':
        return Colors.orange;
      case 'manager_review':
        return Colors.purple;
      case 'director_approval':
        return Colors.indigo;
      case 'approved':
        return Colors.green;
      case 'amount':
        return Colors.teal;
      case 'material':
      case 'material_allocation':
      case 'material_delivery':
        return Colors.brown;
      case 'installation':
      case 'documentation':
      case 'meter_connection':
      case 'inverter_turnon':
        return Colors.deepOrange;
      case 'completed':
      case 'service_phase':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPhaseDisplayName(String phase) {
    switch (phase.toLowerCase()) {
      case 'application':
        return 'Application';
      case 'survey':
        return 'Site Survey';
      case 'manager_review':
        return 'Manager Review';
      case 'director_approval':
        return 'Director Approval';
      case 'approved':
        return 'Approved';
      case 'amount':
        return 'Amount Phase';
      case 'material':
      case 'material_allocation':
        return 'Material';
      case 'material_delivery':
        return 'Material Delivery';
      case 'installation':
        return 'Installation';
      case 'documentation':
        return 'Documentation';
      case 'meter_connection':
        return 'Meter Connection';
      case 'inverter_turnon':
        return 'Inverter Turn On';
      case 'completed':
        return 'Completed';
      case 'service_phase':
        return 'Service Phase';
      default:
        return phase.toUpperCase();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
