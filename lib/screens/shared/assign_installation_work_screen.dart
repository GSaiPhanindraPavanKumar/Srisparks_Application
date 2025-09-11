import 'package:flutter/material.dart';
import '../../models/installation_work_model.dart';
import '../../models/user_model.dart';
import '../../services/installation_service.dart';
import '../../services/user_service.dart';

class AssignInstallationWorkScreen extends StatefulWidget {
  final InstallationProject project;
  final UserModel currentUser;

  const AssignInstallationWorkScreen({
    super.key,
    required this.project,
    required this.currentUser,
  });

  @override
  State<AssignInstallationWorkScreen> createState() => _AssignInstallationWorkScreenState();
}

class _AssignInstallationWorkScreenState extends State<AssignInstallationWorkScreen> {
  final InstallationService _installationService = InstallationService();
  final UserService _userService = UserService();

  List<UserModel> _availableEmployees = [];
  Map<String, WorkAssignment> _assignments = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Get available employees (workers and leads)
      final allUsers = await _userService.getUsersByOffice(
        widget.currentUser.officeId!,
      );
      
      // Filter users to only include employees and leads
      _availableEmployees = allUsers.where((user) => 
        user.role == UserRole.employee || user.role == UserRole.lead
      ).toList();

      // Initialize assignments for each work type
      for (var workItem in widget.project.workItems) {
        _assignments[workItem.id] = WorkAssignment(
          workItem: workItem,
          leadEmployeeId: workItem.leadEmployeeId.isNotEmpty ? workItem.leadEmployeeId : null,
          teamMemberIds: List.from(workItem.teamMemberIds),
        );
      }
    } catch (e) {
      _showMessage('Error loading employees: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Installation Work'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveAssignments,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAssignmentBody(),
    );
  }

  Widget _buildAssignmentBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.project.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.project.customerAddress,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.project.workItems.length} work types to assign',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Available employees summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Employees (${_availableEmployees.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _availableEmployees.map((employee) {
                      final isLead = employee.role == UserRole.lead;
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: isLead ? Colors.orange : Colors.blue,
                          child: Text(
                            employee.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        label: Text(
                          employee.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: isLead ? Colors.orange[50] : Colors.blue[50],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Work assignments
          Text(
            'Work Assignments',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...widget.project.workItems.map((workItem) => _buildWorkAssignmentCard(workItem)),
        ],
      ),
    );
  }

  Widget _buildWorkAssignmentCard(InstallationWorkItem workItem) {
    final assignment = _assignments[workItem.id]!;
    final leadEmployee = assignment.leadEmployeeId != null
        ? _availableEmployees.firstWhere((e) => e.id == assignment.leadEmployeeId)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Work type header
            Row(
              children: [
                Icon(
                  _getWorkTypeIcon(workItem.workType),
                  color: Colors.indigo,
                ),
                const SizedBox(width: 8),
                Text(
                  workItem.workType.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (workItem.status != WorkStatus.notStarted)
                  Chip(
                    label: Text(
                      workItem.status.displayName,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: _getStatusColor(workItem.status).withOpacity(0.1),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Lead assignment
            Text(
              'Team Lead',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: assignment.leadEmployeeId,
                  hint: const Text('Select Team Lead'),
                  isExpanded: true,
                  items: _availableEmployees
                      .where((employee) => employee.role == UserRole.lead || employee.role == UserRole.employee)
                      .map((employee) {
                    return DropdownMenuItem<String>(
                      value: employee.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: employee.role == UserRole.lead ? Colors.orange : Colors.blue,
                            child: Text(
                              employee.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(employee.name)),
                          if (employee.role == UserRole.lead)
                            const Icon(Icons.star, size: 16, color: Colors.orange),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: workItem.status == WorkStatus.notStarted
                      ? (value) {
                          setState(() {
                            assignment.leadEmployeeId = value;
                            // Remove from team members if selected as lead
                            if (value != null) {
                              assignment.teamMemberIds.remove(value);
                            }
                          });
                        }
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Team members
            Text(
              'Team Members',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),

            // Selected team members
            if (assignment.teamMemberIds.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: assignment.teamMemberIds.map((memberId) {
                  final member = _availableEmployees.firstWhere((e) => e.id == memberId);
                  return Chip(
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue,
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    label: Text(member.name),
                    deleteIcon: workItem.status == WorkStatus.notStarted 
                        ? const Icon(Icons.close, size: 16) 
                        : null,
                    onDeleted: workItem.status == WorkStatus.notStarted
                        ? () {
                            setState(() {
                              assignment.teamMemberIds.remove(memberId);
                            });
                          }
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Add team member button
            if (workItem.status == WorkStatus.notStarted)
              OutlinedButton.icon(
                onPressed: () => _showAddTeamMemberDialog(assignment),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Team Member'),
              ),

            const SizedBox(height: 16),

            // Assignment summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignment Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (leadEmployee != null) ...[
                    Text('Lead: ${leadEmployee.name}'),
                  ] else ...[
                    Text('Lead: Not assigned', style: TextStyle(color: Colors.red[600])),
                  ],
                  Text('Team Size: ${assignment.teamMemberIds.length + (leadEmployee != null ? 1 : 0)}'),
                  if (workItem.status != WorkStatus.notStarted)
                    Text(
                      'Status: ${workItem.status.displayName}',
                      style: TextStyle(
                        color: _getStatusColor(workItem.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTeamMemberDialog(WorkAssignment assignment) {
    final availableMembers = _availableEmployees
        .where((employee) => 
            employee.id != assignment.leadEmployeeId && 
            !assignment.teamMemberIds.contains(employee.id))
        .toList();

    if (availableMembers.isEmpty) {
      _showMessage('No more employees available to assign');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team Member'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableMembers.length,
            itemBuilder: (context, index) {
              final employee = availableMembers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: employee.role == UserRole.lead ? Colors.orange : Colors.blue,
                  child: Text(
                    employee.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(employee.name),
                subtitle: Text(employee.role.displayName),
                trailing: employee.role == UserRole.lead
                    ? const Icon(Icons.star, color: Colors.orange)
                    : null,
                onTap: () {
                  setState(() {
                    assignment.teamMemberIds.add(employee.id);
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAssignments() async {
    setState(() => _isSaving = true);
    
    try {
      // Validate assignments
      for (var assignment in _assignments.values) {
        if (assignment.leadEmployeeId == null) {
          throw Exception('Please assign a team lead for ${assignment.workItem.workType.displayName}');
        }
      }

      // Save each assignment
      for (var assignment in _assignments.values) {
        if (assignment.workItem.status == WorkStatus.notStarted) {
          final leadEmployee = _availableEmployees.firstWhere((e) => e.id == assignment.leadEmployeeId);
          final teamMembers = _availableEmployees.where((e) => assignment.teamMemberIds.contains(e.id)).toList();

          await _installationService.assignEmployeesToWork(
            workItemId: assignment.workItem.id,
            leadEmployeeId: assignment.leadEmployeeId!,
            leadEmployeeName: leadEmployee.name,
            teamMemberIds: assignment.teamMemberIds,
            teamMemberNames: teamMembers.map((e) => e.name).toList(),
            assignedBy: widget.currentUser.id,
          );
        }
      }

      _showMessage('Work assignments saved successfully');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Error saving assignments: $e');
    } finally {
      setState(() => _isSaving = false);
    }
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
        return Icons.power;
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
      case WorkStatus.completed:
        return Colors.blue;
      case WorkStatus.verified:
        return Colors.green;
      case WorkStatus.acknowledged:
        return Colors.teal;
      case WorkStatus.approved:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class WorkAssignment {
  final InstallationWorkItem workItem;
  String? leadEmployeeId;
  List<String> teamMemberIds;

  WorkAssignment({
    required this.workItem,
    this.leadEmployeeId,
    List<String>? teamMemberIds,
  }) : teamMemberIds = teamMemberIds ?? [];
}
