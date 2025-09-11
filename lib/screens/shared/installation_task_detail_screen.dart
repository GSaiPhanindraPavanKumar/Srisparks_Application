import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/installation_model.dart';
import '../../models/user_model.dart';
import '../../services/installation_service.dart';

class InstallationTaskDetailScreen extends StatefulWidget {
  final InstallationWorkAssignment assignment;
  final UserModel currentUser;

  const InstallationTaskDetailScreen({
    super.key,
    required this.assignment,
    required this.currentUser,
  });

  @override
  State<InstallationTaskDetailScreen> createState() => _InstallationTaskDetailScreenState();
}

class _InstallationTaskDetailScreenState extends State<InstallationTaskDetailScreen> {
  late InstallationWorkAssignment _assignment;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _refreshAssignment() async {
    try {
      final updated = await InstallationService.getInstallationAssignment(_assignment.id);
      setState(() {
        _assignment = updated;
      });
    } catch (e) {
      _showMessage('Error refreshing assignment: $e');
    }
  }

  void _showStartTaskDialog(InstallationSubTask subTask) {
    showDialog(
      context: context,
      builder: (context) => _StartTaskDialog(
        subTask: subTask,
        assignment: _assignment,
        currentUser: widget.currentUser,
        onStarted: _refreshAssignment,
      ),
    );
  }

  void _showCompleteTaskDialog(InstallationSubTask subTask) {
    showDialog(
      context: context,
      builder: (context) => _CompleteTaskDialog(
        subTask: subTask,
        assignment: _assignment,
        currentUser: widget.currentUser,
        onCompleted: _refreshAssignment,
      ),
    );
  }

  bool _canStartTask(InstallationSubTask subTask) {
    final status = _assignment.subTasksStatus[subTask] ?? InstallationTaskStatus.pending;
    return status == InstallationTaskStatus.pending || status == InstallationTaskStatus.assigned;
  }

  bool _canCompleteTask(InstallationSubTask subTask) {
    final status = _assignment.subTasksStatus[subTask] ?? InstallationTaskStatus.pending;
    return status == InstallationTaskStatus.inProgress;
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

  IconData _getSubTaskStatusIcon(InstallationTaskStatus status) {
    switch (status) {
      case InstallationTaskStatus.pending:
        return Icons.schedule;
      case InstallationTaskStatus.assigned:
        return Icons.assignment;
      case InstallationTaskStatus.inProgress:
        return Icons.construction;
      case InstallationTaskStatus.completed:
        return Icons.done;
      case InstallationTaskStatus.verified:
        return Icons.verified;
      case InstallationTaskStatus.rejected:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_assignment.customerName),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAssignment,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info Card
            _buildCustomerInfoCard(),
            const SizedBox(height: 16),
            
            // Progress Overview Card
            _buildProgressCard(),
            const SizedBox(height: 16),
            
            // Sub-tasks List
            _buildSubTasksList(),
            const SizedBox(height: 16),
            
            // Assignment Details Card
            _buildAssignmentDetailsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Customer Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_assignment.customerAddress),
                ),
              ],
            ),
            if (_assignment.customerLatitude != null && _assignment.customerLongitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.gps_fixed, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'GPS: ${_assignment.customerLatitude!.toStringAsFixed(6)}, ${_assignment.customerLongitude!.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
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

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Installation Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${_assignment.completionPercentage.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _assignment.completionPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getSubTaskStatusColor(
                  _assignment.status == 'assigned' ? InstallationTaskStatus.assigned :
                  _assignment.status == 'in_progress' ? InstallationTaskStatus.inProgress :
                  _assignment.status == 'completed' ? InstallationTaskStatus.completed :
                  _assignment.status == 'verified' ? InstallationTaskStatus.verified :
                  InstallationTaskStatus.pending
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getSubTaskStatusColor(
                    _assignment.status == 'assigned' ? InstallationTaskStatus.assigned :
                    _assignment.status == 'in_progress' ? InstallationTaskStatus.inProgress :
                    _assignment.status == 'completed' ? InstallationTaskStatus.completed :
                    _assignment.status == 'verified' ? InstallationTaskStatus.verified :
                    InstallationTaskStatus.pending
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSubTaskStatusIcon(
                      _assignment.status == 'assigned' ? InstallationTaskStatus.assigned :
                      _assignment.status == 'in_progress' ? InstallationTaskStatus.inProgress :
                      _assignment.status == 'completed' ? InstallationTaskStatus.completed :
                      _assignment.status == 'verified' ? InstallationTaskStatus.verified :
                      InstallationTaskStatus.pending
                    ),
                    color: _getSubTaskStatusColor(
                      _assignment.status == 'assigned' ? InstallationTaskStatus.assigned :
                      _assignment.status == 'in_progress' ? InstallationTaskStatus.inProgress :
                      _assignment.status == 'completed' ? InstallationTaskStatus.completed :
                      _assignment.status == 'verified' ? InstallationTaskStatus.verified :
                      InstallationTaskStatus.pending
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${_assignment.statusDisplayName}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _getSubTaskStatusColor(
                        _assignment.status == 'assigned' ? InstallationTaskStatus.assigned :
                        _assignment.status == 'in_progress' ? InstallationTaskStatus.inProgress :
                        _assignment.status == 'completed' ? InstallationTaskStatus.completed :
                        _assignment.status == 'verified' ? InstallationTaskStatus.verified :
                        InstallationTaskStatus.pending
                      ),
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

  Widget _buildSubTasksList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Installation Sub-Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...InstallationSubTask.values.map((subTask) => _buildSubTaskItem(subTask)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTaskItem(InstallationSubTask subTask) {
    final status = _assignment.subTasksStatus[subTask] ?? InstallationTaskStatus.pending;
    final startTime = _assignment.subTasksStartTimes[subTask];
    final completionTime = _assignment.subTasksCompletionTimes[subTask];
    final photos = _assignment.subTasksPhotos[subTask];
    final notes = _assignment.subTasksNotes[subTask];
    final employeesPresent = _assignment.subTasksEmployeesPresent[subTask];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getSubTaskStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSubTaskStatusIcon(status),
                  color: _getSubTaskStatusColor(status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      InstallationWorkAssignment.getSubTaskDisplayName(subTask),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getSubTaskStatusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_canStartTask(subTask))
                ElevatedButton(
                  onPressed: () => _showStartTaskDialog(subTask),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Start'),
                )
              else if (_canCompleteTask(subTask))
                ElevatedButton(
                  onPressed: () => _showCompleteTaskDialog(subTask),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Complete'),
                ),
            ],
          ),
          
          if (startTime != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.play_arrow, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Started: ${DateFormat('dd/MM/yyyy HH:mm').format(startTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
          
          if (completionTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.done, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Completed: ${DateFormat('dd/MM/yyyy HH:mm').format(completionTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
          
          if (employeesPresent != null && employeesPresent.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Employees Present: ${employeesPresent.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                notes,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          
          if (photos != null && photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Photos: ${photos.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignmentDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Assignment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Assigned By', _assignment.assignedByName),
            _buildDetailRow('Assigned Date', DateFormat('dd/MM/yyyy HH:mm').format(_assignment.assignedDate)),
            if (_assignment.scheduledDate != null)
              _buildDetailRow('Scheduled Date', DateFormat('dd/MM/yyyy HH:mm').format(_assignment.scheduledDate!)),
            _buildDetailRow('Team Members', _assignment.assignedEmployeeNames.join(', ')),
            if (_assignment.notes != null && _assignment.notes!.isNotEmpty)
              _buildDetailRow('Notes', _assignment.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// Start Task Dialog
class _StartTaskDialog extends StatefulWidget {
  final InstallationSubTask subTask;
  final InstallationWorkAssignment assignment;
  final UserModel currentUser;
  final VoidCallback onStarted;

  const _StartTaskDialog({
    required this.subTask,
    required this.assignment,
    required this.currentUser,
    required this.onStarted,
  });

  @override
  State<_StartTaskDialog> createState() => __StartTaskDialogState();
}

class __StartTaskDialogState extends State<_StartTaskDialog> {
  bool _isLoading = false;
  List<String> _selectedEmployees = [];

  @override
  void initState() {
    super.initState();
    // Pre-select current user
    _selectedEmployees.add(widget.currentUser.id);
  }

  Future<void> _startTask() async {
    setState(() => _isLoading = true);
    try {
      await InstallationService.startSubTask(
        assignmentId: widget.assignment.id,
        subTask: widget.subTask,
        employeesPresent: _selectedEmployees,
        startedByEmployeeId: widget.currentUser.id,
      );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onStarted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task started successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting task: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Start ${InstallationWorkAssignment.getSubTaskDisplayName(widget.subTask)}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select employees present on site:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          // List of assigned employees with checkboxes
          ...widget.assignment.assignedEmployeeIds.asMap().entries.map((entry) {
            final index = entry.key;
            final employeeId = entry.value;
            final employeeName = widget.assignment.assignedEmployeeNames[index];
            final isSelected = _selectedEmployees.contains(employeeId);
            
            return CheckboxListTile(
              title: Text(employeeName),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedEmployees.add(employeeId);
                  } else {
                    _selectedEmployees.remove(employeeId);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            );
          }).toList(),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GPS verification will ensure all selected employees are within 50m of the customer location.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedEmployees.isEmpty ? null : _startTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start Task'),
        ),
      ],
    );
  }
}

// Complete Task Dialog
class _CompleteTaskDialog extends StatefulWidget {
  final InstallationSubTask subTask;
  final InstallationWorkAssignment assignment;
  final UserModel currentUser;
  final VoidCallback onCompleted;

  const _CompleteTaskDialog({
    required this.subTask,
    required this.assignment,
    required this.currentUser,
    required this.onCompleted,
  });

  @override
  State<_CompleteTaskDialog> createState() => __CompleteTaskDialogState();
}

class __CompleteTaskDialogState extends State<_CompleteTaskDialog> {
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _solarPanelSerialsController = TextEditingController();
  final TextEditingController _inverterSerialsController = TextEditingController();
  List<File> _photos = [];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickPhoto() async {
    final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _photos.add(File(photo.path));
      });
    }
  }

  Future<void> _completeTask() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completion notes are required')),
      );
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one photo is required')),
      );
      return;
    }

    if (widget.subTask == InstallationSubTask.dataCollection) {
      if (_solarPanelSerialsController.text.trim().isEmpty || 
          _inverterSerialsController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serial numbers are required for data collection')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      // In a real implementation, you would upload photos first and get URLs
      List<String> photoUrls = _photos.map((file) => file.path).toList();

      List<String>? solarPanelSerials;
      List<String>? inverterSerials;

      if (widget.subTask == InstallationSubTask.dataCollection) {
        solarPanelSerials = _solarPanelSerialsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        
        inverterSerials = _inverterSerialsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      await InstallationService.completeSubTask(
        assignmentId: widget.assignment.id,
        subTask: widget.subTask,
        completedByEmployeeId: widget.currentUser.id,
        completionNotes: _notesController.text.trim(),
        photoUrls: photoUrls,
        solarPanelSerialNumbers: solarPanelSerials,
        inverterSerialNumbers: inverterSerials,
      );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing task: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Complete ${InstallationWorkAssignment.getSubTaskDisplayName(widget.subTask)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion Notes
            const Text(
              'Completion Notes *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter completion notes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Photos Section
            const Text(
              'Photos *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
                const SizedBox(width: 8),
                Text('${_photos.length} photo(s) added'),
              ],
            ),
            const SizedBox(height: 16),

            // Data Collection Specific Fields
            if (widget.subTask == InstallationSubTask.dataCollection) ...[
              const Text(
                'Solar Panel Serial Numbers *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _solarPanelSerialsController,
                decoration: const InputDecoration(
                  hintText: 'Enter serial numbers separated by commas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Inverter Serial Numbers *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _inverterSerialsController,
                decoration: const InputDecoration(
                  hintText: 'Enter serial numbers separated by commas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // GPS Verification Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS verification will confirm you are within 50m of the customer location before completing.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _completeTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Complete Task'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _solarPanelSerialsController.dispose();
    _inverterSerialsController.dispose();
    super.dispose();
  }
}
