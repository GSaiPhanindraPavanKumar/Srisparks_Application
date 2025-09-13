import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/installation_work_model.dart';
import '../../models/user_model.dart';
import '../../services/installation_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

class EmployeeWorkDetailScreen extends StatefulWidget {
  final String workItemId;

  const EmployeeWorkDetailScreen({super.key, required this.workItemId});

  @override
  State<EmployeeWorkDetailScreen> createState() =>
      _EmployeeWorkDetailScreenState();
}

class _EmployeeWorkDetailScreenState extends State<EmployeeWorkDetailScreen>
    with TickerProviderStateMixin {
  final InstallationService _installationService = InstallationService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;

  UserModel? _currentUser;
  InstallationWorkItem? _workItem;
  Map<String, dynamic>? _activeSession;
  List<Map<String, dynamic>> _workSessions = [];
  List<Map<String, dynamic>> _photos = [];

  bool _isLoading = true;
  bool _isLocationVerified = false;
  String? _error;
  String? _currentLocation;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser == null) {
        throw Exception('User not found');
      }

      final futures = await Future.wait([
        _loadWorkItemDetails(),
        _installationService.getActiveWorkSession(_currentUser!.id),
        _loadWorkSessions(),
        _loadPhotos(),
      ]);

      setState(() {
        _activeSession = futures[1] as Map<String, dynamic>?;
        _workSessions = futures[2] as List<Map<String, dynamic>>;
        _photos = futures[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });

      await _checkLocationPermission();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWorkItemDetails() async {
    // This would typically fetch from the service
    // For now, creating a placeholder with correct properties
    _workItem = InstallationWorkItem(
      id: widget.workItemId,
      customerId: 'cust-123',
      workType: InstallationWorkType.panels,
      siteLatitude: 12.9716,
      siteLongitude: 77.5946,
      siteAddress: '123 Main St, City, State 12345',
      leadEmployeeId: _currentUser!.id,
      leadEmployeeName: _currentUser!.fullName ?? 'Employee',
      status: WorkStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> _loadWorkSessions() async {
    return [
      {
        'id': 'session-1',
        'start_time': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'end_time': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'duration_hours': 1.0,
        'location': 'Customer Site - Verified',
        'notes': 'Started solar panel installation on roof section A',
      },
      {
        'id': 'session-2',
        'start_time': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'end_time': null,
        'duration_hours': null,
        'location': 'Customer Site - Verified',
        'notes': 'Continuing with electrical connections',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadPhotos() async {
    return [
      {
        'id': 'photo-1',
        'url': 'https://example.com/photo1.jpg',
        'description': 'Before installation - roof condition',
        'taken_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'location': 'Verified',
      },
      {
        'id': 'photo-2',
        'url': 'https://example.com/photo2.jpg',
        'description': 'Panel placement progress',
        'taken_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'location': 'Verified',
      },
    ];
  }

  Future<void> _checkLocationPermission() async {
    try {
      final location = await _locationService.getCurrentLocation();
      setState(() {
        if (location != null) {
          _isLocationVerified = true;
          _currentLocation =
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        } else {
          _isLocationVerified = false;
          _currentLocation = 'Location not available';
        }
      });
    } catch (e) {
      setState(() {
        _isLocationVerified = false;
        _currentLocation = 'Location unavailable: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Work Details'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Work Details'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: _buildErrorWidget(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_workItem?.workType.displayName ?? 'Work Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Details'),
            Tab(icon: Icon(Icons.play_arrow), text: 'Progress'),
            Tab(icon: Icon(Icons.access_time), text: 'Time'),
            Tab(icon: Icon(Icons.photo_camera), text: 'Photos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildProgressTab(),
          _buildTimeTrackingTab(),
          _buildPhotosTab(),
        ],
      ),
      floatingActionButton: _buildActionButton(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading work details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildLocationCard(),
          const SizedBox(height: 16),
          _buildWorkInfoCard(),
          const SizedBox(height: 16),
          _buildProjectInfoCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Work Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (_workItem?.progressPercentage ?? 0) / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green[600]!,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${_workItem?.progressPercentage ?? 0}% Complete'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      _workItem?.status ?? WorkStatus.notStarted,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    (_workItem?.status ?? WorkStatus.notStarted).displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _isLocationVerified
                      ? Colors.green[600]
                      : Colors.red[600],
                ),
                const SizedBox(width: 8),
                const Text(
                  'Location Verification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _isLocationVerified ? Icons.verified : Icons.error,
                  color: _isLocationVerified ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLocationVerified
                      ? 'Location Verified'
                      : 'Location Not Verified',
                  style: TextStyle(
                    color: _isLocationVerified ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (_currentLocation != null) ...[
              const SizedBox(height: 8),
              Text(
                'Current: $_currentLocation',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _checkLocationPermission,
              icon: const Icon(Icons.my_location),
              label: const Text('Verify Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Work Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Work Type',
              _workItem?.workType.displayName ?? 'N/A',
            ),
            _buildInfoRow(
              'Estimated Hours',
              '${_workItem?.estimatedHours ?? 0}',
            ),
            _buildInfoRow('Actual Hours', '${_workItem?.actualHours ?? 0}'),
            if (_workItem?.scheduledDate != null)
              _buildInfoRow(
                'Scheduled Date',
                DateFormat(
                  'MMM dd, yyyy - hh:mm a',
                ).format(_workItem!.scheduledDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Project Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Customer', 'John Smith'),
            _buildInfoRow('Address', '123 Main St, City, State 12345'),
            _buildInfoRow('Phone', '+1 (555) 123-4567'),
            _buildInfoRow(
              'Project ID',
              _workItem?.installationProjectId ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Progress',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current Progress: ${_workItem?.progressPercentage ?? 0}%',
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_workItem?.progressPercentage ?? 0) / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green[600]!,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateProgress(25),
                          child: const Text('25%'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateProgress(50),
                          child: const Text('50%'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateProgress(75),
                          child: const Text('75%'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateProgress(100),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Complete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work Notes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter work progress notes...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _saveNotes,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Notes'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActiveSessionCard(),
          const SizedBox(height: 16),
          _buildTimeControlsCard(),
          const SizedBox(height: 16),
          _buildWorkSessionsHistory(),
        ],
      ),
    );
  }

  Widget _buildActiveSessionCard() {
    if (_activeSession == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.timer_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No Active Work Session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start a work session to track your time',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final startTime = DateTime.parse(_activeSession!['start_time']);
    final duration = DateTime.now().difference(startTime);

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Colors.green[600], size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Work Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Started: ${DateFormat('hh:mm a').format(startTime)}',
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeControlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _activeSession == null
                        ? _startWorkSession
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Work'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _activeSession != null ? _endWorkSession : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('End Work'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkSessionsHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Work Sessions History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._workSessions.map((session) => _buildSessionItem(session)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session) {
    final startTime = DateTime.parse(session['start_time']);
    final endTime = session['end_time'] != null
        ? DateTime.parse(session['end_time'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                endTime != null ? Icons.check_circle : Icons.timer,
                color: endTime != null ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM dd, yyyy').format(startTime),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                endTime != null
                    ? '${session['duration_hours']} hours'
                    : 'In Progress',
                style: TextStyle(
                  color: endTime != null ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('hh:mm a').format(startTime)} - ${endTime != null ? DateFormat('hh:mm a').format(endTime) : 'Ongoing'}',
            style: const TextStyle(color: Colors.grey),
          ),
          if (session['notes'] != null) ...[
            const SizedBox(height: 8),
            Text(session['notes']),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('From Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _photos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Photos Yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Take photos to document your work progress',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return _buildPhotoCard(photo);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 48, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo['description'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'MMM dd, hh:mm a',
                  ).format(DateTime.parse(photo['taken_at'])),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActionButton() {
    if (_activeSession != null) {
      return FloatingActionButton.extended(
        onPressed: _endWorkSession,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.stop, color: Colors.white),
        label: const Text('End Work', style: TextStyle(color: Colors.white)),
      );
    } else {
      return FloatingActionButton.extended(
        onPressed: _startWorkSession,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('Start Work', style: TextStyle(color: Colors.white)),
      );
    }
  }

  Color _getStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.completed:
      case WorkStatus.verified:
      case WorkStatus.acknowledged:
      case WorkStatus.approved:
        return Colors.green;
      case WorkStatus.inProgress:
        return Colors.orange;
      case WorkStatus.awaitingCompletion:
        return Colors.blue;
      case WorkStatus.notStarted:
        return Colors.grey;
    }
  }

  Future<void> _startWorkSession() async {
    if (!_isLocationVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your location before starting work'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get current location for session
      final location = await _locationService.getCurrentLocation();

      if (location == null) {
        throw Exception('Unable to get current location');
      }

      await _installationService.startWorkSession(
        employeeId: _currentUser!.id,
        workItemId: widget.workItemId,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work session started successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start work session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _endWorkSession() async {
    if (_activeSession == null) return;

    try {
      // Get current location for session end
      final location = await _locationService.getCurrentLocation();

      if (location == null) {
        throw Exception('Unable to get current location');
      }

      await _installationService.endWorkSession(
        sessionId: _activeSession!['id'],
        latitude: location.latitude,
        longitude: location.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work session ended successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to end work session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProgress(int percentage) async {
    try {
      await _installationService.updateWorkItemStatus(
        workItemId: widget.workItemId,
        status: percentage == 100 ? 'completed' : 'in_progress',
        progressPercentage: percentage,
      );

      setState(() {
        _workItem = _workItem?.copyWith(
          status: percentage == 100
              ? WorkStatus.completed
              : WorkStatus.inProgress,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update progress: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveNotes() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notes saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _takePhoto() async {
    if (!_isLocationVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your location before taking photos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (photo != null) {
        await _uploadPhoto(photo);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (photo != null) {
        await _uploadPhoto(photo);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadPhoto(XFile photo) async {
    // Show dialog to get photo description
    String? description = await _getPhotoDescription();
    if (description == null || description.isEmpty) return;

    try {
      // Upload photo and add to list
      final newPhoto = {
        'id': 'photo-${_photos.length + 1}',
        'url': photo.path,
        'description': description,
        'taken_at': DateTime.now().toIso8601String(),
        'location': _isLocationVerified ? 'Verified' : 'Not Verified',
      };

      setState(() {
        _photos.add(newPhoto);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _getPhotoDescription() async {
    String description = '';
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Photo Description'),
          content: TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Describe this photo...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => description = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(description),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
