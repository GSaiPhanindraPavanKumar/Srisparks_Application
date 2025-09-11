import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/installation_model.dart';
import '../../models/user_model.dart';
import '../../services/installation_service.dart';
import '../../services/auth_service.dart';

class InstallationVerificationScreen extends StatefulWidget {
  const InstallationVerificationScreen({super.key});

  @override
  State<InstallationVerificationScreen> createState() => _InstallationVerificationScreenState();
}

class _InstallationVerificationScreenState extends State<InstallationVerificationScreen> {
  final AuthService _authService = AuthService();
  
  List<InstallationWorkAssignment> _completedAssignments = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCompletedAssignments();
  }

  Future<void> _loadCompletedAssignments() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        _completedAssignments = await InstallationService.getCompletedInstallations();
      }
    } catch (e) {
      _showMessage('Error loading completed installations: $e');
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

  List<InstallationWorkAssignment> get _filteredAssignments {
    if (_searchQuery.isEmpty) return _completedAssignments;
    
    return _completedAssignments.where((assignment) {
      return assignment.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             assignment.customerAddress.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showVerificationDialog(InstallationWorkAssignment assignment) {
    showDialog(
      context: context,
      builder: (context) => _VerificationDialog(
        assignment: assignment,
        currentUser: _currentUser!,
        onVerified: _loadCompletedAssignments,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installation Verification'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompletedAssignments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search installations to verify...',
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

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssignments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredAssignments.length,
                        itemBuilder: (context, index) {
                          return _buildVerificationCard(_filteredAssignments[index]);
                        },
                      ),
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
          Icon(
            Icons.verified_user,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Installations to Verify',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All completed installations have been verified.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(InstallationWorkAssignment assignment) {
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
            // Header
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: Colors.green,
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
            
            // Completion Progress
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
                  Text(
                    'All installation tasks completed - Ready for verification',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
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
                  'Completed: ${assignment.dataCollectionCompletedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(assignment.dataCollectionCompletedAt!) : 'Recently'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Verification Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showVerificationDialog(assignment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Review & Verify Installation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Verification Dialog Widget
class _VerificationDialog extends StatefulWidget {
  final InstallationWorkAssignment assignment;
  final UserModel currentUser;
  final VoidCallback onVerified;

  const _VerificationDialog({
    required this.assignment,
    required this.currentUser,
    required this.onVerified,
  });

  @override
  State<_VerificationDialog> createState() => __VerificationDialogState();
}

class __VerificationDialogState extends State<_VerificationDialog> {
  bool _isLoading = false;
  bool _isApproved = true;
  final TextEditingController _remarksController = TextEditingController();
  List<Map<String, dynamic>> _subTasks = [];

  @override
  void initState() {
    super.initState();
    _loadSubTaskDetails();
  }

  Future<void> _loadSubTaskDetails() async {
    try {
      _subTasks = await InstallationService.getSubTaskDetails(widget.assignment.id);
      setState(() {});
    } catch (e) {
      _showMessage('Error loading task details: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _submitVerification() async {
    if (!_isApproved && _remarksController.text.trim().isEmpty) {
      _showMessage('Please provide remarks for rejection');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await InstallationService.verifyInstallation(
        assignmentId: widget.assignment.id,
        verifiedById: widget.currentUser.id,
        verificationStatus: _isApproved ? 'approved' : 'rejected',
        verificationNotes: _remarksController.text.trim().isNotEmpty 
            ? _remarksController.text.trim() 
            : null,
      );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onVerified();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isApproved 
                ? 'Installation verified successfully' 
                : 'Installation rejected - Team will be notified'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error verifying installation: $e');
      }
    }
    setState(() => _isLoading = false);
  }

  String _getSubTaskDisplayName(InstallationSubTask subTask) {
    switch (subTask) {
      case InstallationSubTask.structure:
        return 'Structure Installation';
      case InstallationSubTask.panels:
        return 'Solar Panels';
      case InstallationSubTask.wiringInverter:
        return 'Wiring & Inverter';
      case InstallationSubTask.earthing:
        return 'Earthing';
      case InstallationSubTask.lightningArrestor:
        return 'Lightning Arrestor';
      case InstallationSubTask.dataCollection:
        return 'Data Collection';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Installation'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
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
                      widget.assignment.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.assignment.customerAddress,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Team: ${widget.assignment.assignedEmployeeNames.join(', ')}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sub-task Details
              const Text(
                'Installation Tasks:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              
              if (_subTasks.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                ..._subTasks.map((subTask) => _buildSubTaskTile(subTask)),
              
              const SizedBox(height: 16),
              
              // Verification Decision
              const Text(
                'Verification Decision:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              
              Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text('Approve Installation'),
                    subtitle: const Text('Installation meets quality standards'),
                    value: true,
                    groupValue: _isApproved,
                    onChanged: (value) => setState(() => _isApproved = value!),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Reject Installation'),
                    subtitle: const Text('Installation requires corrections'),
                    value: false,
                    groupValue: _isApproved,
                    onChanged: (value) => setState(() => _isApproved = value!),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Remarks
              Text(
                _isApproved ? 'Remarks (Optional):' : 'Rejection Remarks (Required):',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _isApproved 
                      ? 'Enter any additional comments...'
                      : 'Specify what needs to be corrected...',
                  border: const OutlineInputBorder(),
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
          onPressed: _isLoading ? null : _submitVerification,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isApproved ? Colors.green.shade700 : Colors.red.shade700,
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
              : Text(_isApproved ? 'Approve Installation' : 'Reject Installation'),
        ),
      ],
    );
  }

  Widget _buildSubTaskTile(Map<String, dynamic> subTask) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSubTaskDisplayName(subTask['sub_task'] ?? ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (subTask['completed_date'] != null)
                  Text(
                    DateFormat('dd/MM HH:mm').format(DateTime.parse(subTask['completed_date'])),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (subTask['notes'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${subTask['notes']}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
            if (subTask['serial_numbers'] != null && (subTask['serial_numbers'] as List).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Serial Numbers: ${(subTask['serial_numbers'] as List).join(', ')}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
            if (subTask['photo_urls'] != null && (subTask['photo_urls'] as List).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${(subTask['photo_urls'] as List).length} photos attached',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }
}
