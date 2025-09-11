import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/installation_model.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/installation_service.dart';
import '../../services/customer_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import 'installation_verification_screen.dart';

class InstallationAssignmentScreen extends StatefulWidget {
  const InstallationAssignmentScreen({super.key});

  @override
  State<InstallationAssignmentScreen> createState() => _InstallationAssignmentScreenState();
}

class _InstallationAssignmentScreenState extends State<InstallationAssignmentScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final CustomerService _customerService = CustomerService();
  final UserService _userService = UserService();
  
  List<InstallationWorkAssignment> _assignments = [];
  List<CustomerModel> _readyCustomers = [];
  List<UserModel> _employees = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        // Load installation assignments
        _assignments = await InstallationService.getAllInstallationAssignments(
          officeId: _currentUser!.role == UserRole.director ? null : _currentUser!.officeId,
        );
        
        // Load customers ready for installation (material delivered)
        final allCustomers = _currentUser!.role == UserRole.director
            ? await _customerService.getAllApplications()
            : await _customerService.getCustomersByOffice(_currentUser!.officeId!);
        
        _readyCustomers = allCustomers.where((customer) => 
          customer.currentPhase == 'material_allocation' && 
          customer.materialAllocationStatus == 'confirmed'
        ).toList();
        
        // Load employees for assignment
        final allUsers = await _userService.getUsersByOffice(_currentUser!.officeId!);
        _employees = allUsers.where((user) => user.role == UserRole.employee).toList();
      }
    } catch (e) {
      _showMessage('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showAssignInstallationDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => _AssignInstallationDialog(
        customer: customer,
        employees: _employees,
        currentUser: _currentUser!,
        onAssigned: _loadData,
      ),
    );
  }

  void _openVerificationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InstallationVerificationScreen(),
      ),
    ).then((_) => _loadData());
  }

  List<InstallationWorkAssignment> get _filteredAssignments {
    if (_searchQuery.isEmpty) return _assignments;
    
    return _assignments.where((assignment) {
      return assignment.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             assignment.status.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<CustomerModel> get _filteredReadyCustomers {
    if (_searchQuery.isEmpty) return _readyCustomers;
    
    return _readyCustomers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             customer.address!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installation Assignment'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Ready to Assign'),
            Tab(text: 'Active Assignments'),
            Tab(text: 'Overview'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user),
            onPressed: _openVerificationScreen,
            tooltip: 'Verify Installations',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers or assignments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReadyToAssignTab(),
                      _buildActiveAssignmentsTab(),
                      _buildOverviewTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToAssignTab() {
    return _filteredReadyCustomers.isEmpty
        ? _buildEmptyState('No customers ready for installation assignment.', Icons.assignment_add)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredReadyCustomers.length,
            itemBuilder: (context, index) {
              return _buildReadyCustomerCard(_filteredReadyCustomers[index]);
            },
          );
  }

  Widget _buildActiveAssignmentsTab() {
    return _filteredAssignments.isEmpty
        ? _buildEmptyState('No active installation assignments.', Icons.construction)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredAssignments.length,
            itemBuilder: (context, index) {
              return _buildAssignmentCard(_filteredAssignments[index]);
            },
          );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, int>>(
      future: InstallationService.getInstallationStatistics(
        officeId: _currentUser!.role == UserRole.director ? null : _currentUser!.officeId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {};
        return _buildOverviewContent(stats);
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                              customer.address ?? 'No address',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showAssignInstallationDialog(customer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Assign Team'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Materials confirmed - Ready for installation',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (customer.amountKw != null) ...[
                  Icon(Icons.electrical_services, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${customer.amountKw} kW System',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Added: ${DateFormat('dd/MM/yyyy').format(customer.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(InstallationWorkAssignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                        assignment.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.customerAddress,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(assignment.status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Installation Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${assignment.completionPercentage.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: assignment.completionPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
            
            const SizedBox(height: 16),
            
            // Team and Timeline
            Row(
              children: [
                Icon(Icons.group, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Team: ${assignment.assignedEmployeeNames.join(', ')}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Assigned: ${DateFormat('dd/MM/yyyy').format(assignment.assignedDate)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                if (assignment.scheduledDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${DateFormat('dd/MM/yyyy').format(assignment.scheduledDate!)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'assigned':
        color = Colors.blue;
        icon = Icons.assignment;
        break;
      case 'in_progress':
        color = Colors.orange;
        icon = Icons.construction;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.done_all;
        break;
      case 'verified':
        color = Colors.teal;
        icon = Icons.verified;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent(Map<String, int> stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Statistics Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total Assignments',
                stats['total']?.toString() ?? '0',
                Icons.assignment,
                Colors.blue,
              ),
              _buildStatCard(
                'In Progress',
                stats['in_progress']?.toString() ?? '0',
                Icons.construction,
                Colors.orange,
              ),
              _buildStatCard(
                'Completed',
                stats['completed']?.toString() ?? '0',
                Icons.done_all,
                Colors.green,
              ),
              _buildStatCard(
                'Verified',
                stats['verified']?.toString() ?? '0',
                Icons.verified,
                Colors.teal,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.verified_user, color: Colors.green.shade700),
                    title: const Text('Verify Completed Installations'),
                    subtitle: Text('${stats['completed'] ?? 0} installations awaiting verification'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _openVerificationScreen,
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.assignment_add, color: Colors.blue.shade700),
                    title: const Text('Assign New Installations'),
                    subtitle: Text('${_readyCustomers.length} customers ready for assignment'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _tabController.animateTo(0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Assignment Dialog Widget
class _AssignInstallationDialog extends StatefulWidget {
  final CustomerModel customer;
  final List<UserModel> employees;
  final UserModel currentUser;
  final VoidCallback onAssigned;

  const _AssignInstallationDialog({
    required this.customer,
    required this.employees,
    required this.currentUser,
    required this.onAssigned,
  });

  @override
  State<_AssignInstallationDialog> createState() => __AssignInstallationDialogState();
}

class __AssignInstallationDialogState extends State<_AssignInstallationDialog> {
  bool _isLoading = false;
  List<String> _selectedEmployees = [];
  DateTime? _scheduledDate;
  final TextEditingController _notesController = TextEditingController();

  Future<void> _assignInstallation() async {
    if (_selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one employee')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await InstallationService.createInstallationAssignment(
        customerId: widget.customer.id,
        assignedEmployeeIds: _selectedEmployees,
        assignedById: widget.currentUser.id,
        scheduledDate: _scheduledDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Installation assigned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning installation: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Installation Team'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      widget.customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.customer.address != null)
                      Text(
                        widget.customer.address!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    if (widget.customer.amountKw != null)
                      Text(
                        'System: ${widget.customer.amountKw} kW',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Employee Selection
              const Text(
                'Select Installation Team:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.employees.isEmpty
                    ? const Center(
                        child: Text('No employees available'),
                      )
                    : ListView.builder(
                        itemCount: widget.employees.length,
                        itemBuilder: (context, index) {
                          final employee = widget.employees[index];
                          final isSelected = _selectedEmployees.contains(employee.id);
                          
                          return CheckboxListTile(
                            title: Text(employee.fullName ?? 'Unknown'),
                            subtitle: Text(employee.phoneNumber ?? ''),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedEmployees.add(employee.id);
                                } else {
                                  _selectedEmployees.remove(employee.id);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        },
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Scheduled Date
              const Text(
                'Scheduled Date (Optional):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        _scheduledDate != null 
                            ? DateFormat('dd/MM/yyyy').format(_scheduledDate!)
                            : 'Select scheduled date',
                        style: TextStyle(
                          color: _scheduledDate != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      if (_scheduledDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _scheduledDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              const Text(
                'Additional Notes (Optional):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter any special instructions or notes...',
                  border: OutlineInputBorder(),
                ),
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
          onPressed: _isLoading ? null : _assignInstallation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Assign Team'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
