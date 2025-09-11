import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/installation_model.dart';
import '../../models/user_model.dart';
import '../../services/installation_service.dart';
import '../../services/auth_service.dart';
import '../shared/installation_task_detail_screen.dart';

class EmployeeInstallationScreen extends StatefulWidget {
  const EmployeeInstallationScreen({super.key});

  @override
  State<EmployeeInstallationScreen> createState() =>
      _EmployeeInstallationScreenState();
}

class _EmployeeInstallationScreenState
    extends State<EmployeeInstallationScreen> {
  final AuthService _authService = AuthService();

  List<InstallationWorkAssignment> _assignments = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        _assignments =
            await InstallationService.getEmployeeInstallationAssignments(
              _currentUser!.id,
            );
      }
    } catch (e) {
      _showMessage('Error loading installation assignments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  List<InstallationWorkAssignment> get _filteredAssignments {
    if (_searchQuery.isEmpty) return _assignments;

    return _assignments.where((assignment) {
      return assignment.customerName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          assignment.customerAddress.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          assignment.status.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openTaskDetail(InstallationWorkAssignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstallationTaskDetailScreen(
          assignment: assignment,
          currentUser: _currentUser!,
        ),
      ),
    ).then((_) => _loadData()); // Refresh when returning
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'verified':
        return Colors.teal;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.assignment;
      case 'in_progress':
        return Icons.construction;
      case 'completed':
        return Icons.done_all;
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Installation Tasks'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // Search and Stats Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search assignments...',
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
                const SizedBox(height: 16),

                // Quick Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'Total',
                      _assignments.length.toString(),
                      Icons.assignment,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Active',
                      _assignments
                          .where(
                            (a) =>
                                ['assigned', 'in_progress'].contains(a.status),
                          )
                          .length
                          .toString(),
                      Icons.construction,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Completed',
                      _assignments
                          .where(
                            (a) => ['completed', 'verified'].contains(a.status),
                          )
                          .length
                          .toString(),
                      Icons.done,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Assignments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssignments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredAssignments.length,
                    itemBuilder: (context, index) {
                      return _buildAssignmentCard(_filteredAssignments[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Installation Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no installation assignments at this time.',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(InstallationWorkAssignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTaskDetail(assignment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
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
                                assignment.customerAddress,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        assignment.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(assignment.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(assignment.status),
                          size: 16,
                          color: _getStatusColor(assignment.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          assignment.statusDisplayName,
                          style: TextStyle(
                            color: _getStatusColor(assignment.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(assignment.status),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sub-tasks Overview
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: InstallationSubTask.values.map((subTask) {
                  final status =
                      assignment.subTasksStatus[subTask] ??
                      InstallationTaskStatus.pending;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getSubTaskStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getSubTaskStatusColor(status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      InstallationWorkAssignment.getSubTaskDisplayName(subTask),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getSubTaskStatusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Bottom Info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned: ${DateFormat('dd/MM/yyyy').format(assignment.assignedDate)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'By: ${assignment.assignedByName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubTaskStatusColor(InstallationTaskStatus status) {
    switch (status) {
      case InstallationTaskStatus.pending:
        return Colors.grey;
      case InstallationTaskStatus.assigned:
        return Colors.blue;
      case InstallationTaskStatus.inProgress:
        return Colors.orange;
      case InstallationTaskStatus.completed:
        return Colors.green;
      case InstallationTaskStatus.verified:
        return Colors.teal;
      case InstallationTaskStatus.rejected:
        return Colors.red;
    }
  }
}
