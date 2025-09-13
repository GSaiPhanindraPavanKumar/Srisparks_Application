import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../models/installation_work_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../services/office_service.dart';
import '../../services/installation_service.dart';
import '../../services/user_service.dart';
import 'lead_sidebar.dart';
import '../shared/customer_details_screen.dart';
import '../director/material_allocation_plan.dart';
import '../director/installation_management_dashboard.dart';
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
  final OfficeService _officeService = OfficeService();

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
                        'Feasibility: ${_getFeasibilityDisplayName(customer.feasibilityStatus)}',
                        style: TextStyle(
                          color: _getFeasibilityColor(
                            customer.feasibilityStatus,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                      if (customer.materialPlannedDate != null) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.schedule,
                          'Planned: ${DateFormat('dd/MM/yy').format(customer.materialPlannedDate!)}',
                          color: Colors.blue,
                        ),
                      ],
                      if (customer.materialAllocationDate != null) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.check_circle,
                          'Allocated: ${DateFormat('dd/MM/yy').format(customer.materialAllocationDate!)}',
                          color: Colors.green,
                        ),
                      ],
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
          if (customer.currentPhase == 'installation')
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
                  print(
                    'Error loading installation project: ${snapshot.error}',
                  );
                  return ElevatedButton.icon(
                    onPressed: () => _showAssignInstallationDialog(customer),
                    icon: const Icon(Icons.assignment_add, size: 16),
                    label: const Text('Assign Installation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
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
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  );
                } else {
                  // Customer has installation project - show view and manage buttons
                  return Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openInstallationDashboard(customer),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Installation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openInstallationDashboard(customer),
                        icon: const Icon(Icons.build, size: 16),
                        label: const Text('Manage Team'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  );
                }
              },
            )
          else
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
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${customer.name} - Amount Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                      _buildAmountDetailSection('Project Information', [
                        'Customer: ${customer.name}',
                        'KW Capacity: ${customer.kw ?? 'N/A'}',
                        'Email: ${customer.email ?? 'N/A'}',
                        'Phone: ${customer.phoneNumber ?? 'N/A'}',
                      ]),
                      _buildAmountDetailSection('Amount Details', [
                        'Total Amount: ₹${customer.amountTotal?.toStringAsFixed(0) ?? 'N/A'}',
                        'Amount Paid: ₹${customer.amountPaid?.toStringAsFixed(0) ?? '0'}',
                        'Remaining: ₹${customer.amountTotal != null && customer.amountPaid != null ? (customer.amountTotal! - customer.amountPaid!).toStringAsFixed(0) : 'N/A'}',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountDetailSection(String title, List<String> items) {
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
              color: Colors.teal,
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

  void _markPaymentReceived(CustomerModel customer) {
    _showMessage('Payment marking functionality - to be implemented');
  }

  void _moveToMaterialPhase(CustomerModel customer) {
    _showMessage('Moving to material phase - to be implemented');
  }

  void _viewMaterialStatus(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${customer.name} - Material Status',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                      _buildAmountDetailSection('Project Information', [
                        'Customer: ${customer.name}',
                        'KW Capacity: ${customer.kw ?? 'N/A'}',
                        'Current Phase: ${customer.currentPhase.replaceAll('_', ' ').toUpperCase()}',
                        'Email: ${customer.email ?? 'N/A'}',
                        'Phone: ${customer.phoneNumber ?? 'N/A'}',
                      ]),
                      _buildAmountDetailSection('Material Phase Details', [
                        'Material Status: ${_getMaterialPhaseLabel(customer.currentPhase)}',
                        'KW Requirement: ${customer.kw ?? 'N/A'}',
                        if (customer.amountTotal != null)
                          'Project Value: ₹${customer.amountTotal!.toStringAsFixed(0)}',
                        'Payment Status: ${customer.amountPaymentStatus?.toUpperCase() ?? 'PENDING'}',
                      ]),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _manageMaterialPhase(customer);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Manage Material'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMaterialPhaseLabel(String phase) {
    switch (phase) {
      case 'material_allocation':
        return 'Material Allocation in Progress';
      case 'material_delivery':
        return 'Material Delivery in Progress';
      case 'material':
        return 'Material Phase';
      default:
        return phase.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _manageMaterialPhase(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Material Phase - ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Phase: ${_getMaterialPhaseLabel(customer.currentPhase)}',
            ),
            const SizedBox(height: 16),
            Text('KW Capacity: ${customer.kw ?? 'N/A'}'),
            if (customer.amountTotal != null)
              Text(
                'Project Value: ₹${customer.amountTotal!.toStringAsFixed(0)}',
              ),
            const SizedBox(height: 16),
            const Text('Available Actions:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (customer.currentPhase == 'material_allocation')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markMaterialAllocated(customer);
              },
              child: const Text('Plan Material Allocation'),
            ),
          if (customer.currentPhase == 'material_delivery')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markMaterialDelivered(customer);
              },
              child: const Text('Mark Delivered'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _moveToInstallationPhase(customer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Move to Installation'),
          ),
        ],
      ),
    );
  }

  void _markMaterialAllocated(CustomerModel customer) async {
    try {
      // Get the customer's office
      final office = await _officeService.getOfficeById(customer.officeId);
      if (office == null) {
        if (mounted) {
          _showMessage('Unable to find customer office');
        }
        return;
      }

      // Navigate to material allocation screen
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MaterialAllocationPlan(customer: customer, office: office),
          ),
        );

        // Refresh data if allocation was saved
        if (result == true) {
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error opening material allocation: $e');
      }
    }
  }

  void _markMaterialDelivered(CustomerModel customer) {
    _showMessage('Material delivery marking - to be implemented');
  }

  void _moveToInstallationPhase(CustomerModel customer) {
    _showMessage('Moving to installation phase - to be implemented');
  }

  void _viewInstallationStatus(CustomerModel customer) {
    _showMessage('Installation status view - to be implemented');
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

  String _getFeasibilityDisplayName(String feasibilityStatus) {
    switch (feasibilityStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'feasible':
        return 'Feasible';
      case 'not_feasible':
        return 'Not Feasible';
      case 'requires_review':
        return 'Requires Review';
      default:
        return feasibilityStatus.toUpperCase();
    }
  }

  Color _getFeasibilityColor(String feasibilityStatus) {
    switch (feasibilityStatus.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'feasible':
        return Colors.green;
      case 'not_feasible':
        return Colors.red;
      case 'requires_review':
        return Colors.purple;
      default:
        return Colors.grey;
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
            _loadData(); // Refresh the customer list
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
          _loadData();
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

// Installation Assignment Dialog - identical to director/manager versions
class InstallationAssignmentDialog extends StatefulWidget {
  final CustomerModel customer;
  final List<UserModel> availableEmployees;
  final UserModel currentUser;
  final VoidCallback onAssigned;

  const InstallationAssignmentDialog({
    Key? key,
    required this.customer,
    required this.availableEmployees,
    required this.currentUser,
    required this.onAssigned,
  }) : super(key: key);

  @override
  _InstallationAssignmentDialogState createState() =>
      _InstallationAssignmentDialogState();
}

class _InstallationAssignmentDialogState
    extends State<InstallationAssignmentDialog> {
  final Map<InstallationWorkType, bool> _selectedWorkTypes = {
    for (var type in InstallationWorkType.values) type: false,
  };

  final List<String> _selectedEmployeeIds = [];
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.assignment_add, color: Colors.deepOrange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Assign Installation Project',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Info Card
                    _buildCustomerInfoCard(),
                    const SizedBox(height: 20),

                    // Work Types Selection
                    _buildWorkTypesSection(),
                    const SizedBox(height: 20),

                    // Employee Assignment
                    _buildEmployeeAssignmentSection(),
                    const SizedBox(height: 20),

                    // Scheduled Date
                    _buildScheduledDateSection(),
                    const SizedBox(height: 20),

                    // Notes
                    _buildNotesSection(),
                  ],
                ),
              ),
            ),

            // Action Buttons
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Name: ${widget.customer.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Address: ${widget.customer.address ?? 'Not provided'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'System Size: ${widget.customer.kw ?? 'TBD'} kW',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Work Types',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: InstallationWorkType.values.map((workType) {
                return CheckboxListTile(
                  title: Text(workType.displayName),
                  subtitle: Text(_getWorkTypeDescription(workType)),
                  value: _selectedWorkTypes[workType],
                  onChanged: (bool? value) {
                    setState(() {
                      _selectedWorkTypes[workType] = value ?? false;
                    });
                  },
                  activeColor: Colors.deepOrange,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Employees',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: widget.availableEmployees.map((employee) {
                final isSelected = _selectedEmployeeIds.contains(employee.id);
                return CheckboxListTile(
                  title: Text(employee.name),
                  subtitle: Text(
                    employee.email.isNotEmpty ? employee.email : 'No email',
                  ),
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
                  activeColor: Colors.deepOrange,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scheduled Start Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.calendar_today, color: Colors.deepOrange),
            title: Text(DateFormat('dd/MM/yyyy').format(_scheduledDate)),
            trailing: Icon(Icons.edit, color: Colors.grey[600]),
            onTap: _selectDate,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText:
                    'Enter any special instructions or notes for the installation team...',
                border: InputBorder.none,
              ),
              maxLines: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final hasSelectedWorkTypes = _selectedWorkTypes.values.any(
      (selected) => selected,
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: (_isLoading || !hasSelectedWorkTypes)
                ? null
                : _assignInstallation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Assign Installation'),
          ),
        ),
      ],
    );
  }

  String _getWorkTypeDescription(InstallationWorkType workType) {
    switch (workType) {
      case InstallationWorkType.structureWork:
        return 'Foundation and mounting structure';
      case InstallationWorkType.panels:
        return 'Solar panel installation';
      case InstallationWorkType.inverterWiring:
        return 'Inverter and electrical wiring';
      case InstallationWorkType.earthing:
        return 'Earthing and grounding system';
      case InstallationWorkType.lightningArrestor:
        return 'Lightning protection system';
    }
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
    setState(() => _isLoading = true);

    try {
      final selectedWorkTypes = _selectedWorkTypes.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (selectedWorkTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one work type')),
        );
        return;
      }

      final installationService = InstallationService();

      // Create installation project with work types
      final project = await installationService.createInstallationProject(
        customerId: widget.customer.id,
        customerName: widget.customer.name,
        customerAddress: widget.customer.address ?? '',
        siteLatitude: widget.customer.latitude ?? 0.0,
        siteLongitude: widget.customer.longitude ?? 0.0,
        workTypes: selectedWorkTypes,
        scheduledStartDate: _scheduledDate,
      );

      // Assign employees to the project if any are selected
      if (_selectedEmployeeIds.isNotEmpty) {
        await installationService.assignEmployeesToProject(
          projectId: project.projectId,
          employeeIds: _selectedEmployeeIds,
          assignedById: widget.currentUser.id,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedEmployeeIds.isEmpty
                  ? 'Installation project created with ${selectedWorkTypes.length} work types'
                  : 'Installation assigned to ${_selectedEmployeeIds.length} employee(s) with ${selectedWorkTypes.length} work types',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning installation: $e'),
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
