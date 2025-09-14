import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/installation_work_model.dart';
import '../../models/customer_model.dart';
import '../../services/installation_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

class InstallationWorkDetailScreen extends StatefulWidget {
  final InstallationWorkItem workItem;
  final CustomerModel customer;

  const InstallationWorkDetailScreen({
    super.key,
    required this.workItem,
    required this.customer,
  });

  @override
  State<InstallationWorkDetailScreen> createState() =>
      _InstallationWorkDetailScreenState();
}

class _InstallationWorkDetailScreenState
    extends State<InstallationWorkDetailScreen> {
  final InstallationService _installationService = InstallationService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  late InstallationWorkItem _currentWorkItem;
  bool _isLoading = false;
  String? _currentSessionId;
  String? _currentEmployeeId;

  @override
  void initState() {
    super.initState();
    _currentWorkItem = widget.workItem;
    _getCurrentEmployee();
  }

  Future<void> _getCurrentEmployee() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentEmployeeId = currentUser.id;
        });
        // Check if this employee has an active session for this work item
        await _checkActiveSession();
      }
    } catch (e) {
      print('Error getting current employee: $e');
    }
  }

  Future<void> _checkActiveSession() async {
    if (_currentEmployeeId == null) return;

    try {
      final activeSession = await _installationService.getEmployeeActiveSession(
        employeeId: _currentEmployeeId!,
        workItemId: _currentWorkItem.id,
      );

      if (activeSession != null) {
        setState(() {
          _currentSessionId = activeSession['id'];
          // Update work item to show it's in progress for this employee
          if (_currentWorkItem.status != WorkStatus.inProgress) {
            _currentWorkItem = _currentWorkItem.copyWith(
              status: WorkStatus.inProgress,
              startTime: DateTime.parse(activeSession['start_time']),
            );
          }
        });
      }
    } catch (e) {
      print('Error checking active session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getWorkTypeDisplayName(_currentWorkItem.workType.name)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_currentWorkItem.status.name == 'inProgress')
            IconButton(icon: const Icon(Icons.stop), onPressed: _stopWork),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerInfoCard(),
                  const SizedBox(height: 16),
                  _buildWorkStatusCard(),
                  const SizedBox(height: 16),
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                  const SizedBox(height: 16),
                  _buildPhotosCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
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
            const Row(
              children: [
                Icon(Icons.person, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Customer Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.customer.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.customer.address ?? 'Address not specified',
                  ),
                ),
              ],
            ),
            if (widget.customer.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(widget.customer.phoneNumber!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.work, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Work Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getWorkStatusColor(
                    _currentWorkItem.status.name,
                  ),
                  child: Icon(
                    _getWorkStatusIcon(_currentWorkItem.status.name),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getWorkStatusDisplayName(_currentWorkItem.status.name),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_currentWorkItem.startTime != null)
                        Text(
                          'Started: ${DateFormat('dd/MM/yyyy HH:mm').format(_currentWorkItem.startTime!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentWorkItem.estimatedHours != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Estimated: ${_currentWorkItem.estimatedHours}h'),
                  if (_currentWorkItem.actualHours != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Actual: ${_currentWorkItem.actualHours}h'),
                  ],
                ],
              ),
            ],
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
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _currentWorkItem.progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentWorkItem.progressPercentage}% Complete',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note_alt, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Work Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentWorkItem.workNotes?.isNotEmpty == true)
              Text(_currentWorkItem.workNotes!)
            else
              const Text(
                'No notes added yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _addWorkNote,
              icon: const Icon(Icons.add),
              label: const Text('Add Note'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.photo_camera, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Work Photos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentWorkItem.workPhotos.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _currentWorkItem.workPhotos.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
              )
            else
              const Text(
                'No photos added yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _addWorkPhoto,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Photo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    // Determine button state based on employee's active session, not overall work item status
    final bool hasActiveSession = _currentSessionId != null;
    final bool isWorkItemCompleted =
        _currentWorkItem.status.name == 'completed' ||
        _currentWorkItem.status.name == 'verified';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show start button if employee has no active session and work isn't fully completed
        if (!hasActiveSession && !isWorkItemCompleted)
          ElevatedButton.icon(
            onPressed: _startWork,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start My Work'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

        // Show complete button if employee has active session
        if (hasActiveSession) ...[
          ElevatedButton.icon(
            onPressed: _completeWork,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete My Work'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],

        // Show work completed message if overall work item is done
        if (isWorkItemCompleted)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Work item completed by all assigned employees',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _startWork() async {
    if (_currentEmployeeId == null) {
      _showErrorDialog('Employee authentication error. Please try again.');
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Get employee's current GPS location
      final currentLocation = await _locationService.getCurrentLocation();

      if (currentLocation == null) {
        throw Exception(
          'Unable to get your current location. Please enable GPS and try again.',
        );
      }

      _currentSessionId = await _installationService.startWorkSession(
        workItemId: _currentWorkItem.id,
        employeeId: _currentEmployeeId!, // Use current employee's ID
        latitude:
            currentLocation.latitude, // ✅ FIXED - Employee's current location
        longitude:
            currentLocation.longitude, // ✅ FIXED - Employee's current location
      );

      await _installationService.updateWorkItemStatus(
        workItemId: _currentWorkItem.id,
        status: 'inProgress',
        progressPercentage: 10,
      );

      setState(() {
        _currentWorkItem = _currentWorkItem.copyWith(
          status: WorkStatus.inProgress,
          startTime: DateTime.now(),
        );
        _isLoading = false;
      });

      _showMessage('Work started successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to start work: $e');
    }
  }

  Future<void> _completeWork() async {
    try {
      setState(() => _isLoading = true);

      // Get employee's current GPS location for verification
      final currentLocation = await _locationService.getCurrentLocation();

      if (currentLocation == null) {
        throw Exception(
          'Unable to get your current location. Please enable GPS and try again.',
        );
      }

      await _installationService.updateWorkItemStatus(
        workItemId: _currentWorkItem.id,
        status: 'completed',
        progressPercentage: 100,
      );

      if (_currentSessionId != null) {
        await _installationService.endWorkSession(
          sessionId: _currentSessionId!,
          latitude:
              currentLocation.latitude, // ✅ FIXED - Employee's current location
          longitude: currentLocation
              .longitude, // ✅ FIXED - Employee's current location
        );
      }

      setState(() {
        _currentWorkItem = _currentWorkItem.copyWith(
          status: WorkStatus.completed,
          endTime: DateTime.now(),
        );
        _currentSessionId = null; // ✅ FIXED - Clear session ID after completion
        _isLoading = false;
      });

      _showMessage('Work completed successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to complete work: $e');
    }
  }

  Future<void> _stopWork() async {
    try {
      setState(() => _isLoading = true);

      // Get employee's current GPS location for verification
      final currentLocation = await _locationService.getCurrentLocation();

      if (currentLocation == null) {
        throw Exception(
          'Unable to get your current location. Please enable GPS and try again.',
        );
      }

      if (_currentSessionId != null) {
        await _installationService.endWorkSession(
          sessionId: _currentSessionId!,
          latitude:
              currentLocation.latitude, // ✅ FIXED - Employee's current location
          longitude: currentLocation
              .longitude, // ✅ FIXED - Employee's current location
        );
      }

      await _installationService.updateWorkItemStatus(
        workItemId: _currentWorkItem.id,
        status: 'awaitingCompletion',
      );

      setState(() {
        _currentWorkItem = _currentWorkItem.copyWith(
          status: WorkStatus.awaitingCompletion,
        );
        _currentSessionId = null; // ✅ FIXED - Clear session ID after stopping
        _isLoading = false;
      });

      _showMessage('Work stopped');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to stop work: $e');
    }
  }

  void _addWorkNote() {
    // Implementation for adding work notes
    _showMessage('Add note feature coming soon');
  }

  void _addWorkPhoto() {
    // Implementation for adding work photos
    _showMessage('Add photo feature coming soon');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getWorkStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'notstarted':
        return Colors.grey;
      case 'inprogress':
        return Colors.orange;
      case 'awaitingcompletion':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'verified':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getWorkStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'notstarted':
        return Icons.schedule;
      case 'inprogress':
        return Icons.play_arrow;
      case 'awaitingcompletion':
        return Icons.pause;
      case 'completed':
        return Icons.check_circle;
      case 'verified':
        return Icons.verified;
      default:
        return Icons.help;
    }
  }

  String _getWorkStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'notstarted':
        return 'Not Started';
      case 'inprogress':
        return 'In Progress';
      case 'awaitingcompletion':
        return 'Awaiting Completion';
      case 'completed':
        return 'Completed';
      case 'verified':
        return 'Verified';
      default:
        return status;
    }
  }

  String _getWorkTypeDisplayName(String workType) {
    switch (workType.toLowerCase()) {
      case 'structurework':
        return 'Structure Work';
      case 'panels':
        return 'Panel Installation';
      case 'inverterwiring':
        return 'Inverter Wiring';
      case 'earthing':
        return 'Earthing System';
      case 'lightningarrestor':
        return 'Lightning Arrestor';
      default:
        return workType;
    }
  }
}
