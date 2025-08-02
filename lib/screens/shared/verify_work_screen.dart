import 'package:flutter/material.dart';
import '../../models/work_model.dart';
import '../../models/office_model.dart';
import '../../models/user_model.dart';
import '../../services/work_service.dart';
import '../../services/office_service.dart';
import '../../services/auth_service.dart';

class VerifyWorkScreen extends StatefulWidget {
  const VerifyWorkScreen({super.key});

  @override
  State<VerifyWorkScreen> createState() => _VerifyWorkScreenState();
}

class _VerifyWorkScreenState extends State<VerifyWorkScreen> {
  final WorkService _workService = WorkService();
  final OfficeService _officeService = OfficeService();
  final AuthService _authService = AuthService();

  List<WorkModel> _allPendingWork = [];
  List<WorkModel> _filteredPendingWork = [];
  List<OfficeModel> _allOffices = [];
  String? _selectedOfficeId;
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        // If director, load all offices for selection
        if (_currentUser!.role == UserRole.director) {
          _allOffices = await _officeService.getAllOffices();
          _selectedOfficeId =
              'all_offices'; // Default to all offices for directors
        }
        await _loadPendingWork();
      }
    } catch (e) {
      _showMessage('Error initializing screen: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingWork() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _allPendingWork = await _workService.getWorkRequiringVerification();
      _filterWork();
    } catch (e) {
      _showMessage('Error loading work: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterWork() {
    setState(() {
      _filteredPendingWork = _allPendingWork.where((work) {
        // Office filter for directors
        final matchesOffice =
            _selectedOfficeId == null ||
            _selectedOfficeId == 'all_offices' ||
            work.officeId == _selectedOfficeId;

        return matchesOffice;
      }).toList();
    });
  }

  Future<void> _verifyWork(WorkModel work) async {
    try {
      await _workService.verifyWork(work.id);
      _showMessage('Work verified successfully');
      _loadPendingWork();
    } catch (e) {
      _showMessage('Error verifying work: $e');
    }
  }

  Future<void> _rejectWork(WorkModel work) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Work'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject "${work.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _workService.rejectWork(work.id, reasonController.text);
        _showMessage('Work rejected');
        _loadPendingWork();
      } catch (e) {
        _showMessage('Error rejecting work: $e');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Work'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingWork,
          ),
        ],
      ),
      body: Column(
        children: [
          // Office selector for directors
          if (_currentUser?.role == UserRole.director) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Office:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      value: _selectedOfficeId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        // Add "All Offices" option for directors
                        const DropdownMenuItem<String>(
                          value: 'all_offices',
                          child: Row(
                            children: [
                              Icon(
                                Icons.business_center,
                                size: 16,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'All Offices',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Add individual offices
                        ..._allOffices.map((office) {
                          return DropdownMenuItem<String>(
                            value: office.id,
                            child: Row(
                              children: [
                                const Icon(Icons.business, size: 16),
                                const SizedBox(width: 8),
                                Text(office.name),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue != _selectedOfficeId) {
                          setState(() {
                            _selectedOfficeId = newValue;
                          });
                          _filterWork();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Work list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPendingWork.isEmpty
                ? const Center(
                    child: Text(
                      'No work pending verification',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPendingWork.length,
                    itemBuilder: (context, index) {
                      final work = _filteredPendingWork[index];
                      return _buildWorkCard(work);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkCard(WorkModel work) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    work.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (work.description != null)
              Text(
                work.description!,
                style: const TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 12),

            // Work details
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Assigned to: ${work.assignedToName ?? 'Unknown'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Assigned date (created date)
            Row(
              children: [
                Icon(Icons.assignment, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  'Assigned: ${work.createdAt.toString().split(' ')[0]} at ${work.createdAt.toString().split(' ')[1].substring(0, 5)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Started date
            if (work.startDate != null) ...[
              Row(
                children: [
                  Icon(Icons.play_arrow, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Started: ${work.startDate!.toString().split(' ')[0]} at ${work.startDate!.toString().split(' ')[1].substring(0, 5)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Completed date
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.orange[600]),
                const SizedBox(width: 4),
                Text(
                  'Completed: ${work.completedDate?.toString().split(' ')[0] ?? 'Unknown'} ${work.completedDate != null ? 'at ${work.completedDate!.toString().split(' ')[1].substring(0, 5)}' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            if (work.actualHours != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Actual Hours: ${work.actualHours}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejectWork(work),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _verifyWork(work),
                  icon: const Icon(Icons.check),
                  label: const Text('Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
