import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../services/office_service.dart';
import 'create_customer_application_screen.dart';

class CustomerApplicationsScreen extends StatefulWidget {
  const CustomerApplicationsScreen({super.key});

  @override
  State<CustomerApplicationsScreen> createState() =>
      _CustomerApplicationsScreenState();
}

class _CustomerApplicationsScreenState extends State<CustomerApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final OfficeService _officeService = OfficeService();

  late TabController _tabController;

  UserModel? _currentUser;
  List<CustomerModel> _allApplications = [];
  List<CustomerModel> _pendingApplications = [];
  List<CustomerModel> _approvedApplications = [];
  List<CustomerModel> _rejectedApplications = [];

  // Office filter for director
  List<OfficeModel> _offices = [];
  String? _selectedOfficeId; // null means "All Offices"

  bool _isLoading = true;
  String _searchQuery = '';
  bool _sortLatestFirst = true; // true for latest first, false for oldest first

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

      if (_currentUser != null) {
        // Load offices if user is director
        if (_currentUser!.role == UserRole.director) {
          _offices = await _officeService.getAllOffices();

          // Load applications based on office filter
          if (_selectedOfficeId != null) {
            // Load applications for specific office
            _allApplications = await _customerService
                .getApplicationPhaseCustomers(_selectedOfficeId!);
          } else {
            // Load all applications across all offices
            _allApplications = await _customerService.getAllApplications();
          }
        } else if (_currentUser!.officeId != null) {
          // Managers and employees see applications from their office
          _allApplications = await _customerService
              .getApplicationPhaseCustomers(_currentUser!.officeId!);
        } else {
          // User without office assignment - show empty list and error
          _allApplications = [];
          _showMessage(
            'Error: User is not assigned to any office. Please contact administrator.',
          );
          return;
        }

        _filterApplications();
      }
    } catch (e) {
      _showMessage('Error loading applications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterApplications() {
    final query = _searchQuery.toLowerCase();

    List<CustomerModel> filteredApplications;

    if (query.isEmpty) {
      // If search is empty, show all applications
      filteredApplications = _allApplications;
    } else {
      // Filter based on search query
      filteredApplications = _allApplications.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.email?.toLowerCase().contains(query) == true ||
            customer.phoneNumber?.contains(query) == true ||
            customer.electricMeterServiceNumber?.toLowerCase().contains(
                  query,
                ) ==
                true;
      }).toList();
    }

    // Sort applications by application date based on user preference
    if (_sortLatestFirst) {
      // Latest first (descending order)
      filteredApplications.sort(
        (a, b) => b.applicationDate.compareTo(a.applicationDate),
      );
    } else {
      // Oldest first (ascending order)
      filteredApplications.sort(
        (a, b) => a.applicationDate.compareTo(b.applicationDate),
      );
    }

    _pendingApplications = filteredApplications
        .where((c) => c.applicationStatus == 'pending')
        .toList();
    _approvedApplications = filteredApplications
        .where((c) => c.applicationStatus == 'approved')
        .toList();
    _rejectedApplications = filteredApplications
        .where((c) => c.applicationStatus == 'rejected')
        .toList();

    setState(() {});
  }

  void _toggleSortOrder() {
    setState(() {
      _sortLatestFirst = !_sortLatestFirst;
    });
    _filterApplications();
  }

  void _onOfficeFilterChanged(String? officeId) {
    setState(() {
      _selectedOfficeId = officeId;
    });
    _loadData(); // Reload data for the selected office
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildOfficeFilter() {
    // Only show office filter for directors
    if (_currentUser?.role != UserRole.director || _offices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String?>(
        value: _selectedOfficeId,
        decoration: InputDecoration(
          labelText: 'Filter by Office',
          prefixIcon: const Icon(Icons.business),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Offices'),
          ),
          ..._offices.map(
            (office) => DropdownMenuItem<String?>(
              value: office.id,
              child: Text('${office.name} - ${office.city ?? 'No City'}'),
            ),
          ),
        ],
        onChanged: _onOfficeFilterChanged,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, phone, email, or service number...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterApplications();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _sortLatestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                _sortLatestFirst ? 'Latest First' : 'Oldest First',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _toggleSortOrder,
                icon: Icon(
                  _sortLatestFirst ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
                label: Text(
                  'Sort ${_sortLatestFirst ? 'Oldest' : 'Latest'} First',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(List<CustomerModel> applications) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No applications found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final customer = applications[index];
        return _buildApplicationCard(customer);
      },
    );
  }

  Widget _buildApplicationCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showApplicationDetails(customer),
        borderRadius: BorderRadius.circular(8),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (customer.email != null)
                          Text(
                            customer.email!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        if (customer.phoneNumber != null)
                          Text(
                            customer.phoneNumber!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(customer),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.solar_power, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(customer.projectSummary),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customer.fullAddress,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Applied: ${DateFormat('MMM dd, yyyy').format(customer.applicationDate)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  if (customer.siteSurveyCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Survey Done',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (!customer.siteSurveyCompleted &&
                      customer.siteSurveyTechnicianId == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Survey Pending',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (!customer.siteSurveyCompleted &&
                      customer.siteSurveyTechnicianId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Survey Ongoing',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildStatusChip(CustomerModel customer) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (customer.applicationStatus) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.pending;
        break;
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            customer.applicationStatusDisplayName,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicationDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${customer.name} - Application Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', customer.name),
              _buildDetailRow('Email', customer.email ?? 'Not provided'),
              _buildDetailRow('Phone', customer.phoneNumber ?? 'Not provided'),
              _buildDetailRow('Address', customer.fullAddress),
              _buildDetailRow('Project', customer.projectSummary),
              _buildDetailRow('Status', customer.applicationStatusDisplayName),
              _buildDetailRow(
                'Feasibility',
                customer.feasibilityStatusDisplayName,
              ),
              _buildDetailRow(
                'Application Date',
                DateFormat(
                  'MMM dd, yyyy hh:mm a',
                ).format(customer.applicationDate),
              ),
              if (customer.siteSurveyCompleted &&
                  customer.siteSurveyDate != null)
                _buildDetailRow(
                  'Survey Date',
                  DateFormat('MMM dd, yyyy').format(customer.siteSurveyDate!),
                ),
              if (customer.applicationApprovalDate != null)
                _buildDetailRow(
                  'Approval Date',
                  DateFormat(
                    'MMM dd, yyyy hh:mm a',
                  ).format(customer.applicationApprovalDate!),
                ),
              _buildDetailRow(
                'Service Number',
                customer.electricMeterServiceNumber ?? 'Not provided',
              ),
              if (customer.applicationNotes != null)
                _buildDetailRow('Notes', customer.applicationNotes!),
            ],
          ),
        ),
        actions: [
          if ((_currentUser?.role == UserRole.director ||
                  _currentUser?.role == UserRole.manager) &&
              customer.isApplicationPending)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showApprovalDialog(customer);
              },
              child: Text(
                _currentUser?.role == UserRole.director
                    ? 'Review Application'
                    : 'Recommend',
              ),
            ),
          // Complete Site Survey button for pending surveys
          if (!customer.siteSurveyCompleted &&
              customer.siteSurveyTechnicianId == null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCompleteSiteSurveyDialog(customer);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Complete Site Survey'),
            ),
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

  void _showApprovalDialog(CustomerModel customer) async {
    // Check if site survey is pending (not completed and no technician assigned)
    if (!customer.siteSurveyCompleted &&
        customer.siteSurveyTechnicianId == null) {
      _showMessage(
        'Cannot approve or reject application: Site survey is pending. Survey must be completed before approval/rejection.',
      );
      return;
    }

    // Check if current user is director or manager
    if (_currentUser!.role == UserRole.director) {
      _showDirectorApprovalDialog(customer);
    } else if (_currentUser!.role == UserRole.manager) {
      // Check if there's already a manager recommendation
      if (customer.managerRecommendation != null) {
        _showMessage(
          'Manager recommendation already provided for this application',
        );
        return;
      }
      _showManagerRecommendationDialog(customer);
    } else {
      _showMessage('You do not have permission to review applications');
    }
  }

  void _showDirectorApprovalDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Director Approval - ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to approve or reject this application?'),
            if (customer.managerRecommendation != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: customer.managerRecommendation == 'approve'
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: customer.managerRecommendation == 'approve'
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          customer.managerRecommendation == 'approve'
                              ? Icons.thumb_up
                              : Icons.thumb_down,
                          color: customer.managerRecommendation == 'approve'
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Manager ${customer.managerRecommendation == 'approve' ? 'Recommends Approval' : 'Recommends Rejection'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: customer.managerRecommendation == 'approve'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (customer.managerRecommendationComment != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Comment: ${customer.managerRecommendationComment}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (customer.managerRecommendationDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(customer.managerRecommendationDate!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateApplicationStatus(customer, 'rejected');
            },
            child: Text('Reject', style: TextStyle(color: Colors.red.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateApplicationStatus(customer, 'approved');
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showManagerRecommendationDialog(CustomerModel customer) {
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
              'As a manager, you can provide a recommendation for the director to review:',
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

  Future<void> _updateApplicationStatus(
    CustomerModel customer,
    String status,
  ) async {
    try {
      // Use the appropriate service method for approval/rejection
      if (status == 'approved') {
        await _customerService.approveApplication(
          customer.id,
          _currentUser!.id,
        );
      } else {
        await _customerService.rejectApplication(
          customer.id,
          _currentUser!.id,
          null,
        );
      }

      _showMessage(
        'Application ${status == 'approved' ? 'approved' : 'rejected'} successfully',
      );
      _loadData();
    } catch (e) {
      _showMessage('Error updating application: $e');
    }
  }

  void _showCompleteSiteSurveyDialog(CustomerModel customer) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Applications'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          tabs: [
            Tab(
              text: 'All (${_allApplications.length})',
              icon: const Icon(Icons.list),
            ),
            Tab(
              text: 'Pending (${_pendingApplications.length})',
              icon: const Icon(Icons.pending),
            ),
            Tab(
              text: 'Approved (${_approvedApplications.length})',
              icon: const Icon(Icons.check_circle),
            ),
            Tab(
              text: 'Rejected (${_rejectedApplications.length})',
              icon: const Icon(Icons.cancel),
            ),
          ],
          isScrollable: true,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _sortLatestFirst ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: _sortLatestFirst ? 'Latest First' : 'Oldest First',
            onPressed: _toggleSortOrder,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _buildOfficeFilter(),
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationsList(_allApplications),
                _buildApplicationsList(_pendingApplications),
                _buildApplicationsList(_approvedApplications),
                _buildApplicationsList(_rejectedApplications),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 8),
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateCustomerApplicationScreen(),
              ),
            );
            if (result == true) {
              _loadData();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'New Application',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
